# --- Which plugins (providers) Terraform needs, pinned so everyone gets the same behaviour ---
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }   # talks to Azure; any 4.x version
    random  = { source = "hashicorp/random",  version = "~> 3.6" }   # generates random text for unique names
  }
}

# --- How to connect to Azure ---
provider "azurerm" {
  features {}                               # required block, left empty = default behaviour
  subscription_id = var.subscription_id     # which subscription to build in (passed in at plan/apply time)
}

variable "subscription_id" {}               # an input value; we supply it on the command line, not in the file

# --- 5 random letters/numbers so global names are unique (e.g. sthelios7k2qa) ---
resource "random_string" "sfx" {
  length  = 5                               # 5 characters
  upper   = false                           # lowercase only (storage names must be lowercase)
  special = false                           # no symbols like ! or #
}

# --- Tags reused on every resource, for cost tracking (FinOps) ---
locals {
  tags = { course = "helios", module = "m2", owner = "jaggi" }   # a named value used below as local.tags
}

# --- The folder that holds everything; deleting it deletes all of it ---
resource "azurerm_resource_group" "rg" {
  name     = "rg-helios-dev"                # resource group name
  location = "centralindia"                 # one region for everything
  tags     = local.tags                     # apply the tags
}

# --- Central logs: every service sends its logs here (Module 6) ---
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-helios-${random_string.sfx.result}"   # name + random suffix
  location            = azurerm_resource_group.rg.location         # same region as the resource group
  resource_group_name = azurerm_resource_group.rg.name             # put it inside the resource group
  sku                 = "PerGB2018"                                # pricing tier: pay per GB of logs
  retention_in_days   = 30                                         # keep logs 30 days (cheapest common choice)
  tags                = local.tags
}

# --- Data lake for raw and normalised machine telemetry (Module 5) ---
resource "azurerm_storage_account" "lake" {
  name                     = "sthelios${random_string.sfx.result}"  # globally unique, lowercase, no dashes
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"                             # normal disks (not premium)
  account_replication_type = "LRS"                                  # 3 copies in one data centre; prod would use ZRS
  is_hns_enabled           = true                                   # real folders = ADLS Gen2 data lake
  tags                     = local.tags
}

# --- Private store for Docker images (Module 3) ---
resource "azurerm_container_registry" "acr" {
  name                = "acrhelios${random_string.sfx.result}"      # globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"                                     # cheapest tier (~USD 5/month, charged daily)
  tags                = local.tags
}

# --- Shared runtime where all services will run; scales apps to zero when idle ---
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-helios"                                # environment name
  location                   = azurerm_resource_group.rg.location          # same region as the resource group
  resource_group_name        = azurerm_resource_group.rg.name              # put it inside the resource group
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id     # send its logs to the workspace above

  workload_profile {                          # declare the default Azure already created (fixes drift)
    name                  = "Consumption"     # the profile's name
    workload_profile_type = "Consumption"     # pay-per-use, scales to zero (our ADR-0001 choice)
  }

  tags                       = local.tags                                  # same tags as everything else
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-helios-${random_string.sfx.result}" 
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags = local.tags   # same course/module/owner tags as every other resource
 
}

resource "azurerm_role_assignment" "me_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}