#!/bin/sh

set -ux
DIR="."
GetPathToCurrentlyExecutingScript () {
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	ABS_PATH=$(readlink -f "$0")
	if [ "$?" -ne "0" ]; then
		echo "readlink issue workaround..."
		# Unfortunate MacOs issue with readlink functionality, see https://github.com/corda/corda-kubernetes-deployment/issues/4
		TARGET_FILE=$0

		cd `dirname $TARGET_FILE`
		TARGET_FILE=`basename $TARGET_FILE`
		local ITERATIONS=0

		# Iterate down a (possible) chain of symlinks
		while [ -L "$TARGET_FILE" ]
		do
			TARGET_FILE=`readlink $TARGET_FILE`
			cd `dirname $TARGET_FILE`
			TARGET_FILE=`basename $TARGET_FILE`
			((++ITERATIONS))
			if [ "$ITERATIONS" -gt 1000 ]; then
				echo "symlink loop. Critical exit."
				exit 1
			fi
		done

		# Compute the canonicalized name by finding the physical path 
		# for the directory we're in and appending the target file.
		PHYS_DIR=`pwd -P`
		ABS_PATH=$PHYS_DIR/$TARGET_FILE
	fi

	# Absolute path of the directory this script is in, thus /opt/corda/node/
	DIR=$(dirname "$ABS_PATH")
}
GetPathToCurrentlyExecutingScript
set -eux

. $DIR/docker_config.sh

if [ "$DOCKER_REGISTRY" = "" ]; then
	echo "You must specify a valid container registry in the values.yaml file"
	exit 1
fi

docker login $DOCKER_REGISTRY

docker tag ${CORDA_IMAGE_PATH}:$CORDA_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/${CORDA_IMAGE_PATH}_$VERSION:$CORDA_DOCKER_IMAGE_VERSION
docker tag ${CORDA_FIREWALL_IMAGE_PATH}:$FIREWALL_DOCKER_IMAGE_VERSION $DOCKER_REGISTRY/${CORDA_FIREWALL_IMAGE_PATH}_$VERSION:$FIREWALL_DOCKER_IMAGE_VERSION

CORDA_DOCKER_REPOSITORY=$(echo $DOCKER_REGISTRY/${CORDA_IMAGE_PATH}_$VERSION:$CORDA_DOCKER_IMAGE_VERSION 2>&1 | tr '[:upper:]' '[:lower:]')
CORDA_FIREWALL_DOCKER_REPOSITORY=$(echo $DOCKER_REGISTRY/${CORDA_FIREWALL_IMAGE_PATH}_$VERSION:$FIREWALL_DOCKER_IMAGE_VERSION 2>&1 | tr '[:upper:]' '[:lower:]')
docker push $CORDA_DOCKER_REPOSITORY
docker push $CORDA_FIREWALL_DOCKER_REPOSITORY
