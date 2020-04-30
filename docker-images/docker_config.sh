#!/bin/sh

set -u
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
set -eu

DOCKER_REGISTRY=""
DOCKER_REGISTRY=$(grep -A 3 'containerRegistry:' $DIR/../helm/values.yaml | grep 'serverAddress: "' | cut -d '"' -f 2)

VERSION="4.0"
HEALTH_CHECK_VERSION="4.0"

CORDA_VERSION="corda-ent-$VERSION"
CORDA_IMAGE_PATH="corda_image_ent_$VERSION"
CORDA_DOCKER_IMAGE_VERSION="v1.00"

CORDA_FIREWALL_VERSION="corda-firewall-$VERSION"
CORDA_FIREWALL_IMAGE_PATH="corda_image_firewall_$VERSION"
FIREWALL_DOCKER_IMAGE_VERSION="v1.00"
