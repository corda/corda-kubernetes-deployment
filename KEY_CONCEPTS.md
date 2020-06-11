# KEY CONCEPTS / TOOLS

## Docker image generation

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

## HELM

Helm is an orchestrator for Kubernetes, which allows us to parametrize the whole installation into a few simple values in one file (``helm/values.yaml``).
This file is also used for the initial registration phase.

## CONFIGURATION

Notable configuration options in the Helm values file include the following:

- Enable / disable Corda Firewall use
- Enable / disable out-of-process Artemis use, with / without High-Availability setup
- Enable / disable HSM (Hardware Security Module) use

## Public Key Infrastructure (PKI) generation

Some parts of the deployment use independent PKI structure. This is true for the Corda Firewall. The two components of the Corda Firewall, the Bridge and the Float communicate with each other using mutually authenticated TLS using a common certificate hierarchy with a shared trust root.
One way to generate this certificate hierarchy is by use of the tools located in the folder ``corda-pki-generator``.
This is just an example for setting up the necessary PKI structure and does not support storing the keys in HSMs, for that additional work is required and that is expected in an upcoming version of the scripts.

## INITIAL REGISTRATION

The initial registration of a Corda Node is a one-time step that issues a Certificate Signing Request (CSR) to the Identity Manager on the Corda Network and once approved returns with the capability to generate a full certificate chain which links the Corda Network Root CA to the Subordinate CA which in turn links to the Identity Manager CA and finally to the Node CA.
This Node CA is then capable of generating the necessary TLS certificate and signing keys for use in transactions on the network.

This process is generally initiated by executing ``java -jar corda.jar initial-registration``.
The process will always need access to the Corda Network root truststore. This is usually assigned to the above command with additional parameters ``--network-root-truststore-password $TRUSTSTORE_PASSWORD --network-root-truststore ./workspace/networkRootTrustStore.jks``.

The ``networkRootTrustStore.jks`` file should be placed in folder ``helm/files/network``.

Once initiated the Corda Node will start the CSR request and wait indefinitely until the CSR request returns or is cancelled.
If the CSR returns successfully, next the Node will generate the certificates in the folder ``certificates``.
The generated files from this folder should then be copied to the following folder: ``helm/files/certificates/node``.

The following is performed by initiating an initial-registration step:

- Contacts the [Corda Network](https://corda.network/) or a private Corda Network with a request to join the network with a CSR (Certificate Signing Request).
- Generates Node signing keys and TLS keys for communicating with other Nodes on the network

The scripted initial-registration step can be found in the following folder ``helm/initial-registration/``.

Just run script ``initial-registration.sh``

The following steps should also be performed in a scripted manner, however, they are not implemented yet:

- Places the Private keys corresponding to the generated certificates in an HSM (if HSM is configured to be used)
- Generates Artemis configuration with / without High-Availability setup
