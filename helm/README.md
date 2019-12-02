# Corda Deployment Chart

This Helm Chart deploys a Corda Node with optional Corda Firewall onto a Kubernetes cluster.

---

## Prerequisites

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

## Installation

First we have to create a namespace for this installation, if installing multiple nodes, the namespace should be customized per installation.

    kubectl create namespace corda

Next we generate the Kubernetes templates that we will be deploying to the Kubernetes Cluster.

    helm template . --name corda --namespace corda --output-dir output

Next we deploy the template to the cluster.

    kubectl apply -f output --namespace=corda

This step can be repeated if you change any of the parameters in the template.
