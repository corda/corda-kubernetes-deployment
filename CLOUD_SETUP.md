# CLOUD INFRASTRUCTURE SETUP INSTRUCTIONS

In order to use the Corda Kubernetes Deployment, you will need to have the necessary platform on which to deploy.
This comes in the shape of a Kubernetes cluster and Container registry, but also should have persistent storage set up.
Next are some instructions on how to set up the infrastructure.
Setting up the relevant cloud services is currently left to the reader, this may change in future versions of the scripts to be more automated.

---

## AWS cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### Amazon EKS - Elastic Kubernetes Service (EKS)

### Amazon ECR - Elastic Container Registry (ECR)

### Amazon EFS - Elastic File System (EFS)

---

## Azure cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### Azure Kubernetes Service (AKS)

This is the main Kubernetes cluster that we will be using. Setting up the AKS will also set up a NodePool resource group. The NodePool should also have a few public IP addresses configured as Front End IP addresses for the AKS cluster.

A good guide to follow for setting up AKS: [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough)

Worth reading the ACR section at the same time to combine the knowledge and setup process.

### Azure Container Registry (ACR)

The ACR provides the Docker images for the AKS to use. Please make sure that the AKS can connect to the ACR using appropriate Service Principals. See: [Azure Container Registry authentication with service principals](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal). 

Guide for setting up ACR: [Tutorial: Deploy and use Azure Container Registry](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr)

Guide for connecting ACR and AKS: [Authenticate with Azure Container Registry from Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)

Worth reading the AKS section at the same time to combine the knowledge and setup process.

### Azure Service Principals

Service Principals is Azures way of delegating permissions between different services within Azure. There should be at least one Service Principal for AKS which can access ACR to pull the Docker images from there.

Here is a guide to get your started on SPs: [Service principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)

### Azure Storage Account

In addition to that there should be a storage account that will host the persistent volumes (File storage).

Guide on setting up Storage Accounts: [Create an Azure Storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal)

### Public IP addresses

You should have a few static public IP addresses available for each deployment. One for the Node to accept incoming RPC connections from an UI level and another one if running the Float component within the cluster, this would then be the public IP address that other nodes would see and connect to.

A guide on setting up Public IP addresses in Azure: [Create, change, or delete a public IP address](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address)

---

## GCP cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### GCP kub

### GCP cr

File storage

---
