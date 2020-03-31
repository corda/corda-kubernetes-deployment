#!/bin/sh

set -eux
ABS_PATH=$(readlink -f "$0")
DIR=$(dirname "$ABS_PATH")

TEMPLATE="cordatest"

helm template $DIR --name $TEMPLATE --namespace $TEMPLATE --output-dir $DIR/output
mv $DIR/output/corda/templates/pre-install.sh.yml $DIR/output/corda/templates/pre-install.sh

### docker secret ###
mv $DIR/output/corda/templates/create-docker-secret.sh.yml $DIR/output/corda/templates/create-docker-secret.sh
chmod +x $DIR/output/corda/templates/create-docker-secret.sh
$DIR/output/corda/templates/create-docker-secret.sh
###---------------###

kubectl apply -f $DIR/output/corda/templates/ --namespace=$TEMPLATE

chmod +x $DIR/output/corda/templates/pre-install.sh
# Copy CorDapps etc.
#$DIR/output/corda/templates/pre-install.sh
