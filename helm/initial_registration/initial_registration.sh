#!/bin/sh

set -eux
ABS_PATH=$(readlink -f "$0")
DIR=$(dirname "$ABS_PATH")
TEMPLATE="cordatest"
OUTPUT_DIR=$DIR/output
SCRIPT=$OUTPUT_DIR/corda/templates/initial_registration.sh
NODE_CONF=$OUTPUT_DIR/corda/templates/node.conf

helm template $DIR -f $DIR/../values.yaml --name $TEMPLATE --namespace $TEMPLATE --output-dir $OUTPUT_DIR --set-file node_conf=$DIR/../files/node.conf
mv $OUTPUT_DIR/corda/templates/initial_registration.sh.yml $SCRIPT
mv $OUTPUT_DIR/corda/templates/node.conf.yml $NODE_CONF
chmod +x $SCRIPT

# Helm always adds a few extra lines, which we want to remove from shell scripts
tail -n +2 "$SCRIPT" > "$SCRIPT.tmp" && mv "$SCRIPT.tmp" "$SCRIPT"
# And from compiled node.conf
tail -n +3 "$NODE_CONF" > "$NODE_CONF.tmp" && mv "$NODE_CONF.tmp" "$NODE_CONF"

# Call script:
$SCRIPT
