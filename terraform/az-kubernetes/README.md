# Azure Kubernetes for Corda/CENM

## Overview

> **NOTE**: FOR TEST USE ONLY

This is an example deployment using the `az-kubernetes` module.

## Prerequisites

You will require an Azure Service Principal to deploy using Terraform.

To create one, use the following Azure-CLI command:

```bash
➜ az ad sp create-for-rbac --name <my service principal name>

Changing "<my service principal name>" to a valid URI of "http://<my service principal name>", which is the required format used for service principal names
Creating a role assignment under the scope of "/subscriptions/<subscription id>"
  Retrying role assignment creation: 1/36
{
  "appId": "<application id (client id)>",
  "displayName": "<my service principal name>",
  "name": "http://<my service principal name>",
  "password": "<password (client secret)>",
  "tenant": "<tenant id>"
}
```

You will need to add the `AcrPull` role assignment to the newly created service principal.  This also applies to existing service principals.

```bash
➜ az role assignment create --assignee <appId> --role acrpull
```

## Quick-Start Guide

### Configure Azure-CLI Login

1. Login to Azure-CLI using the command:
    ```az login```
    This will take you to the Azure Portal to login using your normal credentials.
2. Set your target subscription using the following command:
   ```az account set --subscription <Name or Subscription ID>```

### Terraform - Deploy Infrastructure

1. Change directory into the Terraform folder in this repository.

2. Create your `terraform.tfvars` file using the `terraform.tfvars.example`.

    This file represents the variables which terraform are used to determine the infrastructure to deploy.
    
    You can retrieve your Client ID using:
    
    ```bash
    ➜ az ad sp list --display-name <name of service principal> | grep appId 
    ```
   
   If you do not know your Client Secret, you can reset it with the following command:
   
   ```bash
   ➜ az ad sp credential reset --name <name of service principal>
   ```
    
3. To list available local workspaces, use the following command:
   
   ```terraform workspace list```
   
4. To create a new workspace use the following command:

   ```terraform workspace new <Name of Workspace>```
   
   Terraform will automatically switch to the newly created workspace.
   
5. Initialise Terraform:

   ```terraform init```
   
6. Create a Terraform plan using the following command:

   ```terraform
   terraform plan -out=terraform.tfstate.d/<Name of Workspace>/terraform_plan
   ```

   This will output a plan to file, in the `terraform.tfstate.d/<Workspace Name>` directory.
   
7. When you are happy with the plan, run the following command to execute the deployment:

   ```terraform
   terraform apply "terraform.tfstate.d/<Name of Workspace>/terraform_plan"
   ```

