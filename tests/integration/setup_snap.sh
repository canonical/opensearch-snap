#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -eux

usage ()  { echo "Call it with setup-snap.sh -f ./snap/snapcraft.yaml]"; exit 1; }
[ $# -eq 0 ] && usage

while getopts ":v:" option; do
    case $option in
        f)
        version="$(python3 -c \"import yaml; y=open('$OPTARG').read(); print(yaml.safe_load(y)['version'])\")"
        ;;
        *)
        usage
        exit 1
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