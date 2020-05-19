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

EnsureDockerIsAvailableAndReachable () {
	# Make sure Docker is ready
	set +e
	docker ps &>/dev/null
	status=$?
	if [ $status -eq 0 ]
	then
		echo "Docker is ready..."
	else
		if [[ `docker ps 2>&1 | grep "permission denied"` ]]; then 
			echo "Docker requires sudo to execute, trying to substitute using alias docker='sudo docker'"
			alias docker='sudo docker'
			if [[ `docker ps 2>&1 | grep "permission denied"` ]]; then 
				echo "Still issues with permissions, try a manual workaround where you set 'alias docker='sudo docker'' then run 'docker ps' to check that there is no 'permission denied' errors."
				exit 1
			else
				echo "Docker now accessible by way of alias, continuing..."
			fi
		else
			echo "!!! Docker engine not available, make sure your Docker is running and responds to command 'docker ps' !!!"
			exit 1
		fi
	fi
	set -e
}
EnsureDockerIsAvailableAndReachable

NO_CACHE=
if [ "${1-}" = "no-cache" ]
then
	NO_CACHE=--no-cache
fi 

. $DIR/download_binaries.sh

if [ ! -f "$DIR/bin/$CORDA_VERSION.jar" -o  ! -f "$DIR/bin/$CORDA_HEALTH_CHECK_VERSION.jar" -o  ! -f "$DIR/bin/$CORDA_FIREWALL_VERSION.jar" ]; then
	echo "Missing binaries, check that you have the correct files with the correct names in the following folder $DIR/bin"
	echo "$DIR/bin/$CORDA_VERSION.jar"
	echo "$DIR/bin/$CORDA_FIREWALL_VERSION.jar"
	echo "$DIR/bin/$CORDA_HEALTH_CHECK_VERSION.jar"
	exit 1
fi

cp $DIR/bin/$CORDA_VERSION.jar $DIR/$CORDA_IMAGE_PATH/corda.jar
cp $DIR/bin/$CORDA_HEALTH_CHECK_VERSION.jar $DIR/$CORDA_IMAGE_PATH/corda-tools-health-survey.jar
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
