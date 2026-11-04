# ---------- Event Hubs: the normalizer's own bookmark and keys ----------
resource "azurerm_eventhub_consumer_group" "normalizer" {          # own consumer group: doesn't disturb other teams
  name                = "cg-normalizer"                            # name the Function trigger uses
  namespace_name      = azurerm_eventhub_namespace.ehns.name       # existing namespace
  eventhub_name       = azurerm_eventhub.telemetry.name            # existing machine-telemetry hub
  resource_group_name = azurerm_resource_group.rg.name             # same resource group
}

resource "azurerm_eventhub_authorization_rule" "normalizer_listen" { # least privilege: read only
  name                = "listen-normalizer"                         # key name for the Function
  namespace_name      = azurerm_eventhub_namespace.ehns.name        # existing namespace
  eventhub_name       = azurerm_eventhub.telemetry.name             # scoped to this one hub
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  listen              = true                                        # may read
  send                = false                                       # may not write
  manage              = false                                       # may not change settings
}

resource "azurerm_eventhub_authorization_rule" "ingest_send" {      # telemetry-ingest publishes with this
  name                = "send-telemetry-ingest"                     # same name as Module 4 (was CLI, now code)
  namespace_name      = azurerm_eventhub_namespace.ehns.name        # existing namespace
  eventhub_name       = azurerm_eventhub.telemetry.name             # scoped to this one hub
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  listen              = false                                       # may not read
  send                = true                                        # may write
  manage              = false                                       # may not change settings
}

# ---------- Cosmos DB: latest state per machine+metric ----------
resource "azurerm_cosmosdb_account" "cosmos" {                      # the Cosmos account (the cabinet room)
  name                = "cosmos-helios-${random_string.sfx.result}" # globally unique name
  location            = azurerm_resource_group.rg.location          # Central India
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  offer_type          = "Standard"                                  # the only offer type
  kind                = "GlobalDocumentDB"                          # NoSQL (JSON documents) API
  free_tier_enabled   = true                                        # free 1,000 RU/s + 25 GB (one per subscription)
  tags                = local.tags                                  # cost tracking

  consistency_policy {                                              # how fresh reads must be
    consistency_level = "Session"                                   # default: you always read your own writes
  }

  geo_location {                                                    # where the data lives
    location          = azurerm_resource_group.rg.location          # one region only
    failover_priority = 0                                           # primary region
  }
}

resource "azurerm_cosmosdb_sql_database" "helios" {                 # database "helios"
  name                = "helios"                                    # name the Function binding uses
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  account_name        = azurerm_cosmosdb_account.cosmos.name        # inside our account
  throughput          = 400                                         # 400 RU/s shared, well inside the free 1,000
}

resource "azurerm_cosmosdb_sql_container" "machine_state" {         # container = the cabinet
  name                = "machine_state"                             # name the Function binding uses
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  account_name        = azurerm_cosmosdb_account.cosmos.name        # inside our account
  database_name       = azurerm_cosmosdb_sql_database.helios.name   # inside database helios
  partition_key_paths = ["/serial"]                                 # LOCKED DECISION: drawer = machine serial
}

# ---------- Lake: quarantine folder ----------
resource "azurerm_storage_container" "quarantine" {                 # LOCKED DECISION: bad events land here
  name                  = "quarantine"                              # path used by the blob output binding
  storage_account_id    = azurerm_storage_account.lake.id           # existing data lake
  container_access_type = "private"                                 # no anonymous access
}

# ---------- Function plumbing: its own small storage + monitoring ----------
resource "azurerm_storage_account" "func" {                         # Function's own files (package, bookmarks)
  name                     = "stfunc${random_string.sfx.result}"    # globally unique, <= 24 chars
  resource_group_name      = azurerm_resource_group.rg.name          # same resource group
  location                 = azurerm_resource_group.rg.location      # Central India
  account_tier             = "Standard"                              # cheapest tier
  account_replication_type = "LRS"                                   # one data centre is fine for plumbing
  tags                     = local.tags                              # cost tracking
}

resource "azurerm_storage_container" "deploy" {                     # Flex uploads the code zip here
  name                  = "deploymentpackage"                       # container for the app package
  storage_account_id    = azurerm_storage_account.func.id           # in the Function's storage
  container_access_type = "private"                                 # no anonymous access
}

resource "azurerm_application_insights" "ai" {                      # see logs: ACTION / QUARANTINED lines
  name                = "appi-helios-${random_string.sfx.result}"   # unique name
  location            = azurerm_resource_group.rg.location          # Central India
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  workspace_id        = azurerm_log_analytics_workspace.logs.id     # stores data in our Module 2 workspace
  application_type    = "other"                                     # not a web app
  tags                = local.tags                                  # cost tracking
}

# ---------- The Function itself: Flex Consumption, Python 3.13 ----------
resource "azurerm_service_plan" "flex" {                            # the hosting plan
  name                = "asp-normalizer"                            # plan name
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  location            = azurerm_resource_group.rg.location          # Central India
  os_type             = "Linux"                                     # Python runs on Linux
  sku_name            = "FC1"                                       # LOCKED DECISION: Flex Consumption
  tags                = local.tags                                  # cost tracking
}

resource "azurerm_function_app_flex_consumption" "normalizer" {     # the Function app
  name                = "func-normalizer-${random_string.sfx.result}" # globally unique name
  resource_group_name = azurerm_resource_group.rg.name               # same resource group
  location            = azurerm_resource_group.rg.location          # Central India
  service_plan_id     = azurerm_service_plan.flex.id                # runs on the FC1 plan

  storage_container_type      = "blobContainer"                     # code package lives in a blob container
  storage_container_endpoint  = "${azurerm_storage_account.func.primary_blob_endpoint}${azurerm_storage_container.deploy.name}" # which container
  storage_authentication_type = "StorageAccountConnectionString"    # lab shortcut; prod = managed identity
  storage_access_key          = azurerm_storage_account.func.primary_access_key # key for that storage (stays in state)

  runtime_name           = "python"                                 # language
  runtime_version        = "3.13"                                   # LOCKED DECISION
  maximum_instance_count = 40                                       # scale-out cap (lowest allowed)
  instance_memory_in_mb  = 2048                                     # memory per instance

  site_config {                                                     # runtime settings
    application_insights_connection_string = azurerm_application_insights.ai.connection_string # send logs here
  }

  app_settings = {                                                  # names the bindings in function_app.py look up
    EH_CONN     = azurerm_eventhub_authorization_rule.normalizer_listen.primary_connection_string # listen-only key
    COSMOS_CONN = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string                   # Cosmos key
    LAKE_CONN   = azurerm_storage_account.lake.primary_connection_string                          # lake key
  }

  tags = local.tags                                                 # cost tracking
}
