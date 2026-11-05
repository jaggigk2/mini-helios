# Application Insights: app-level telemetry (requests, failures, latency, traces) for machine-api
resource "azurerm_application_insights" "appi" {
  name                = "appi-helios-${random_string.sfx.result}"          # same suffix as the rest of the foundation
  location            = azurerm_resource_group.rg.location                 # same region as everything else
  resource_group_name = azurerm_resource_group.rg.name                     # same resource group = one-command cleanup
  workspace_id        = azurerm_log_analytics_workspace.logs.id            # store data in the M2 Log Analytics workspace
  application_type    = "web"                                              # generic type for HTTP services like a Spring Boot API
  tags                = local.tags                                         # tagged for cost tracking
}

# Connection string the Java agent needs: marked sensitive so Terraform never prints it
output "appi_connection_string" {
  value     = azurerm_application_insights.appi.connection_string           # where the agent sends telemetry
  sensitive = true                                                          # hidden in plan/apply output
}

