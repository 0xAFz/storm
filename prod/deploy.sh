#!/bin/bash

set -euo pipefail

cd $(dirname "$0") || exit 1

source ./.env

activate_venv() {
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -r requirements.txt
    else
        source .venv/bin/activate
    fi
}

check_ping() {
    until ansible all -i ansible/inventory/hosts.yml -m ping --timeout 1; do
        echo "Waiting for VM's to become reachable..."
        sleep 1
    done
}

setup_cluster() {
    ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/cluster.yml
}

up() {
    terraform/tf.sh apply compute || { echo "Terraform failed to create vm's on OpenStack. Exiting..."; exit 1; }

    python3 ansible/inventory/dynamic.py || { echo "dynamic.py failed to generate hosts.yml file. Exiting..."; exit 1; }

    python3 dns.py || { echo "dns.py failed to create DNS records. Exiting..."; exit 1; }

	check_ping

    setup_cluster || { echo "Ansible failed to setup Kubernetes cluster. Exiting..."; exit 1; }

    terraform/tf.sh apply kafka || { echo "Terraform failed to deploy kafka on kubernetes. Exiting..."; exit 1; }
    terraform/tf.sh apply storm || { echo "Terraform failed to deploy storm on kubernetes. Exiting..."; exit 1; }
}

down() {
    terraform/tf.sh destroy compute || {
        echo "Failed to destroy the cluster. Check terraform logs."
        exit 1
    }
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <action>. Use 'up' or 'down'"
    exit 1
fi

case "$1" in
    up)
        activate_venv
        up
        ;;
    down)
        down
        ;;
    *)
        echo "Action not found. Use 'up' or 'down'."
        exit 1
        ;;
esac
