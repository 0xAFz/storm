#!/bin/bash

set -euo pipefail

cd $(dirname "$0") || exit 1

apply() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist!" >&2
        exit 1
    fi
    
    source ./$dir/.env || echo "$dir/.env not found. skipping..."
    terraform -chdir="$dir" init
    terraform -chdir="$dir" apply -auto-approve
}

destroy() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist!" >&2
        exit 1
    fi

    source ./$dir/.env || echo "$dir/.env not found. skipping..."
    terraform -chdir="$dir" init
    terraform -chdir="$dir" destroy -auto-approve
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <action> <directory>. Use 'apply' or 'destroy'"
    exit 1
fi

if [ $# -eq 1 ]; then
    echo "Usage: $0 <action> <directory>. (path/compute)"
    exit 1
fi

case "$1" in
    apply)
        apply $2
        ;;
    destroy)
        destroy $2
        ;;
    *)
        echo "Action not found. Use 'apply' or 'destroy'."
        exit 1
        ;;
esac
