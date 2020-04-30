#!/bin/sh

set -u
set +x

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

. $DIR/docker_config.sh

set +x

echoMessage () {
	local message=$1

	echo "====== $message ======"
}

checkStatus () {
	local status=$1
	if [ $status -eq 0 ]
		then
			echoMessage "Success"
		else
			echoMessage "The previous step failed"
			exit 1
	fi	
	return 0
}

downloadBinaries () {
	echoMessage "Downloading necessary binaries..."
	cd ./bin

	if [ ! -f "$CORDA_VERSION.jar" ]; then
		wget -nc --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} -O $CORDA_VERSION "https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda/${VERSION}/corda-${VERSION}.jar"
		checkStatus $?
	else
		echo "$CORDA_VERSION.jar already downloaded."
	fi

	if [ ! -f "$CORDA_FIREWALL_VERSION.jar" ]; then
		wget -nc --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} -O $CORDA_FIREWALL_VERSION "https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda/${VERSION}/corda-${VERSION}.jar"
		checkStatus $?
	else
		echo "$CORDA_FIREWALL_VERSION.jar already downloaded."
	fi

	if [ ! -f "corda-finance-workflows-${VERSION}.jar" ]; then
		wget -nc --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} "https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda-finance-workflows/${VERSION}/corda-finance-workflows-${VERSION}.jar"
		checkStatus $?
	else
		echo "corda-finance-workflows-${VERSION}.jar already downloaded."
	fi

	if [ ! -f "corda-finance-contracts-${VERSION}.jar" ]; then
		wget -nc --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} "https://ci-artifactory.corda.r3cev.com/artifactory/corda-releases/net/corda/corda-finance-contracts/${VERSION}/corda-finance-contracts-${VERSION}.jar"
		checkStatus $?
	else
		echo "corda-finance-contracts-${VERSION}.jar already downloaded."
	fi
	
	if [ ! -f apache-artemis-2.6.4-bin.tar.gz ]
		then
			echoMessage "Downloading apache-artemis-2.6.4-bin.tar.gz..."
			curl -sSL https://www.apache.org/dist/activemq/activemq-artemis/2.6.4/apache-artemis-2.6.4-bin.tar.gz -o apache-artemis-2.6.4-bin.tar.gz
			#tar xzf apache-artemis-2.6.4-bin.tar.gz
		else
			echo "apache-artemis-2.6.4-bin.tar.gz already downloaded."
	fi
	
	if [ ! -f zookeeper-3.5.4-beta.tar.gz ]
		then
			echoMessage "Downloading zookeeper-3.5.4-beta.tar.gz..."
			curl -sSL https://apache.org/dist/zookeeper/zookeeper-3.5.4-beta/zookeeper-3.5.4-beta.tar.gz -o zookeeper-3.5.4-beta.tar.gz
			#tar xvf zookeeper-3.5.4-beta.tar.gz
		else
			echo "zookeeper-3.5.4-beta.tar.gz already downloaded."
	fi
	
	if [ ! -f mssql-jdbc-7.2.0.jre8.jar ]
		then
			echoMessage "Downloading mssql-jdbc-7.2.0.jre8.jar..."
			curl -sSL https://github.com/Microsoft/mssql-jdbc/releases/download/v7.2.0/mssql-jdbc-7.2.0.jre8.jar -o mssql-jdbc-7.2.0.jre8.jar
		else
			echo "mssql-jdbc-7.2.0.jre8.jar already downloaded."
	fi
	
	cd ..
	echoMessage "Binaries downloaded."
	return 0
}

askForArtifactoryLoginInformation () {
	if [ "$ARTIFACTORY_USER" == "" ]; then
		echo "There is no value defined for artifactory_username in values.yaml, you can either interrupt this script with CTRL+C or enter your R3 Artifactory username next."
		read -p "Enter your R3 Artifactory username to continue: " ARTIFACTORY_USER
	fi
	
	if [ "$ARTIFACTORY_PASSWORD" == "" ]; then
		echo "There is no value defined for artifactory_password in values.yaml, you can either interrupt this script with CTRL+C or enter your R3 Artifactory password next."
		read -p "Enter your R3 Artifactory password to continue: " ARTIFACTORY_PASSWORD
	fi
	
	if [ "$ARTIFACTORY_USER" == "" -o "$ARTIFACTORY_PASSWORD" == "" ]; then
		echo "R3 Artifactory username or password missing!"
		exit 1
	fi
}

main () {
	ARTIFACTORY_CONFIG_RAW=$(grep -A 5 'artifactoryR3:' $DIR/../helm/values.yaml)
	ARTIFACTORY_USER=$(echo "$ARTIFACTORY_CONFIG_RAW" | grep 'artifactory_username: "' | cut -d '"' -f 2)
	ARTIFACTORY_PASSWORD=$(echo "$ARTIFACTORY_CONFIG_RAW" | grep 'artifactory_password: "' | cut -d '"' -f 2)
	ARTEMIS_OOP_ENABLED=$(grep -A 3 'artemis:' $DIR/../helm/values.yaml | grep 'enabled: "' | cut -d ':' -f 2)
	askForArtifactoryLoginInformation
	downloadBinaries
	return 0
}

main
