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
		ITERATIONS=0

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

helm version | grep "v2." > /dev/null 2>&1
if [ "$?" -ne "0" ] ; then
	echo "Helm version 2 has to be used for compiling these scripts. Please install it from https://github.com/helm/helm/releases"
	exit 1
fi

kubectl cluster-info > /dev/null 2>&1
if [ "$?" -ne "0" ] ; then
	echo "kubectl must be connected to the Kubernetes cluster in order to continue. Please see https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/"
	exit 1
fi

set -eu

TEMPLATE_NAMESPACE=""
TEMPLATE_NAMESPACE=$(grep -A 3 'config:' $DIR/values.yaml | grep 'namespace: "' | cut -d '"' -f 2)

if [ "$TEMPLATE_NAMESPACE" = "" ]; then
	echo "Kubernetes requires a namespace to deploy resources to, no namespace is defined in values.yaml, please define one."
	exit 1
fi

helm template $DIR --name $TEMPLATE_NAMESPACE --namespace $TEMPLATE_NAMESPACE --output-dir $DIR/output

# pre-install script
SCRIPT="$DIR/output/corda/templates/pre-install.sh"
mv $SCRIPT.yml $SCRIPT
# Helm always adds a few extra lines, which we want to remove from shell scripts
tail -n +3 "$SCRIPT" > "$SCRIPT.tmp" && mv "$SCRIPT.tmp" "$SCRIPT"
chmod +x $SCRIPT

# docker secret script
SCRIPT="$DIR/output/corda/templates/create-docker-secret.sh"
mv $SCRIPT.yml $SCRIPT
# Helm always adds a few extra lines, which we want to remove from shell scripts
tail -n +3 "$SCRIPT" > "$SCRIPT.tmp" && mv "$SCRIPT.tmp" "$SCRIPT"
chmod +x $SCRIPT
$SCRIPT

kubectl apply -f $DIR/output/corda/templates/ --namespace=$TEMPLATE_NAMESPACE

# Copy CorDapps etc.
#$DIR/output/corda/templates/pre-install.sh
