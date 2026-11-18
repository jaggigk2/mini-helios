# Azure OpenAI account: the "building" that hosts models (in Sweden Central, per D2)
resource "azurerm_cognitive_account" "aoai" {
  name                  = "aoai-helios-${random_string.sfx.result}"   # unique name via the random suffix
  location              = "swedencentral"                             # D2: Standard = processed in Sweden only
  resource_group_name   = azurerm_resource_group.rg.name              # same RG as the rest of Mini-Helios
  kind                  = "OpenAI"                                    # this account type serves OpenAI models
  sku_name              = "S0"                                        # standard pay-per-use account tier
  custom_subdomain_name = "aoai-helios-${random_string.sfx.result}"   # required for Entra ID (token) sign-in
  local_auth_enabled    = false                                       # API KEYS OFF: only Entra ID sign-in works
  tags                  = local.tags                                  # cost tracking, as everywhere
}

# Model deployment: the "room" inside the building where one model runs
resource "azurerm_cognitive_deployment" "chat" {
  name                 = "gpt-4.1-mini"                       # deployment name = what our code will call (AOAI_DEPLOYMENT)
  cognitive_account_id = azurerm_cognitive_account.aoai.id    # lives inside the account above
  model {
    format  = "OpenAI"                                        # model family provider
    name    = "gpt-4.1-mini"                                  # the model chosen in step 1
    version = "2025-04-14"                                    # the version we saw listed
  }
  sku {
    name     = "Standard"                                     # D2: pay per token, Sweden only
    capacity = 10                                             # 10 = 10K tokens/min: small cap = cost guardrail
  }
}

# Gate 2 for YOU: allowed to call models on this one account, nothing more
resource "azurerm_role_assignment" "me_openai_user" {
  scope                = azurerm_cognitive_account.aoai.id               # scope = this account only (least privilege)
  role_definition_name = "Cognitive Services OpenAI User"                # may call models, can't change or delete anything
  principal_id         = data.azurerm_client_config.current.object_id    # you (the signed-in user), from Lab 2.2's data block
}

# Print the endpoint URL after apply (not a secret: useless without a token)
output "aoai_endpoint" {
  value = azurerm_cognitive_account.aoai.endpoint
}
