#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -eux

usage ()  { echo "Usage: upgrade_to_local_snap.sh -f ./snap/snapcraft.yaml -c <new revision to check, e.g. x1/x2...>]"; exit 1; }
[ $# -lt 4 ] && usage

source "$(dirname $(dirname $0))"/utils/process_yaml.sh

version=
revision="x2"

while true; do
    case "${1:-}" in
        -f)
        version=$(run_python_yaml $2 version)
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

sudo snap install opensearch_${version}_amd64.snap --dangerous --jailmode

if [ "$(ls /var/snap/opensearch/${revision})" ]; then
    echo "Snap upgraded."
else
    exit 1
fi
sudo snap restart opensearch.daemon