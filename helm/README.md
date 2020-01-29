# Corda Kubernetes Deployment Chart

This directory contains two Helm charts, one for initial registration of a Corda Node and one for deploying the Corda Node along  with optional Corda Firewall to a Kubernetes cluster.

---

## Prerequisites

- Corda Enterprise binaries available in ``docker-images/bin`` folder as per previous steps in ``corda-kubernetes-deployment``
- Kubernetes cluster set up with access to a Docker Container Registry
- Docker Container Registry
- StorageClass linked to correctly set up Cloud storage
- Database cluster with JDBC connection string
- kubectl is used to manage Kubernetes cluster (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- Helm (https://helm.sh/)

---

## Configuration

All the values listed in `values.yaml` can be modified to customise the deployment of the Corda Node.
Please pay attention to correct spelling of the content of each variable.

## Initial registration

The one time registration of a Corda Node to a Corda Network has to be performed before deploying the Nodes to the Kubernetes cluster. 
This can be done by executing the script ``initial_registration/initial_registration.sh`` 

NOTE! Make sure you have completed ALL prerequisites (also in corda-kubernetes-deployment) and filled in ``values.yaml`` entirely

## Installation

Executing ``helm_compile.sh`` will compile the Helm charts into Kubernetes templates and apply them directly to the Kubernetes cluster.

This is the recommended mode of operation. (you may use ``delete-all.sh`` to clean out the cluster for a fresh deploy)

## Manual Installation

First we have to create a namespace for this installation, if installing multiple nodes, the namespace should be customized per installation.

    kubectl create namespace corda

Next we generate the Kubernetes templates that we will be deploying to the Kubernetes Cluster.

    helm template . --name corda --namespace corda --output-dir output

Next we deploy the template to the cluster.

    kubectl apply -f output --namespace=corda

This step can be repeated if you change any of the parameters in the template.
