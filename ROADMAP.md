# CORDA KUBERNETES DEPLOYMENT ROADMAP

This repository (<https://github.com/corda/corda-kubernetes-deployment>) is not complete, here is the roadmap for the next features to make the deployment more complete.

## Support for Amazon Web Services (AWS)

The first version of the deployment only added support for Microsoft's Azure cloud platform.

### Goals: 

- Add support for AWS in the deployment

## Support for Google Cloud Platform (GCP)

The first version of the deployment only added support for Microsoft's Azure cloud platform.

### Goals: 

- Add support for GCP in the deployment

## Support for local Kubernetes clusters

The first version of the deployment only added support for Microsoft's Azure cloud platform.

### Goals: 

- Add support for deploying this setup on a local cluster

## HA utilities support

[HA utilities](<https://docs.corda.r3.com/ha-utilities.html>) adds support for Corda Firewall PKI generation and HSM integration for the initial registration phase. 
It can even generate the configuration required to set up external Artemis (out-of-process Artemis).

### Goals: 

- Change Initial registration step to use HA utilities.

## HSM support

Hardware Security Modules (HSM) are a must in order to keep private key material absolutely private. 
There are options to keep private key material safe, but by using an HSM it can be completely private.
This is a requirement for many larger corporations and banks.

### Goals: 

- Enable Initial registration step to use HA utilities to add private key material directly to HSM.
- Add support for the Corda Node and the Corda Firewall components to use the keys from the HSM.

## Artemis support

Artemis is the message queue that the Corda Node uses to communicate with other nodes on the network, whether it be via a Corda Firewall or not.
Adding support for Artemis allows the option to host multiple Corda Nodes behind a shared Artemis <> Bridge <> Float setup.
This can be both a cost benefit but also helps define the High Availability (HA) setup.

### Goals: 

- Enable Initial registration step to generate the Artemis configuration and potentially the full installation of Artemis that could can then be deployed in between Corda Node and Corda Firewalls Bridge component.

## CorDapp distribution

The CorDapps are currently installed by a direct copy command during the deployment step.
This may not be the best way to handle CorDapps in the future, for example in order to handle upgrade scenarios.

### Goals:

- Investigate different ways to handle CorDapp distribution for the deployment
- Define a working design for the necessary new distribution options and add them back to the roadmap

## Upgrading scenarios

There are many upgrading scenarios that should be tackled. These include, but are not necessarily limited to:

- Corda Network upgrades, network-parameters (minimumPlatformVersion, whitelisted notaries etc.)
- Corda version upgrades, if a new version of Corda is required, steps to upgrade it in a reliable manner
- CorDapp version upgrades, if a new version of the CorDapp is required, steps to upgrade it in a reliable manner

### Goals:

- Define upgrading best practices for the deployment to tackle the above 3 scenarios
- Define the designs for these upgrading options and place them in the roadmap

## Monitoring and Health Probes

It is important to be able to monitor and probe the pods health to be able to react to any detrimental changes over time.
For example, if the memory usage goes above 80%, take an action. Or if the pod is restarting regularly, take an action.

### Goals: 

- Define the best practices of health probing for the different components
- Define and design a monitoring solution that is standardized

## Testing

### Performance testing

An extensive set of performance tests should be executed on the deployment to figure out potential bottlenecks and then address those issues accordingly.

### Penetration testing

An extensive set of penetration tests should be executed on the deployment to figure out potential security issues and then address those issues accordingly.

## Distribution-less Docker Images

High security environments demand that the Docker image is not based on a specific Distribution, it should be custom built, as in define exactly what it will contain.

### Goals:

- Add support for Distribution-less Docker images
