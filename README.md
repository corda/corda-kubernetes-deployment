# CORDA KUBERNETES DEPLOYMENT

This repository (<https://github.com/corda/corda-kubernetes-deployment>) contains the means with which you can stand up a [Corda Enterprise](https://www.r3.com/corda-platform/) Node.

This is meant to be a customizable version of the Node deployment that you can take as-is if it fits your needs or then customize it to your liking.

**DISCLAIMER:**

This Kubernetes deployment for a Corda Enterprise Node is considered a **reference implementation** and should not be used in a production environment until sufficient testing has been done.

Licensed under [Apache License, version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

## IMPORTANT

Kubernetes is a complex system and setting it up a successful deployment for the first time can be challenging as well.

Please make sure you step through the [SETUP CHECKLIST](#setup-checklist) section carefully the first time you deploy, to avoid problems down the road.

Additional information on setup and usage of this Corda Kubernetes Deployment can be found on the [Corda Solutions Docs](https://solutions.corda.net/deployment/kubernetes/intro.html) site.

It is strongly recommended you review the documentation there before setting this up for the first time to familiarize yourself with the topic at hand.

---

## SETUP CHECKLIST

Since there are a number of prerequisites that need to be met and then a certain order of running everything, a checklist has been collated that you may find useful.

Please see [CHECKLIST.md](CHECKLIST.md) for more information.

**Note!**
It is strongly recommended you follow the CHECKLIST, to not skip an important step, especially the first time you set up this deployment,

---

## PREREQUISITES

* A cloud environment with Kubernetes Cluster Services that has access to a Docker Container Registry, see [CLOUD_SETUP.md](CLOUD_SETUP.md)
* Building the images requires local [Docker](https://www.docker.com/) installation
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) is used to manage Kubernetes cluster
* [Helm](https://helm.sh/) version 2.x
* Access to Corda Enterprise binary files or access to R3 Artifactory for Enterprise (licensed users)

---
---

## SETUP

### BINARIES

This deployment is targeting an Enterprise deployment, which should include a Corda Node, but also the Corda Firewall, which is an Enterprise only feature.

In order to execute the following scripts correctly, you will have to have access to the Corda Enterprise binaries.

The files should be downloaded first and placed in the following folder: ``docker-images/bin``

You can use the helper script ``download_binaries.sh`` to download binaries for you, as long as you have the necessary login details available for the R3 Artifactory.

If you have R3 Artifactory access, the download will be automatic as part of the ``one-time-setup.sh`` script, which is the recommended way of performing the first time setup.

Please see [docker-images/README.md](docker-images/README.md) for more information.

### CONFIGURATION VALUES

You must completely fill out the [helm/values.yaml](helm/values.yaml) file according to your configuration.

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

---

## USAGE (ALSO SEE ``SETUP`` above)

This is a brief view of the steps you will take, for the full set of steps, please review [CHECKLIST.md](CHECKLIST.md).

1. Customize the Helm ``values.yaml`` file according to your deployment (this step is used by initial-registration and Helm compile, very important to fill in correctly and completely)
2. Execute ``one-time-setup.sh`` which will do the following (you can also step through the steps on your own, just follow what the one-time-setup.sh would have done):
	1. Build the docker images and push them to the Container Registry
	2. Generate the Corda Firewall PKI certificates
	3. Execute initial registration step (which should copy certificates to the correct locations under ``helm/files``)
3. Build Helm templates and install them onto the Kubernetes Cluster (by way of executing either ``deploy.sh`` or ``helm/helm_compile.sh``)
4. Ensure that the deployment has been successful (log in to the pods and check that they are working correctly, please see below link for information on how to do that)

---

## DOCUMENTATION

For more details and instructions it is strongly recommended to visit the following page on the Corda Solutions docs site: 
<https://solutions.corda.net/deployment/kubernetes/intro.html>

For additional documentation please find it here [Documentation](DOCUMENTATION.md).

---

### KEY CONCEPTS & TOOLS

You may want to familiarize yourself with the key concepts of a production grade deployment and the tools being used in this deployment.

You can find the information in [Key Concepts](KEY_CONCEPTS.md).

---

## ROADMAP

To see the intended direction that this deployment should take, please have a look at the [Roadmap](ROADMAP.md)

---

## Contributing

The Corda Kubernetes Deployment is an open-source project and contributions are welcome as seen here: [Contributing](CONTRIBUTING.md)

The contributors can be found here: [Contributors](CONTRIBUTORS.md)

---

## Feedback

Any suggestions / issues are welcome in the issues section: <https://github.com/corda/corda-kubernetes-deployment/issues/new>

Fin.
