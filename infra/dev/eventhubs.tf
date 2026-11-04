# Event Hubs namespace: the container (and hourly bill) for event hubs
resource "azurerm_eventhub_namespace" "ehns" {
  name                = "evhns-helios-${random_string.sfx.result}"  # globally unique name with our suffix
  location            = azurerm_resource_group.rg.location          # same region as everything else
  resource_group_name = azurerm_resource_group.rg.name              # lives in rg-helios-dev
  sku                 = "Standard"                                  # Standard = has the Kafka endpoint (Basic does not)
  capacity            = 1                                           # 1 throughput unit (~1 MB/s in), the smallest
  tags                = local.tags                                  # same tags as the rest of the foundation
}

# The event hub (the stream) inside the namespace
resource "azurerm_eventhub" "telemetry" {
  name              = "machine-telemetry"                           # the stream name producers send to
  namespace_id      = azurerm_eventhub_namespace.ehns.id            # put it inside the namespace above
  partition_count   = 2                                             # 2 lanes: enough to see spreading; fixed after creation
  message_retention = 1                                             # keep events 1 day (lab); real = 7 for replay
  capture_description {                                          # Capture: auto-copy every raw event to the lake
    enabled             = true                                   # switch it on
    encoding            = "Avro"                                 # compact file format Capture writes
    interval_in_seconds = 60                                     # write a file at least every 60 s (lab: fast)
    size_limit_in_bytes = 10485760                               # ...or every 10 MB, whichever comes first
    skip_empty_archives = true                                   # no empty files when nothing arrives

    destination {                                                # where the files go
      name                = "EventHubArchive.AzureBlockBlob"     # fixed value: write to blob storage
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}" # folder layout by time
      blob_container_name = azurerm_storage_container.bronze.name # the bronze container below
      storage_account_id  = azurerm_storage_account.lake.id      # our Module 2 data lake
    }
  }
}

# Consumer group: maintenance team's own bookmark
resource "azurerm_eventhub_consumer_group" "maintenance" {
  name                = "cg-maintenance"                            # the maintenance team's reader
  namespace_name      = azurerm_eventhub_namespace.ehns.name        # which namespace
  eventhub_name       = azurerm_eventhub.telemetry.name             # which stream
  resource_group_name = azurerm_resource_group.rg.name              # which resource group
}

# Consumer group: fleet analytics team's own bookmark
resource "azurerm_eventhub_consumer_group" "fleet_analytics" {
  name                = "cg-fleet-analytics"                        # the analytics team's reader
  namespace_name      = azurerm_eventhub_namespace.ehns.name        # which namespace
  eventhub_name       = azurerm_eventhub.telemetry.name             # which stream
  resource_group_name = azurerm_resource_group.rg.name              # which resource group
}

resource "azurerm_storage_container" "bronze" {                  # bronze layer: raw events, untouched
  name                  = "bronze"                               # container name
  storage_account_id    = azurerm_storage_account.lake.id        # in the data lake
  container_access_type = "private"                              # no anonymous access
}