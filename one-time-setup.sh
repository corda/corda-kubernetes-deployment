#!/bin/bash

set -u
DIR="."
GetPathToCurrentlyExecutingScript () {
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	set +e
	ABS_PATH=$(readlink -f "$0")
	if [ "$?" -ne "0" ]; then
		echo "readlink issue workaround..."
		# Unfortunate MacOs issue with readlink functionality, see https://github.com/corda/corda-kubernetes-deployment/issues/4
		TARGET_FILE=$0

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

checkStatus () {
	status=$1
	if [ $status -eq 0 ]
		then
			echo "."
		else
			echo "The previous step failed"
			exit 1
	fi	
	return 0
}

OneTimeSetup () {
	echo "====== One Time Setup Script ====== "
	$DIR/docker-images/build_docker_images.sh
	checkStatus $?
	$DIR/docker-images/push_docker_images.sh
	checkStatus $?
	$DIR/corda-pki-generator/generate_firewall_pki.sh
	checkStatus $?

	INITIAL_REGISTRATION=""
	INITIAL_REGISTRATION=$(grep -A 3 'initialRegistration:' $DIR/helm/values.yaml | grep 'enabled: ' | cut -d ':' -f 2 | xargs)

	if [ "$INITIAL_REGISTRATION" = "true" ]; then
		$DIR/helm/initial_registration/initial_registration.sh
		checkStatus $?
	else 
		echo "Skipping initial registration step. (disabled in values.yaml)"
	fi

	echo "====== One Time Setup Script completed. ====== "
}
OneTimeSetup
