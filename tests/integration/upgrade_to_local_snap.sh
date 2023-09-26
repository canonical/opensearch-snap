#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -eux

usage ()  { echo "Usage: upgrade_to_local_snap.sh ([-f ./snap/snapcraft.yaml] or [-s <path to snap file>]) optionally: [-c <new revision to check, e.g. x1/x2...>]"; exit 1; }
[ $# -lt 2 ] && usage

source "$(dirname $(dirname $0))"/utils/process_yaml.sh

version=
revision="x2"

while true; do
    case "${1:-}" in
        -f)
        version=$(run_python_yaml $2 version)
        shift 2
        ;;
        -s)
        snapfile=$2
        shift 2
        ;;
        -c)
        revision="$2"
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

if [ -z $version ]; then
        sudo snap install ${snapfile} --dangerous --jailmode
else
        sudo snap install opensearch_${version}_amd64.snap --dangerous --jailmode
fi

if [ "$(ls /var/snap/opensearch/${revision})" ]; then
    echo "Snap upgraded."
else
    exit 1
fi

sudo snap connect opensearch:log-observe
sudo snap connect opensearch:mount-observe
sudo snap connect opensearch:process-control
sudo snap connect opensearch:system-observe
sudo snap connect opensearch:sys-fs-cgroup-service
sudo snap connect opensearch:shmem-perf-analyzer


sudo snap restart opensearch.daemon
