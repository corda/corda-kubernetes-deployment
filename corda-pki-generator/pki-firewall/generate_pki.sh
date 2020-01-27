#!/bin/sh

set -eux

ABS_PATH=$(readlink -f "$0")
DIR=$(dirname "$ABS_PATH")
WORKDIR=$DIR/certs
mkdir $WORKDIR -p
rm $WORKDIR/* -rf

# C:\Program Files\Java\jre1.8.0_201\bin or if in PATH just keytool.exe
KEYTOOL_EXE=$DIR/bin/keytool.exe

# Make sure KEYTOOL is ready
if [ ! -f "$KEYTOOL_EXE" ]
then
	echo "!!! Keytool not found, make sure your Keytool is configured correctly !!!"
	exit 1
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
