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
