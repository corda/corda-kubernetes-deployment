#!/bin/sh

set -eux

# Absolute path of this script, e.g. /opt/corda/node/foo.sh
ABS_PATH=$(readlink -f "$0")
# Absolute path of the directory this script is in, thus /opt/corda/node/
DIR=$(dirname "$ABS_PATH")
source $DIR/docker_config.sh

# Make sure Docker is ready
docker ps &>/dev/null
status=$?
if [ $status -eq 0 ]
then
	echo "Docker is ready..."
else
	echo "!!! Docker engine not available, make sure your Docker is running and responds to command 'docker ps' !!!"
	exit 1
fi


NO_CACHE=
if [ "${1-}" == "no-cache" ]
then
	NO_CACHE=--no-cache
fi 

cp $DIR/bin/$CORDA_VERSION.jar $DIR/$CORDA_IMAGE_PATH/corda.jar
cp $DIR/bin/corda-tools-health-survey-$HEALTH_CHECK_VERSION.jar $DIR/$CORDA_IMAGE_PATH/corda-tools-health-survey.jar
cd $DIR/$CORDA_IMAGE_PATH
docker build -t $CORDA_IMAGE_PATH:$CORDA_DOCKER_IMAGE_VERSION . -f Dockerfile $NO_CACHE
rm corda.jar
rm corda-tools-health-survey.jar
cd ..

cp $DIR/bin/$CORDA_FIREWALL_VERSION.jar $DIR/$CORDA_FIREWALL_IMAGE_PATH/corda-firewall.jar
cd $DIR/$CORDA_FIREWALL_IMAGE_PATH
docker build -t $CORDA_FIREWALL_IMAGE_PATH:$FIREWALL_DOCKER_IMAGE_VERSION . -f Dockerfile $NO_CACHE
rm corda-firewall.jar
cd ..

docker images "corda_*"
