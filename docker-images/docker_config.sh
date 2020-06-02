#!/bin/bash

set -u
DIR="."
GetPathToCurrentlyExecutingScript () {
	SCRIPT_SRC=""
	set +u
	if [ "$BASH_SOURCE" = "" ]; then SCRIPT_SRC=""; else SCRIPT_SRC="${BASH_SOURCE[0]}"; fi
	if [ "$SCRIPT_SRC" = "" ]; then SCRIPT_SRC=$0; fi
	set -u
	
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	set +e
	ABS_PATH=$(readlink -f "${SCRIPT_SRC}" 2>&1)
	if [ "$?" -ne "0" ]; then
		echo "Using macOS alternative to readlink -f command..."
		# Unfortunate MacOs issue with readlink functionality, see https://github.com/corda/corda-kubernetes-deployment/issues/4
		TARGET_FILE=$SCRIPT_SRC

		cd $(dirname $TARGET_FILE)
		TARGET_FILE=$(basename $TARGET_FILE)
		ITERATIONS=0

		# Iterate down a (possible) chain of symlinks
		while [ -L "$TARGET_FILE" ]
		do
			TARGET_FILE=$(readlink $TARGET_FILE)
			cd $(dirname $TARGET_FILE)
			TARGET_FILE=$(basename $TARGET_FILE)
			ITERATIONS=$((ITERATIONS + 1))
			if [ "$ITERATIONS" -gt 1000 ]; then
				echo "symlink loop. Critical exit."
				exit 1
			fi
		done

		# Compute the canonicalized name by finding the physical path 
		# for the directory we're in and appending the target file.
		PHYS_DIR=$(pwd -P)
		ABS_PATH=$PHYS_DIR/$TARGET_FILE
	fi

	# Absolute path of the directory this script is in, thus /opt/corda/node/
	DIR=$(dirname "$ABS_PATH")
}
GetPathToCurrentlyExecutingScript
set -eu

DOCKER_CMD='docker'
EnsureDockerIsAvailableAndReachable () {
	# Make sure Docker is ready
	set +e
	$DOCKER_CMD ps > /dev/null 2>&1
	status=$?
	if [ $status -eq 0 ]
	then
		echo "Docker is available and reachable..."
	else
		$DOCKER_CMD ps 2>&1 | grep -q "permission denied"
		status=$?
		if [ $status -eq 0 ]; then 
			echo "Docker requires sudo to execute, trying to substitute using 'sudo docker'"
			DOCKER_CMD='sudo docker'
			$DOCKER_CMD ps 2>&1 | grep -q "permission denied"
			status=$?
			if [ $status -eq 0 ]; then 
				echo "Still issues with permissions, try a manual workaround where you set 'alias docker='sudo docker'' then run 'docker ps' to check that there is no 'permission denied' errors."
				exit 1
			else
				echo "Docker now accessible by way of sudo, continuing..."
			fi
		else
			echo "!!! Docker engine not available, make sure your Docker is running and responds to command 'docker ps' !!!"
			exit 1
		fi
	fi
	set -e
}
EnsureDockerIsAvailableAndReachable

DOCKER_REGISTRY=""
DOCKER_CONF_RAW=$(grep -A 8 'containerRegistry:' $DIR/../helm/values.yaml) # Find configuration path .Values.config.containerRegistry:
DOCKER_REGISTRY=$(echo "$DOCKER_CONF_RAW" | grep 'serverAddress: "' | cut -d '"' -f 2)
DOCKER_USER=$(echo "$DOCKER_CONF_RAW" | grep 'username: "' | cut -d '"' -f 2)
DOCKER_PASSWORD=$(echo "$DOCKER_CONF_RAW" | grep 'password: "' | cut -d '"' -f 2)

VERSION=""
VERSION=$(grep 'cordaVersion:' $DIR/../helm/values.yaml | cut -d '"' -f 2 | tr '[:upper:]' '[:lower:]')
HEALTH_CHECK_VERSION=$VERSION

CORDA_VERSION="corda-ent-$VERSION"
CORDA_IMAGE_PATH="corda_image_ent"
CORDA_DOCKER_IMAGE_VERSION="v1.00"

CORDA_FIREWALL_VERSION="corda-firewall-$VERSION"
CORDA_FIREWALL_IMAGE_PATH="corda_image_firewall"
FIREWALL_DOCKER_IMAGE_VERSION="v1.00"

CORDA_HEALTH_CHECK_VERSION="corda-tools-health-survey-$HEALTH_CHECK_VERSION"
