data "azuread_service_principal" "aks_principal" {
  application_id = var.client_id
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "aks" {
  source               = "git@github.com:corda/terraform-modules-ext//modules/az-kubernetes?ref=master"
  prefix               = var.prefix
  resource_group_name  = azurerm_resource_group.main.name
  client_id            = var.client_id
  client_secret        = var.client_secret
  application_id       = data.azuread_service_principal.aks_principal.id
  storage_file_shares  = var.storage_file_shares
  node_pool_public_ips = var.node_pool_public_ips
  tags                 = var.tags
}
