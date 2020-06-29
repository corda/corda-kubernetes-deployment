variable "resource_group_name" {
  type = string
}
variable "client_id" {
  type = string
  description = ""
}
variable "client_secret" {
  type = string
  description = ""
}
variable "location" {
  type = string
  description = ""
  default = "uksouth"
}
variable "prefix" {
  type = string
  description = "Prefix of resources"
}
variable "tags" {
  type = map(string)
}
variable "storage_file_shares" {
  type = map(object({
    quota = number
  }))
  description = "(Required) Map of file shares."
}
variable "node_pool_public_ips" {
  type = map(object({
    public_ip_dns_label = string
  }))
  description = "(Optional) Map of public ip dns to create inside the nodepool resource group."
}
variable "subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}