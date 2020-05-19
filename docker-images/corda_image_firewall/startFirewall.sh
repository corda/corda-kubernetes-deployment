#!/usr/bin/env bash

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
}

ifSharedFolderAndFilesExists () {
    if [ -d /opt/corda/shared/ -a -f /opt/corda/shared/network-parameters -a -f /opt/corda/shared/certificates/sslkeystore.jks -a -f /opt/corda/shared/certificates/truststore.jks ]
    then
        return 1
    else
        return 0
    fi
}

copySharedFiles () {
	let EXIT_CODE=0
	while [ ${EXIT_CODE} -eq 0 ]
	do
		sleep 2
		echoMessage "Checking shared folder for required files..."
		ifSharedFolderAndFilesExists
		let EXIT_CODE=$?
	done
	echoMessage "Shared folder & files exists." 
	
	echoMessage "Copying network-parameters & certificates from shared folder (from node)."
	cp /opt/corda/shared/network-parameters ./workspace/
	mkdir ./workspace/certificates/
	cp /opt/corda/shared/certificates/sslkeystore.jks ./workspace/certificates/
	cp /opt/corda/shared/certificates/truststore.jks ./workspace/certificates/
	echoMessage "Copied network-parameters & certificates from shared folder (from node), ready to start Corda Firewall."
	return 1
}

waitForOtherCordaFirewallProcessToExit () {
	let PROCESS_ID_ACCESSIBLE=0
	while [ ${PROCESS_ID_ACCESSIBLE} -eq 0 ]
	do
		sleep 2
		echoMessage "Checking access for firewall-process-id file..."
		PROCESS_ID_FILE=./workspace/firewall-process-id
		if [ -f $PROCESS_ID_FILE ]
		then
			echoMessage "File firewall-process-id exists, checking lock status..."
			#flock -n /tmp/test.lock -c $PROCESS_ID_FILE
			( flock -n 200 || exit 1
				echo "In critical section"
				echo "Random write" >> $PROCESS_ID_FILE
			) 200>$PROCESS_ID_FILE
			if [ $? -ne 1 ]; then
				echoMessage "File firewall-process-id is not locked by another process, we can start Corda Firewall!"
				let PROCESS_ID_ACCESSIBLE=1
			fi
		else
			let PROCESS_ID_ACCESSIBLE=1
		fi
	done
}

startFirewall () {
	if [ ! -f ./workspace/network-parameters -a -f ./workspace/certificates/sslkeystore.jks -a -f ./workspace/certificates/truststore.jks ]
	then
		copySharedFiles
	fi
	
	echoMessage "Checking if other Corda Firewall process is running..."
	waitForOtherCordaFirewallProcessToExit
	echoMessage "Starting the firewall"
	java -jar corda-firewall.jar --base-directory ./workspace --verbose --logging-level=INFO
	local status=$?
	if [ $status -ne 0 ]
	then
		echo "DEBUG INFO on CRITICAL ERROR:"
		ls /opt/corda -R -al
		echo "Active firewall.conf file:"
		less /opt/corda/workspace/firewall.conf
		MACHINE_NAME=$(cat /proc/sys/kernel/hostname)
		LOG_FILE="/opt/corda/workspace/logs/corda-firewall-${MACHINE_NAME}.log"
		echo "Content of log file (${LOG_FILE}):"
		tail -n 500 $LOG_FILE
	fi
	checkStatus $status
}

startFirewall
