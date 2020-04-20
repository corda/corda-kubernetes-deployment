# CLOUD INFRASTRUCTURE SETUP INSTRUCTIONS

In order to use the Corda Kubernetes Deployment, you will need to have the necessary platform on which to deploy.
This comes in the shape of a Kubernetes cluster and Container registry, but also should have persistent storage set up.
Next are some instructions on how to set up the infrastructure.
Setting up the relevant cloud services is currently left to the reader, this may change in future versions of the scripts to be more automated.

---

## Azure cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### Azure Kubernetes Service (AKS)

This is the main Kubernetes cluster that we will be using. Setting up the AKS will also set up a NodePool resource group. The NodePool should also have a few public IP addresses configured as Front End IP addresses for the AKS cluster.

A good guide to follow for setting up AKS: [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough).

Worth reading the ACR section at the same time to combine the knowledge and setup process.

### Azure Container Registry (ACR)

The ACR provides the Docker images for the AKS to use. Please make sure that the AKS can connect to the ACR using appropriate Service Principals. See: [Azure Container Registry authentication with service principals](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal). 

Guide for setting up ACR: [Tutorial: Deploy and use Azure Container Registry](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr).

Guide for connecting ACR and AKS: [Authenticate with Azure Container Registry from Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration).

Worth reading the AKS section at the same time to combine the knowledge and setup process.

### Azure Service Principals

Service Principals is Azures way of delegating permissions between different services within Azure. There should be at least one Service Principal for AKS which can access ACR to pull the Docker images from there.

Here is a guide to get your started on SPs: [Service principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal).

### Azure Storage Account

In addition to that there should be a storage account that will host the persistent volumes (File storage).

Guide on setting up Storage Accounts: [Create an Azure Storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal).

### Public IP addresses

You should have a few static public IP addresses available for each deployment. One for the Node to accept incoming RPC connections from an UI level and another one if running the Float component within the cluster, this would then be the public IP address that other nodes would see and connect to.

A guide on setting up Public IP addresses in Azure: [Create, change, or delete a public IP address](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address).

---

## AWS cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### Amazon EKS - Elastic Kubernetes Service (EKS)

Amazon EKS is the Kubernetes cluster on AWS. 

Here is a nice guide on setting up an EKS [Creating an Amazon EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html).

You will need to create a VPC and IAM role for this to work, but the guide describes it quite well.

We will need to set one up along with a node group (node pool), [Guide on node group setup](https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html).

### Amazon ECR - Elastic Container Registry (ECR)

The ECR is the container registry, and it is required in order to host our custom built Docker images.
[Creating a Repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html).

In addition to creating this ECR, you will have to remember to set the containerRegistry.username as "AWS" in the values.yaml file in the helm sub folder.

### Amazon EBS - Elastic Block Storage (EBS)

The way Amazon handles persistent storage for Kubernetes clusters is by way of EBS. We will have to provision some EBS volumes and dedicate a host for them.
In order to set them up we should start by following this guide: [EC2 + EBS volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/add-instance-store-volumes.html).

Please make sure you create at least the following:

* 1Gb EBS volume for the Float component
* 1Gb EBS volume for the Bridge component
* 2Gb EBS volume for the Node

The volumes have to be assigned to a specific host, and that host also has to be specified in the values.yaml file in the helm sub folder later on in the installation, so keep the volume IDs and the host name (Private DNS) of the EC2 instance ready.

The reason for this is that we will have to use [Topology-Aware Volume Provisioning in Kubernetes](https://kubernetes.io/blog/2018/10/11/topology-aware-volume-provisioning-in-kubernetes/).

For more information on Amazons EBS read [Block Device Mapping](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/block-device-mapping-concepts.html).

The Kubernetes deployments will later on also be using nodeAffinity [](https://success.docker.com/article/how-to-control-container-placement-in-kubernetes-deployments) to successfully target the specific EC2 instance.

---

## GCP cloud instructions

Coming soon...

---
