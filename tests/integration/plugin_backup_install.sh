#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -ex

usage ()  { echo "Usage: install_backup_plugin.sh -a|--access-key ACCESS_KEY -s|--secret-key SECRET_KEY"; exit 1; }

ACCESS_KEY="TEST"
SECRET_KEY="TEST"

if [ $# -gt 0 ]; then
    while true; do
        case "$1" in
            a|access-key)
            ACCESS_KEY="$2"
            shift 2
            ;;
            s|secret-key)
            SECRET_KEY="$2"
            shift 2
            ;;
            h|help)
            usage
            exit 1
            ;;
            *)
            break
            ;;
        esac
    done
fi

sudo -E "${OPENSEARCH_BIN}"/opensearch-plugin remove repository-s3 || true
sudo -E "${OPENSEARCH_BIN}"/opensearch-plugin install --batch repository-s3

sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore add --force s3.client.default.access_key < <(echo "${ACCESS_KEY}")
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore add --force s3.client.default.secret_key < <(echo "${SECRET_KEY}")

sudo snap restart opensearch.daemon
sleep 20s

"$(dirname $0)"/check_snap_install.sh