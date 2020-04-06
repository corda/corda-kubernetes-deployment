#!/bin/sh

set -ux
DIR="."
function GetPathToCurrentlyExecutingScript () {
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

OUTPUT_DIR=$DIR/output
SCRIPT=$OUTPUT_DIR/corda/templates/initial_registration.sh
NODE_CONF=$OUTPUT_DIR/corda/templates/node.conf

helm template $DIR -f $DIR/../values.yaml --output-dir $OUTPUT_DIR --set-file node_conf=$DIR/../files/node.conf
mv $OUTPUT_DIR/corda/templates/initial_registration.sh.yml $SCRIPT
mv $OUTPUT_DIR/corda/templates/node.conf.yml $NODE_CONF

# Helm always adds a few extra lines, which we want to remove from shell scripts
tail -n +3 "$SCRIPT" > "$SCRIPT.tmp" && mv "$SCRIPT.tmp" "$SCRIPT"
# And from compiled node.conf
tail -n +3 "$NODE_CONF" > "$NODE_CONF.tmp" && mv "$NODE_CONF.tmp" "$NODE_CONF"

# Make the script executable
chmod +x $SCRIPT

# Call script:
$SCRIPT
