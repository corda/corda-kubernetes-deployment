output "aks_host" {
  value = module.aks.aks_host
}

output "aks_username" {
  value = module.aks.aks_username
}

output "aks_password" {
  value = module.aks.aks_password
}

output "acr_host" {
  value = module.aks.acr_host
}

output "acr_admin_username" {
  value = module.aks.acr_admin_username
}

output "acr_admin_password" {
  value = module.aks.acr_admin_password
}

output "storage_account_primary_access_key" {
  value = module.aks.storage_account_primary_access_key
}