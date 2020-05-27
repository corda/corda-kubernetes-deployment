#!/bin/bash

set -u
DIR="."
GetPathToCurrentlyExecutingScript () {
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	set +e
	ABS_PATH=$(readlink -f "$0" 2>&1)
	if [ "$?" -ne "0" ]; then
		echo "Using macOS alternative to readlink -f command..."
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

InitialRegistration () {
	echo "====== Performing Corda node Initial Registration next ... ====== "
	VERSION=$(grep 'cordaVersion:' $DIR/../values.yaml | cut -d '"' -f 2)

	OUTPUT_DIR=$DIR/output
	SCRIPT=$OUTPUT_DIR/corda/templates/initial_registration.sh
	OUTPUT_NODE_CONF=$OUTPUT_DIR/corda/templates/node.conf
	NODE_CONF=$DIR/../files/conf/node-$VERSION.conf

	if [ ! -f "$NODE_CONF" ]; then
		set +x
		echo "ERROR: The node.conf file could not be read, file path: $NODE_CONF"
		echo "This most likely means you are targetting a cordaVersion in the helm/values.yaml file which does not have a corresponding node.conf file in the helm/files subfolder."
		echo "This can in most cases easily be fixed by copying an existing node.conf file and naming it according to the version you want to use."
		echo "Please follow this guide: If you are deploying a version 4.3, and there is only a conf file for 4.2, copy that one. If you are deplying a version for 4.2.20190221, you should also copy the 4.2 node.conf file."
		echo "To avoid using a too new file, never copy a newer node.conf file as base, because it might contain new settings that your targeted Corda version does not know about."
		echo "Should you run into any issues while starting up the Corda node with this node.conf file, just check the node workspace logs folder, there you will find the exact details of what the node.conf should look like in the case of errors."
		echo ""
		echo "Please repeat the same copy and naming steps for the bridge.conf and float.conf that exists next to the node.conf file!"
		exit 1
	fi

	echo "Compiling Helm Initial Registration templates:"
	helm template $DIR -f $DIR/../values.yaml --output-dir $OUTPUT_DIR --set-file node_conf=$NODE_CONF
	mv $OUTPUT_DIR/corda/templates/initial_registration.sh.yml $SCRIPT
	mv $OUTPUT_DIR/corda/templates/node.conf.yml $OUTPUT_NODE_CONF

	# Helm always adds a few extra lines, which we want to remove from shell scripts
	tail -n +3 "$SCRIPT" > "$SCRIPT.tmp" && mv "$SCRIPT.tmp" "$SCRIPT"
	# And from compiled node.conf
	tail -n +3 "$OUTPUT_NODE_CONF" > "$OUTPUT_NODE_CONF.tmp" && mv "$OUTPUT_NODE_CONF.tmp" "$OUTPUT_NODE_CONF"

	# Make the script executable
	chmod +x $SCRIPT

	# Call script:
	echo "Executing Initial Registration step:"
	$SCRIPT

	echo "====== Corda node Initial Registration completed. ====== "
}
InitialRegistration
