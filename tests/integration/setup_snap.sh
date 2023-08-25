#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -eux

usage ()  { echo "Usage: setup_snap.sh -f ./snap/snapcraft.yaml]"; exit 1; }
[ $# -lt 2 ] && usage

source "$(dirname $(dirname $0))"/utils/process_yaml.sh

while true; do
    case "${1:-}" in
        -f)
        version=$(run_python_yaml $2 version)
        shift 2
        ;;
        -h)
        usage
        exit 1
        ;;
        *)
        break
        ;;
    esac
done

sudo snap remove --purge opensearch
sudo snap install opensearch_${version}_amd64.snap --dangerous --jailmode

sudo sysctl -w vm.swappiness=0
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.ipv4.tcp_retries2=5

sudo snap connect opensearch:log-observe
sudo snap connect opensearch:mount-observe
sudo snap connect opensearch:process-control
sudo snap connect opensearch:system-observe
sudo snap connect opensearch:sys-fs-cgroup-service

sudo snap run opensearch.setup \
    --node-name cm0 \
    --node-roles cluster_manager,data \
    --tls-priv-key-root-pass root1234 \
    --tls-priv-key-admin-pass admin1234 \
    --tls-priv-key-node-pass node1234 \
    --tls-init-setup yes                 # this creates the root and admin certs as well.

sudo snap start opensearch.daemon

sleep 15s

sudo snap run opensearch.security-init --tls-priv-key-admin-pass=admin1234