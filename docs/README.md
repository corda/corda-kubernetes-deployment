# Corda Kubernetes Deployment

## Overview

Kubernetes shines in orchestrating complex connection scenarios between multiple components and allowing these components to self-heal and recover from errors.
The Corda Node is quite a complex system to deploy when it is deployed with Corda Firewall and potentially utilising HSM for storing private key material.
This Kubernetes deployment is created to show you how to set up the different components in a Kubernetes cluster while still catering to best security practices.

The old documentation section was hosted at https://solutions.corda.net/deployment/kubernetes/intro.html (link to be removed in the future)

## TOPICS

### Architecture Overview

If you would like to see the high-level architectural view of the deployment, this is where you will find that information.

[Architecture Overview](ARCHITECTURE_OVERVIEW.md)

---

### Usage: Deployment & Debugging issues

In order to figure out how to perform the deployment successfully, and how to handle any issues that may come your way, please review the following:

[Usage](USAGE.md)

---

### KEY CONCEPTS & TOOLS

You may want to familiarize yourself with the key concepts of a production grade deployment and the tools being used in this deployment.
You can find the information in: 

[Key Concepts](KEY_CONCEPTS.md).

---

### SETUP CHECKLIST

Since there are a number of prerequisites that need to be met and then a certain order of running everything, a checklist has been collated that you may find useful.

Please see [CHECKLIST.md](CHECKLIST.md) for more information.

**Note!**
It is strongly recommended you follow the CHECKLIST, to not skip an important step, especially the first time you set up this deployment,

---

### Cloud infrastructure setup

This deployment requires a working cloud environment with Kubernetes Cluster Services that has access to a Docker Container Registry.
In order to set everything up, you may find the following document helpful:

[CLOUD_SETUP.md](CLOUD_SETUP.md)

---

### Cost calculation of Kubernetes deployment versus a traditional bare-metal deployment

We have received many requests to compare the cost of deploying using Kubernetes versus a traditional bare-metal based installation.

Although the answer will be dependent on the use-case specific details, for example are we talking about high-frequency trading with high number of transactions per second or 
are we talking about high quality asset issuance which occurs much less frequently, we can still generate some rough estimates that hopefully will be useful as indications.

The details can be found in this dedicated document: 
[Cost calculation & comparison](COST_CALCULATION.md)

---

### TESTED WITH

This deployment has been tested and verified with the following information: 

[SUPPORT_MATRIX.md](SUPPORT_MATRIX.md)

---

