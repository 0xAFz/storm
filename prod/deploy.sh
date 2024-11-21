#!/bin/bash

set -euo pipefail

cd $(dirname "$0") || exit 1

source ./.env
source ./terraform/services/storm/.env

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

deploy_resource() {
    local service_dir="terraform/$1"

    if [ ! -d "$service_dir" ]; then
        echo "Directory $service_dir does not exist!" >&2
        exit 1
    fi

    terraform -chdir="$service_dir" init
    terraform -chdir="$service_dir" plan
    terraform -chdir="$service_dir" apply -auto-approve
}

cluster_up() {
    deploy_resource cluster || { echo "Terraform failed to create vm's on OpenStack. Exiting..."; exit 1; }

    python3 ansible/inventory/dynamic.py || { echo "dynamic.py failed to generate hosts.yml file. Exiting..."; exit 1; }

    python3 dns.py || { echo "dns.py failed to create DNS records. Exiting..."; exit 1; }

    setup_cluster || { echo "Ansible failed to setup Kubernetes cluster. Exiting..."; exit 1; }

    deploy_resource services/kafka || { echo "Terraform failed to deploy kafka on kubernetes. Exiting..."; exit 1; }
    deploy_resource services/storm || { echo "Terraform failed to deploy storm on kubernetes. Exiting..."; exit 1; }
}

cluster_down() {
    terraform -chdir=terraform/cluster destroy -auto-approve || {
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
        cluster_up
        ;;
    down)
        cluster_down
        ;;
    *)
        echo "Action not found. Use 'up' or 'down'."
        exit 1
        ;;
esac
