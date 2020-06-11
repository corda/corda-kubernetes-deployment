#!/bin/bash

set -u
set +x

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

. $DIR/docker_config.sh

set +x

echoMessage () {
	message=$1

	echo "====== $message ======"
}

checkStatus () {
	status=$1
	if [ $status -eq 0 ]
		then
			echoMessage "Success"
		else
			echoMessage "The previous step failed"
			exit 1
	fi	
	return 0
}

wgetDownload () {
	OUTPUT_FILE=$1
	URL=$2
	echo "Downloading $OUTPUT_FILE from $URL:"
	set +e
	wget --help > /dev/null 2>&1
	status=$?
	set -e
	if [ $status -ne 0 ]; then 
		echo "wget missing, cannot continue (please install wget: https://stackoverflow.com/questions/33886917/how-to-install-wget-in-macos)!"
		exit 1
	else
		wget --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} -S --spider $URL 2>&1 | grep 'HTTP/1.1 200 OK'
		status=$?
		if [ $status -eq 0 ]; then 
			echo "URL check passed, target exists!"
		else 
			echo "URL check failed, file not found! Check your version definition in values.yaml file!"
			exit 1
		fi

		set +e
		echo "test for sed -u availability..." | sed -u -e "s,\.,,g" > /dev/null 2>&1
		status=$?
		set -e
		
		SED_U_OPTION="-u"
		if [ $status -ne 0 ]; then 
			SED_U_OPTION=""
		fi

		echo "Now downloading (please be patient) ..."
		echo -n "    "
		wget -nc --user ${ARTIFACTORY_USER} --password ${ARTIFACTORY_PASSWORD} --progress=dot $URL -O $OUTPUT_FILE 2>&1 | grep --line-buffered "%" | sed $SED_U_OPTION -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
		echo -ne "\b\b\b\b"
		echo " DONE"
	fi
}

downloadBinaries () {
	echoMessage "Downloading necessary binaries for Corda Enterprise version $CORDA_VERSION ..."
	cd $DIR/bin
	
	CORDA_DOWNLOAD_URL="https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda/${VERSION}/corda-${VERSION}.jar"
	CORDA_FIREWALL_DOWNLOAD_URL="https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda-firewall/${VERSION}/corda-firewall-${VERSION}.jar"
	CORDA_HEALTH_CHECK_DOWNLOAD_URL="https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda-tools-health-survey/${VERSION}/corda-tools-health-survey-${VERSION}.jar"
	CORDA_FINANCE_WORKFLOWS_DOWNLOAD_URL="https://software.r3.com/artifactory/r3-corda-releases/com/r3/corda/corda-finance-workflows/${VERSION}/corda-finance-workflows-${VERSION}.jar"
	CORDA_FINANCE_CONTRACT_DOWNLOAD_URL="https://ci-artifactory.corda.r3cev.com/artifactory/corda-releases/net/corda/corda-finance-contracts/${VERSION}/corda-finance-contracts-${VERSION}.jar"

	echo "Checking that wget exists..."
	set +e
	wget --help > /dev/null 2>&1
	status=$?
	set -e
	if [ $status -ne 0 ]; then 
		echo "wget is not installed. You need to install it in order to download the binaries using this script. You may also download them manually."
		echo "Manual download instructions, please download the following links and save as the name suggests:"
		echo "docker-images/bin/$CORDA_VERSION.jar = $CORDA_DOWNLOAD_URL"
		echo "docker-images/bin/$CORDA_FIREWALL_VERSION.jar = $CORDA_FIREWALL_DOWNLOAD_URL"
		echo "docker-images/bin/$CORDA_HEALTH_CHECK_VERSION.jar = $CORDA_HEALTH_CHECK_DOWNLOAD_URL"
		echo "docker-images/bin/corda-finance-workflows-${VERSION}.jar = $CORDA_FINANCE_WORKFLOWS_DOWNLOAD_URL"
		echo "docker-images/bin/corda-finance-contracts-${VERSION}.jar = $CORDA_FINANCE_CONTRACT_DOWNLOAD_URL"
	fi
	
	if [ ! -f "$CORDA_VERSION.jar" ]; then
		wgetDownload $CORDA_VERSION.jar "$CORDA_DOWNLOAD_URL"
		checkStatus $?
	else
		echo "$CORDA_VERSION.jar already downloaded."
	fi

	if [ ! -f "$CORDA_FIREWALL_VERSION.jar" ]; then
		wgetDownload $CORDA_FIREWALL_VERSION.jar "$CORDA_FIREWALL_DOWNLOAD_URL"
		checkStatus $?
	else
		echo "$CORDA_FIREWALL_VERSION.jar already downloaded."
	fi

	if [ ! -f "$CORDA_HEALTH_CHECK_VERSION.jar" ]; then
		wgetDownload $CORDA_HEALTH_CHECK_VERSION.jar "$CORDA_HEALTH_CHECK_DOWNLOAD_URL"
		checkStatus $?
	else
		echo "$CORDA_HEALTH_CHECK_VERSION.jar already downloaded."
	fi

	if [ ! -f "corda-finance-workflows-${VERSION}.jar" ]; then
		wgetDownload corda-finance-workflows-${VERSION}.jar "$CORDA_FINANCE_WORKFLOWS_DOWNLOAD_URL"
		checkStatus $?
	else
		echo "corda-finance-workflows-${VERSION}.jar already downloaded."
	fi

	if [ ! -f "corda-finance-contracts-${VERSION}.jar" ]; then
		wgetDownload corda-finance-contracts-${VERSION}.jar "$CORDA_FINANCE_CONTRACT_DOWNLOAD_URL"
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
	if [ "$ARTIFACTORY_USER" = "" ]; then
		echo "There is no value defined for artifactory_username in values.yaml, you can either interrupt this script with CTRL+C or enter your R3 Artifactory username next."
		read -p "Enter your R3 Artifactory username to continue: " ARTIFACTORY_USER
	fi
	
	if [ "$ARTIFACTORY_PASSWORD" = "" ]; then
		echo "There is no value defined for artifactory_password in values.yaml, you can either interrupt this script with CTRL+C or enter your R3 Artifactory password next."
		read -p "Enter your R3 Artifactory password to continue: " ARTIFACTORY_PASSWORD
	fi
	
	if [ "$ARTIFACTORY_USER" = "" -o "$ARTIFACTORY_PASSWORD" = "" ]; then
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
