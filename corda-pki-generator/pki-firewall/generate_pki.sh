#!/bin/bash

set -ux
DIR="."
GetPathToCurrentlyExecutingScript () {
	# Absolute path of this script, e.g. /opt/corda/node/foo.sh
	ABS_PATH=$(readlink -f "$0")
	if [ "$?" -ne "0" ]; then
		echo "readlink issue workaround..."
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

WORKDIR=$DIR/certs
mkdir $WORKDIR -p
rm $WORKDIR/* -rf

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

$KEYTOOL_EXE &>/dev/null
status=$?
if [ $status -eq 0 ]
then
	echo "Keytool is ready..."
else
	echo "!!! Keytool is not available, make sure your Keytool is configured correctly !!!"
	exit 1
fi

set +x

# Read values.yaml for configuration
VALUES_YAML=$DIR/../../helm/values.yaml
FIREWALL_CONF_RAW=$(grep -A 14 ' firewall:' $VALUES_YAML) # Find configuration path .Values.corda.firewall.conf
echo "Reading values.yaml file ($VALUES_YAML), contents: $FIREWALL_CONF_RAW"
CERTIFICATE_VALIDITY_DAYS=$(echo "$FIREWALL_CONF_RAW" | grep 'certificateValidityInDays: "' | cut -d '"' -f 2)
TRUST_PASSWORD=$(echo "$FIREWALL_CONF_RAW" | grep 'truststorePassword: "' | cut -d '"' -f 2)
BRIDGE_PASSWORD=$(echo "$FIREWALL_CONF_RAW" | grep 'bridgeKeystorePassword: "' | cut -d '"' -f 2)
FLOAT_PASSWORD=$(echo "$FIREWALL_CONF_RAW" | grep 'floatKeystorePassword: "' | cut -d '"' -f 2)
CA_KEYSTORE_PASSWORD=$(echo "$FIREWALL_CONF_RAW" | grep 'keystorePasswordCA: "' | cut -d '"' -f 2)
CA_KEY_PASSWORD=$(echo "$FIREWALL_CONF_RAW" | grep 'keyPasswordCA: "' | cut -d '"' -f 2)

set -eux

if [ "$CERTIFICATE_VALIDITY_DAYS" = "" -o "$TRUST_PASSWORD" = "" -o "$BRIDGE_PASSWORD" = "" -o "$FLOAT_PASSWORD" = "" -o "$CA_KEYSTORE_PASSWORD" = "" -o "$CA_KEY_PASSWORD" = "" ]; then
	echo "Some values were not set correctly from values.yaml file, please check the following values in the values.yaml file:"
	echo "CERTIFICATE_VALIDITY_DAYS=$CERTIFICATE_VALIDITY_DAYS"
	echo "TRUST_PASSWORD=$TRUST_PASSWORD"
	echo "BRIDGE_PASSWORD=$BRIDGE_PASSWORD"
	echo "FLOAT_PASSWORD=$FLOAT_PASSWORD"
	echo "CA_KEYSTORE_PASSWORD=$CA_KEYSTORE_PASSWORD"
	echo "CA_KEY_PASSWORD=$CA_KEY_PASSWORD"
fi

$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Firewall Root,O=Local Only,L=London,C=GB" -ext bc:ca:true,pathlen:1 -keystore $WORKDIR/firewallca.jks -storepass $CA_KEYSTORE_PASSWORD -keypass $CA_KEY_PASSWORD
$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias bridgecert -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Bridge Local,O=Local Only,L=London,C=GB" -ext bc:ca:false -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD
$KEYTOOL_EXE -genkeypair -keyalg EC -keysize 256 -alias floatcert -validity $CERTIFICATE_VALIDITY_DAYS -dname "CN=Float Local,O=Local Only,L=London,C=GB" -ext bc:ca:false -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD

$KEYTOOL_EXE -exportcert -rfc -alias firewallroot -keystore $WORKDIR/firewallca.jks -storepass $CA_KEYSTORE_PASSWORD -keypass $CA_KEY_PASSWORD > $WORKDIR/root.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/root.pem -alias root -keystore $WORKDIR/trust.jks -storepass $TRUST_PASSWORD

$KEYTOOL_EXE -certreq -alias bridgecert -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD | $KEYTOOL_EXE -gencert -ext ku:c=dig,keyEncipherment -ext: eku:true=serverAuth,clientAuth -rfc -keystore $WORKDIR/firewallca.jks -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -storepass $CA_KEYSTORE_PASSWORD -keypass $CA_KEY_PASSWORD > $WORKDIR/bridge.pem
cat $WORKDIR/root.pem $WORKDIR/bridge.pem >> $WORKDIR/bridgechain.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/bridgechain.pem -alias bridgecert -keystore $WORKDIR/bridge.jks -storepass $BRIDGE_PASSWORD -keypass $BRIDGE_PASSWORD

$KEYTOOL_EXE -certreq -alias floatcert -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD | $KEYTOOL_EXE -gencert -ext ku:c=dig,keyEncipherment -ext: eku::true=serverAuth,clientAuth -rfc -keystore $WORKDIR/firewallca.jks -alias firewallroot -validity $CERTIFICATE_VALIDITY_DAYS -storepass $CA_KEYSTORE_PASSWORD -keypass $CA_KEY_PASSWORD > $WORKDIR/float.pem
cat $WORKDIR/root.pem $WORKDIR/float.pem >> $WORKDIR/floatchain.pem
$KEYTOOL_EXE -importcert -noprompt -file $WORKDIR/floatchain.pem -alias floatcert -keystore $WORKDIR/float.jks -storepass $FLOAT_PASSWORD -keypass $FLOAT_PASSWORD
