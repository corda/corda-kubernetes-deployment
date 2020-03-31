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

WORKDIR=$DIR/certs
mkdir $WORKDIR -p
rm $WORKDIR/* -rf

set -ux
# C:\Program Files\Java\jre1.8.0_201\bin or if in PATH just keytool.exe
KEYTOOL_EXE=keytool
$KEYTOOL_EXE &>/dev/null
if [ "$?" -ne "0" ]; then
    KEYTOOL_EXE=$DIR/bin/keytool.exe
    $KEYTOOL_EXE &>/dev/null
    if [ "$?" -ne "0" ]; then
        KEYTOOL_EXE=/usr/bin/keytool
        $KEYTOOL_EXE &>/dev/null
        if [ "$?" -ne "0" ]; then
            echo "!!! Keytool not found, please check to make sure you have it installed and in the path or in path $DIR/bin/ !!!"
	    exit 1
        fi
    fi
fi
set -eux

$KEYTOOL_EXE &>/dev/null
status=$?
if [ $status -eq 0 ]
then
	echo "Keytool is ready..."
else
	echo "!!! Keytool is not available, make sure your Keytool is configured correctly !!!"
	exit 1
fi


CERTIFICATE_VALIDITY_DAYS=3650
BRIDGE_PASSWORD=bridgepass
FLOAT_PASSWORD=floatpass
TRUST_PASSWORD=trustpass
CA_PASSWORD=capass

$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Firewall Root,O=Local Only,L=London,C=GB" -ext bc:ca:true,pathlen:1 -keystore $WORKDIR/firewallca.jks -storepass $CA_PASSWORD -keypass cakeypass
$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias bridgecert -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Bridge Local,O=Local Only,L=London,C=GB" -ext bc:ca:false -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD
$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias floatcert -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Float Local,O=Local Only,L=London,C=GB" -ext bc:ca:false -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD

$KEYTOOL_EXE -exportcert -rfc -alias firewallroot -keystore $WORKDIR/firewallca.jks -storepass $CA_PASSWORD -keypass cakeypass > $WORKDIR/root.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/root.pem -alias root -keystore $WORKDIR/trust.jks -storepass $TRUST_PASSWORD

$KEYTOOL_EXE -certreq -alias bridgecert -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD | $KEYTOOL_EXE -gencert -ext ku:c=dig,keyEncipherment -ext: eku:true=serverAuth,clientAuth -rfc -keystore $WORKDIR/firewallca.jks -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -storepass $CA_PASSWORD -keypass cakeypass > $WORKDIR/bridge.pem
cat $WORKDIR/root.pem $WORKDIR/bridge.pem >> $WORKDIR/bridgechain.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/bridgechain.pem -alias bridgecert -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD

$KEYTOOL_EXE -certreq -alias floatcert -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD | $KEYTOOL_EXE -gencert -ext ku:c=dig,keyEncipherment -ext: eku::true=serverAuth,clientAuth -rfc -keystore $WORKDIR/firewallca.jks -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -storepass $CA_PASSWORD -keypass cakeypass > $WORKDIR/float.pem
cat $WORKDIR/root.pem $WORKDIR/float.pem >> $WORKDIR/floatchain.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/floatchain.pem -alias floatcert -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD
