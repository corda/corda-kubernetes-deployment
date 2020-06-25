#!/usr/bin/env bash

RED='\033[0;31m' # Error color
YELLOW='\033[0;33m' # Warning color
NC='\033[0m' # No Color

echoMessage () {
	message=$1
	echo "====== $message ======"
}

checkStatus () {
	status=$1
	if [ $status -eq 0 ]; then
		echoMessage "Success"
	else
		echo -e "${RED}ERROR${NC}"
		echoMessage "The previous step failed"
		exit 1
	fi	
	return 0
}

isRegistered () {
	IS_REGISTERED=0
	if grep -q "compatibilityZoneURL" ./workspace/node.conf ; then 
		NODE_KEY_STORE="./workspace/certificates/nodekeystore.jks";
		if [ -f "$NODE_KEY_STORE" ]; then
			IS_REGISTERED=1
		fi
	else
		NODE_INFOS=(./workspace/nodeInfo-*)
		# Check if NODE_INFOS is an glob array of size larger than zero and then check first array element if valid file
		if [ ${#NODE_INFOS[@]} -gt 0 -a -f "${NODE_INFOS[0]}" ]; then
			IS_REGISTERED=1
		fi
	fi

	return $IS_REGISTERED
}

waitForOtherCordaNodeProcessToExit () {
	let PROCESS_ID_ACCESSIBLE=0
	while [ ${PROCESS_ID_ACCESSIBLE} -eq 0 ]
	do
		sleep 2
		echoMessage "Checking access for process-id file..."
		PROCESS_ID_FILE=./workspace/process-id
		if [ -f $PROCESS_ID_FILE ]; then
			echoMessage "File process-id exists, checking lock status..."
			#flock -n /tmp/test.lock -c $PROCESS_ID_FILE
			( flock -n 200 || exit 1
				echo "In critical section"
				echo "Random write" >> $PROCESS_ID_FILE
			) 200>$PROCESS_ID_FILE
			if [ $? -ne 1 ]; then
				echoMessage "File process-id is not locked by another process, we can start Corda Node!"
				let PROCESS_ID_ACCESSIBLE=1
			fi
		else
			let PROCESS_ID_ACCESSIBLE=1
		fi
	done
}

checkIfNetworkParametersIsAvailable () {
	let NETWORK_PARAMETERS_EXISTS=0
	while [ ${NETWORK_PARAMETERS_EXISTS} -eq 0 ]
	do
		sleep 2
		echoMessage "Checking for network-parameters file..."
		if [ -f ./workspace/network-parameters ]
		then
			echoMessage "Found network-parameters file!"
			let NETWORK_PARAMETERS_EXISTS=1
		fi
	done
}

checkIfIdentityManagerIsUpAndRunning () {
	echoMessage "Trying to contact Identity Manager @ ($IDENTITY_MANAGER_ADDRESS)..."
	curl -m5 -s $IDENTITY_MANAGER_ADDRESS/status > /dev/null
	result=$?
	
	if [ $result -eq 0]; then
		echoMessage "Identity Manager is up and running"
	else
		echo -e "${YELLOW}Warning${NC}"
		echoMessage "Identity Manager is unavailable"
	fi
}

checkIfNetworkMapIsUpAndRunning () {
	echoMessage "Trying to contact network map @ ($NETMAP_ADDRESS)..."
	curl -m5 -s $NETMAP_ADDRESS/network-map/my-hostname > /dev/null
	let EXIT_CODE=$?
	result=$?
	
	if [ $result -eq 0]; then
		echoMessage "Network map is up and running"
	else
		echo -e "${YELLOW}Warning${NC}"
		echoMessage "Network map is unavailable"
	fi
}

checkNetworkMap () {
	hash="" 
	while [ -z "${hash}" -o "${hash}" = "null" ]
	do
		sleep 2
		echoMessage "Checking network map for notary NodeInfo..."
		hash=$(curl -m5 -s $NETMAP_ADDRESS/network-map-user/network-map | jq -r '.[0]')
		if [ "$hash" = "null" ]
		then
			echoMessage "The network map is currently empty, waiting for first registrations..."
		fi
	done
	echoMessage "We found a hash from network map: $hash"
	# curl -m5 -s "http://enm-netmap-service:20000/network-map/network-parameters/$hash"
	# echoMessage ""
	# curl -m5 -s "http://enm-netmap-service:20000/network-map/network-parameters/$hash" > /opt/corda/workspace/network-params
	# let EXIT_CODE=$?
	# if [ ${EXIT_CODE} -gt 0 ]
	# then
		# echoMessage "Error downloading network-parameters, exiting..."
		# echoMessage "$EXIT_CODE"
		# exit 1
	# else
		# echoMessage "Downloaded network-parameters successfully"
		# ls /opt/corda/workspace/network-params
		# cat /opt/corda/workspace/network-params
		# return 0
	# fi
}

startNode () {
	java -jar corda.jar --base-directory ./workspace
	checkStatus $?
}

launchCordaNode () {
	echoMessage "Checking if other Corda Node process is running..."
	waitForOtherCordaNodeProcessToExit

	echoMessage "Checking Identity Manager's availability"
	checkIfIdentityManagerIsUpAndRunning

	echoMessage "Checking network map's availability"
	checkIfNetworkMapIsUpAndRunning

	echoMessage "Starting the node"
	startNode
}
launchCordaNode