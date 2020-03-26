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

helm version | grep "v2."
if [ "$?" -ne "0" ] ; then
	echo "Helm version 2 has to be used for compiling these scripts. Please install it from https://github.com/helm/helm/releases"
	exit 1
fi

kubectl cluster-info
if [ "$?" -ne "0" ] ; then
	echo "kubectl must be connected to the Kubernetes cluster in order to continue. Please see https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/"
	exit 1
fi

TEMPLATE_NAMESPACE="cordatest"

helm template $DIR --name $TEMPLATE_NAMESPACE --namespace $TEMPLATE_NAMESPACE --output-dir $DIR/output
mv $DIR/output/corda/templates/pre-install.sh.yml $DIR/output/corda/templates/pre-install.sh
kubectl apply -f $DIR/output/corda/templates/ --namespace=$TEMPLATE_NAMESPACE

chmod +x $DIR/output/corda/templates/pre-install.sh
# Copy CorDapps etc.
#$DIR/output/corda/templates/pre-install.sh
