# CORDA DOCKER IMAGES

In this section we define the structure of the Docker images that our deployment will be using.

The scripts we will be using are as follows:

- ``docker_config.sh``, contains the customisation options that you can define for your deployment, for example which version of Corda Enterprise to use
- ``build_docker_images.sh``, this script will compile the Docker images based on the Docker files and necessary jars
- ``push_docker_images.sh``, this script will push the local Docker images to a remote repository, the Container Registry. Please note that your Kubernetes Cluster should have access to the Container Registry, please see root README.md for more information

## PREREQUISITES

Before executing the above mentioned scripts, the scripts need access to the Corda Enterprise binaries, these files should be placed in the ``bin``-folder, namely:

- Corda Enterprise Node jar file, e.g. [R3 Artifactory: corda-ent-4.0.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda/4.0/corda-4.0.jar)
- Corda Firewall jar file, e.g. [R3 Artifactory: corda-firewall-4.0.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda-firewall/4.0/corda-firewall-4.0.jar)
- Corda Health Survey Tool jar file, e.g. [R3 Artifactory: corda-tools-health-survey-4.2.20191122.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda-tools-health-survey/4.0/corda-tools-health-survey-4.0.jar)

Either you can download them from the [R3 Artifactory](https://ci-artifactory.corda.r3cev.com/artifactory/webapp/#/artifacts/browse/tree/General/corda-enterprise) (login details required) or then you may have these files shared with you separately, in which case you just have to copy them to the correct folder.

## CONFIGURATION

Main configuration options in the file ``docker_config.sh`` are as follows:

- ``DOCKER_REGISTRY``, defines the Container Registry location to use, example: <container-registry.mydomain.com>
- ``VERSION``, defines the version of Corda Enterprise we are using, default is 4.0
- ``HEALTH_CHECK_VERSION``, defines the version of the Corda Health Survey version to use, the default is 4.0, for more information see <https://solutions.corda.net/deployment/corda-health-checker.html>
- ``CORDA_DOCKER_IMAGE_VERSION``, the published version number of the Docker image for the Node, the default is ``v1.00``, which you can use as starting point an increment if you make changes to your Docker file
- ``FIREWALL_DOCKER_IMAGE_VERSION``, the published version number of the Docker image for the Corda Firewall, the default is ``v1.00``, which you can use as starting point an increment if you make changes to your Docker file

Fin.
