# CORDA KUBERNETES DEPLOYMENT OPTION

This repository (<http://github.com/corda/corda-deployments/kubernetes/)> contains the means with which you can stand up a Corda Node (<https://www.corda.net/).>

This is meant to be a customizable version of the Node deployment that you can take as-is if it fits your needs or then customize it to your liking.

Licensed under Apache License, version 2.0 (<https://www.apache.org/licenses/LICENSE-2.0).>

---

## PREREQUISITES

- A cloud environment with Kubernetes Cluster Service that has access to a Docker Container Registry
- Currently only supporting Azure:
  - Azure Kubernetes Service (<https://azure.microsoft.com/en-gb/services/kubernetes-service/)> & Azure Container Registry (<https://azure.microsoft.com/en-gb/services/container-registry/)>
- Building the images requires local Docker installation (<https://www.docker.com/)>
- kubectl is used to manage Kubernetes cluster (<https://kubernetes.io/docs/tasks/tools/install-kubectl/)>
- Helm (<https://helm.sh/)>
- Corda Enterprise jar downloaded and stored in 'bin' folder

---

## Azure cloud instructions

These are the services you will need to have set up in order to execute the deployment scripts correctly.

### Azure Kubernetes Service (AKS)

This is the main Kubernetes cluster that we will be using. Setting up the AKS will also set up a NodePool resource group. The NodePool should also have a few public IP addresses configured as Front End IP addresses for the AKS cluster.

### Azure Container Registry (ACR)

The ACR provides the Docker images for the AKS to use. Please make sure that the AKS can connect to the ACR using appropriate Service Principals. See: <https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal>
In addition to that there should be a storage account that will host the persistent volumes (File storage).
You should have a few static public IP addresses available for each deployment. One for the Node to accept incoming RPC connections from an UI level and another one if running the Float component within the cluster, this would then be the public IP address that other nodes would see and connect to.

---

## SETUP

Execute build_docker_images.sh to compile the Docker image we will be using.

Running docker images "corda_*" should reveal the newly created image:

```
	REPOSITORY				TAG		IMAGE ID		CREATED			SIZE
	corda_image_ent_4.0   	v1.0	4c037385e632	5 minutes ago	363MB
```

---

## KEY CONCEPTS / TOOLS

### HELM

Helm is an orchestrator for Kubernetes, which allows us to parametrize the whole installation into a few simple values in one file (``helm/values.yaml``).
This file is also used for the initial registration phase.

### CONFIGURATION

Notable configuration options in the Helm values file include the following:

- Enable / disable Corda Firewall use
- Enable / disable out-of-process Artemis use, with / without High-Availability setup
- Enable / disable HSM (Hardware Security Module) use

### INITIAL REGISTRATION

Before we can stand up our Node on the network, it will have to have the required certificates installed.
This is done by initiating an initial-registration step. What this step does is it takes the configuration options and handles them approriately.

If a Corda Firewall is being deployed as part of the deployment:

- Contacts the Corda Network (<https://corda.network/)> or a private Corda Network with a request to join the network with a CSR (Certificate Signing Request).
- Generates Node signing keys and TLS keys for communicating with other Nodes on the network
- Generates PKI tunnel certificates for the Bridge & Float
- Places the Private keys corresponding to the above certificates in the HSM that is being used (if HSM is configured to be used)
- Generates Artemis configuration with / without High-Availability setup

## USAGE

1. Start by downloading the required binaries
2. Generate the certificates
3. Build the docker images and push them to the Container Registry
4. Build Helm templates and install them onto the Kubernetes Cluster
5. Ensure that the deployment has been successful

### Feedback

Any suggestions / issues are welcome in the issues section: <https://github.com/corda/corda-deployments/issues/new>

Fin.
