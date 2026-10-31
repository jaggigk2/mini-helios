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