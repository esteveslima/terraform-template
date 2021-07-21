#! /bin/bash
# Generates dummy ssh keys for the example
# The infrastructure should be redeployed after generating a new keypair

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ssh-keygen -m PEM -C "bastion@example.com" -N "bastionpassphrase" -f $SCRIPT_DIR/bastion_id_rsa
ssh-keygen -m PEM -C "apps@example.com" -N "appspassphrase" -f $SCRIPT_DIR/apps_id_rsa
