#!/bin/bash

set -eux

ABS_PATH=$(readlink -f "$0")
DIR=$(dirname "$ABS_PATH")

checkStatus () {
	local status=$1
	if [ $status -eq 0 ]
		then
			echo "."
		else
			echo "The previous step failed"
			exit 1
	fi	
	return 0
}

ensureFileExistsAndCopy () {
    FROM=$1
    TO=$2
    if [ -f "$FROM" ]
    then
        if [ ! -f "$TO" ]
        then
            cp -f $FROM $TO
        else
			echo "Existing certificate already existed, skipping copying as a safe-guard: $TO"
            exit 1
        fi
    else
		echo "File did not exist, probably an issue with certificate creation: $FROM"
        exit 1
    fi
}

ensureFileExistsAndCopy $DIR/pki-firewall/certs/trust.jks $DIR/../helm/files/certificates/firewall_tunnel/trust.jks
ensureFileExistsAndCopy $DIR/pki-firewall/certs/float.jks $DIR/../helm/files/certificates/firewall_tunnel/float.jks
ensureFileExistsAndCopy $DIR/pki-firewall/certs/bridge.jks $DIR/../helm/files/certificates/firewall_tunnel/bridge.jks

