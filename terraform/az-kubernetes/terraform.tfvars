resource_group_name = "<provide a resource group name>"
prefix              = "<provide a short prefix for resources>"
storage_file_shares = {
  "node-storage-1" = {
    quota = 2
  }
  "bridge-storage-1" = {
    quota = 1
  }
  "float-storage-1" = {
    quota = 1
  }
}
node_pool_public_ips = {
  "node-ip" = {
    public_ip_dns_label = "<dns label you wish to use for node-ip>"
  }
  "float-ip" = {
    public_ip_dns_label = "<dns label you wish to use for float-ip>"
  }
}
tags = {
  Owner       = "<your email address>"
  Environment = "<your environment>"
}
subscription_id  = "<your Azure subscription id in form 00000000-0000-0000-0000-000000000000>"
client_id        = "<your service principal id in form 00000000-0000-0000-0000-000000000000>"
client_secret    = "<create a secret for client id and paste here>"
tenant_id        = "<your tenant id in form 00000000-0000-0000-0000-000000000000>"