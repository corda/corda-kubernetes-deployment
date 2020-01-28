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

source $DIR/helm/helm_compile.sh
checkStatus $?
