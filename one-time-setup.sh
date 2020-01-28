#!/bin/sh

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

source $DIR/docker-images/build_docker_images.sh
checkStatus $?
source $DIR/docker-images/push_docker_images.sh
checkStatus $?
source $DIR/corda-pki-generator/pki-firewall/generate_pki.sh
checkStatus $?
source $DIR/helm/initial_registration/initial_registration.sh
checkStatus $?
