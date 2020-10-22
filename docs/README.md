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

### Usage: Deployment & Debugging issues

[Usage](USAGE.md)

### Cost calculation of Kubernetes deployment versus a traditional bare-metal deployment

We have received many requests to compare the cost of deploying using Kubernetes versus a traditional bare-metal based installation.

Although the answer will be dependent on the use-case specific details, for example are we talking about high-frequency trading with high number of transactions per second or 
are we talking about high quality asset issuance which occurs much less frequently, we can still generate some rough estimates that hopefully will be useful as indications.

The details can be found in this dedicated document: 
[Cost calculation & comparison](COST_CALCULATION.md)
