# CORDA KUBERNETES DEPLOYMENT

This repository (<https://github.com/corda/corda-kubernetes-deployment>) contains the means with which you can stand up a Corda Node (<https://www.corda.net/).>

This is meant to be a customizable version of the Node deployment that you can take as-is if it fits your needs or then customize it to your liking.

**DISCLAIMER:**

**THIS IS AN EXPERIMENTAL VERSION WHICH SHOULD NOT BE USED IN PRODUCTION.**

**IT CAN BE USED TO SET UP TEST ENVIRONMENTS AND TO LEARN ABOUT DEPLOYING CORDA AND OTHER ENTERPRISE COMPONENTS.**

Licensed under Apache License, version 2.0 (<https://www.apache.org/licenses/LICENSE-2.0).>

---

## MORE INFORMATION

Additional information on setup and usage of this Corda Kubernetes Deployment can be found on the Corda Solutions Docs site: <https://solutions.corda.net/deployment/kubernetes/intro.html>

It is strongly recommended you review all of the documentation there before setting this up for the first time.

---

## PREREQUISITES

* A cloud environment with Kubernetes Cluster Services that has access to a Docker Container Registry
* Note! The current version of the scripts only supports Azure out of the box by way of Azure Kubernetes Service and Azure Container Registry, future versions of the scripts may add support for other cloud providers
* Building the images requires local Docker installation (<https://www.docker.com/)>
* kubectl is used to manage Kubernetes cluster (<https://kubernetes.io/docs/tasks/tools/install-kubectl/)>
* Helm (<https://helm.sh/)>
* Corda Enterprise jars downloaded and stored in 'bin' folder

---

## BINARIES

This deployment is targeting an Enterprise deployment, which should include a Corda Node, but also the Corda Firewall, which is an Enterprise only feature.

In order to execute the following scripts correctly, you will have to have access to the Corda Enterprise binaries.
The files should be downloaded first and placed in the following folder: ``docker-images/bin``

Please see ``docker-images/README.md`` for more information.

---

## Azure cloud instructions

Setting up the relevant cloud services is currently left to the reader, this may change in future versions of the scripts.
Having said that though, these are the services you will need to have set up in order to execute the deployment scripts correctly.

### Azure Kubernetes Service (AKS)

This is the main Kubernetes cluster that we will be using. Setting up the AKS will also set up a NodePool resource group. The NodePool should also have a few public IP addresses configured as Front End IP addresses for the AKS cluster.

A good guide to follow for setting up AKS: [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough>)

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

## SETUP

### READ ME FIRST

#### BINARIES

The scripts contained within require you to have the necessary binaries in place, as previously mentioned in this document.

#### CONFIGURATION VALUES

You must completely fill out the ``helm/values.yaml`` file according to your configuration.

Last time I ran this script in a fresh installation, I only had to modify the following fields:

``config.``:

* nodeLoadBalancerIP
* floatLoadBalancerIP

``config.containerRegistry.``:

* serverAddress
* username
* password
* email

``config.storage.azureFile.``:

* account
* azureStorageAccountName
* azureStorageAccountKey

``corda.node.conf.``:

* legalName
* emailAddress
* p2pAddress
* identityManagerAddress
* networkmapAddress

For the rest of the options the defaults worked for me, but you may find that you have to modify more configuration options for your deployment.

#### ONE-TIME SETUP

There is an automated way to perform the one-time setup by executing ``one-time-setup.sh``, which does all the necessary steps, provided you have completed the previous sections.

---

## KEY CONCEPTS / TOOLS

### Docker image generation

We need to have the relevant Docker images in the Container Registry for Kubernetes to access.
This is accomplished by the following two scripts in the folder ``docker-images``:

* build_docker_images.sh
    Will compile the Dockerfiles into Docker images and tag them with the appropriate tags (that are customisable).
* push_docker_images.sh
    Pushes the created Docker images to the assigned Docker Registry.

Both of the above scripts rely on configuration settings in the file ``docker_config.sh``. The main variables to set in this file are ``DOCKER_REGISTRY``, ``HEALTH_CHECK_VERSION`` and ``VERSION``, the rest of the options can use their default values.

Execute build_docker_images.sh to compile the Docker image we will be using.

Running docker images "corda_*" should reveal the newly created image:

```
	REPOSITORY		TAG	IMAGE ID	CREATED		SIZE
	corda_image_ent_4.0	v1.0	4c037385e632	5 minutes ago	363MB
```

### HELM

Helm is an orchestrator for Kubernetes, which allows us to parametrize the whole installation into a few simple values in one file (``helm/values.yaml``).
This file is also used for the initial registration phase.

### CONFIGURATION

Notable configuration options in the Helm values file include the following:

- Enable / disable Corda Firewall use
- Enable / disable out-of-process Artemis use, with / without High-Availability setup
- Enable / disable HSM (Hardware Security Module) use

### Public Key Infrastructure (PKI) generation

Some parts of the deployment use independent PKI structure. This is true for the Corda Firewall. The two components of the Corda Firewall, the Bridge and the Float communicate with each other using mutually authenticated TLS using a common certificate hierarchy with a shared trust root.
One way to generate this certificate hierarchy is by use of the tools located in the folder ``corda-pki-generator``.
This is just an example for setting up the necessary PKI structure and does not support storing the keys in HSMs, for that additional work is required and that is expected in an upcoming version of the scripts.

### INITIAL REGISTRATION

The initial registration of a Corda Node is a one-time step that issues a Certificate Signing Request (CSR) to the Identity Manager on the Corda Network and once approved returns with the capability to generate a full certificate chain which links the Corda Network Root CA to the Subordinate CA which in turn links to the Identity Manager CA and finally to the Node CA.
This Node CA is then capable of generating the necessary TLS certificate and signing keys for use in transactions on the network.

This process is generally initiated by executing ``java -jar corda.jar initial-registration``.
The process will always need access to the Corda Network root truststore. This is usually assigned to the above command with additional parameters ``--network-root-truststore-password $TRUSTSTORE_PASSWORD --network-root-truststore ./workspace/networkRootTrustStore.jks``.

The ``networkRootTrustStore.jks`` file should be placed in folder ``helm/files/network``.

Once initiated the Corda Node will start the CSR request and wait indefinitely until the CSR request returns or is cancelled.
If the CSR returns successfully, next the Node will generate the certificates in the folder ``certificates``.
The generated files from this folder should then be copied to the following folder: ``helm/files/certificates/node``.

The following is performed by initiating an initial-registration step:

- Contacts the Corda Network (<https://corda.network/)> or a private Corda Network with a request to join the network with a CSR (Certificate Signing Request).
- Generates Node signing keys and TLS keys for communicating with other Nodes on the network

The scripted initial-registration step can be found in the following folder ``helm/initial-registration/``.

Just run script ``initial-registration.sh``

The following steps should also be performed in a scripted manner, however, they are not implemented yet:

- Places the Private keys corresponding to the generated certificates in an HSM (if HSM is configured to be used)
- Generates Artemis configuration with / without High-Availability setup

## USAGE (ALSO SEE ``SETUP`` above)

1. Start by downloading the required binaries
2. Customize the Helm ``values.yaml`` file according to your deployment (this step is used by initial-registration and Helm compile, very important to fill in correctly and completely)
3. Execute ``one-time-setup.sh`` which will do the following (you can also step through the steps on your own, just follow what the one-time-setup.sh would have done):
	1. Generate the Corda Firewall PKI certificates
	2. Execute initial registration step (which should copy certificates to the correct locations under ``helm/files``)
	3. Build the docker images and push them to the Container Registry
4. Build Helm templates and install them onto the Kubernetes Cluster (by way of executing either ``deploy.sh`` or ``helm/helm_compile.sh``)
5. Ensure that the deployment has been successful (log in to the pods and check that they are working correctly, please see below link for information on how to do that)

For more details and instructions it is strongly recommended to visit the following page on the Corda Solutions docs site: 
<https://solutions.corda.net/deployment/kubernetes/intro.html>

### Feedback

Any suggestions / issues are welcome in the issues section: <https://github.com/corda/corda-kubernetes-deployment/issues/new>

Fin.
