#!/bin/sh

set -eux

# Absolute path of this script, e.g. /opt/corda/node/foo.sh
ABS_PATH=$(readlink -f "$0")
# Absolute path of the directory this script is in, thus /opt/corda/node/
DIR=$(dirname "$ABS_PATH")
source $DIR/docker_config.sh

docker login $DOCKER_REGISTRY

docker tag $CORDA_IMAGE_PATH:$CORDA_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/$CORDA_IMAGE_PATH:$CORDA_DOCKER_IMAGE_VERSION
docker tag $CORDA_FIREWALL_IMAGE_PATH:$FIREWALL_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/$CORDA_FIREWALL_IMAGE_PATH:$FIREWALL_DOCKER_IMAGE_VERSION

docker push $DOCKER_REGISTRY/$CORDA_IMAGE_PATH:$CORDA_DOCKER_IMAGE_VERSION
docker push $DOCKER_REGISTRY/$CORDA_FIREWALL_IMAGE_PATH:$FIREWALL_DOCKER_IMAGE_VERSION