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

ResetEnvironment () {
	echo "====== Resetting deployment environment next ... ====== "
	echo "WARNING!"
	echo "This will remove certificates from your local file system."
	echo "If you are sure this is what you want to do, please type 'yes' and press enter."
	read -p "Enter 'yes' to continue: " confirm
	echo $confirm
	if [ "$confirm" = "yes" ]; then
		echo "Resetting environment..."
		rm -rf $DIR/corda-pki-generator/pki-firewall/certs/
		checkStatus $?
		mkdir -p $DIR/corda-pki-generator/pki-firewall/certs/
		rm -rf $DIR/helm/files/certificates/node/
		checkStatus $?
		mkdir -p $DIR/helm/files/certificates/node/
		rm -rf $DIR/helm/files/certificates/firewall_tunnel/
		checkStatus $?
		mkdir -p $DIR/helm/files/certificates/firewall_tunnel/
		rm -rf $DIR/helm/files/network/*.file
		checkStatus $?
		rm -rf $DIR/helm/initial_registration/output/corda/templates/workspace/
		checkStatus $?
		mkdir -p $DIR/helm/initial_registration/output/corda/templates/workspace/
		echo "Environment now reset, you can execute one-time-setup.sh again."
	fi
	echo "====== Resetting deployment environment completed. ====== "
}
ResetEnvironment
