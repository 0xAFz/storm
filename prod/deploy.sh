#!/bin/bash

cd $(dirname "$0") || exit 1

source ./.env.prod

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
    ansible all -i ansible/inventory/hosts.yml -m ping --timeout 1
}

cluster_up() {
    terraform -chdir=terraform/cluster init && \
    terraform -chdir=terraform/cluster plan && \
    terraform -chdir=terraform/cluster apply -auto-approve

    python3 ansible/inventory/dynamic.py

    if [ "$?" -ne 0 ]; then
        echo "dynamic.py failed to generate hosts.yml file. Exiting..."
        exit 1
    fi

    until check_ping; do
        echo "Waiting for VM's to become reachable..."
        sleep 1
    done

    ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/cluster.yml
}

cluster_down() {
    terraform -chdir=terraform/cluster destroy -auto-approve
}

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
