# CORDA DOCKER IMAGES

In this section we define the structure of the Docker images that our deployment will be using.

The scripts we will be using are as follows:

- ``docker_config.sh``, contains the customisation options that are read automatically from values.yaml, the following scripts use this file
- ``download_binaries.sh``, downloads the required Corda binaries (as specified in values.yaml, cordaVersion)
- ``build_docker_images.sh``, this script will compile the Docker images based on the Docker files and necessary binaries
- ``push_docker_images.sh``, this script will push the local Docker images to a remote repository, the Container Registry. Please note that your Kubernetes Cluster should have access to the Container Registry, please see root README.md for more information

## PREREQUISITES

Before executing the above mentioned scripts, the scripts need access to the Corda Enterprise binaries, these files should be placed in the ``bin``-folder, namely:

- Corda Enterprise Node jar file, e.g. [R3 Artifactory: corda-ent-4.0.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda/4.0/corda-4.0.jar)
- Corda Firewall jar file, e.g. [R3 Artifactory: corda-firewall-4.0.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda-firewall/4.0/corda-firewall-4.0.jar)
- Corda Health Survey Tool jar file, e.g. [R3 Artifactory: corda-tools-health-survey-4.2.20191122.jar](https://ci-artifactory.corda.r3cev.com/artifactory/corda-enterprise/com/r3/corda/corda-tools-health-survey/4.0/corda-tools-health-survey-4.0.jar)

Either you can download them from the [R3 Artifactory](https://ci-artifactory.corda.r3cev.com/artifactory/webapp/#/artifacts/browse/tree/General/corda-enterprise) (login details required) 
or then you may have these files shared with you separately, in which case you just have to copy them to the correct folder.
The recommended way is however to use the functionality within ``download_binaries.sh`` and have the scripts download the binaries for you. (the R3 Artifactory user details have to be set for this step to work)

If you do not have a license for Corda Enterprise, you can apply for an evaluation version here (you have to sign the Corda evaluation license agreement): 
[Corda Enterprise Evaluation](https://www.r3.com/download-corda-enterprise/)

## CONFIGURATION

All the relevant configuration options can be found in the file ``helm/values.yaml``.
