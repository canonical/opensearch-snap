#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

set -ex

sudo -E "${OPENSEARCH_BIN}"/opensearch-plugin remove repository-s3
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore remove s3.client.default.access_key
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore remove s3.client.default.secret_key

sudo snap restart opensearch.daemon
sleep 20s

"$(dirname $0)"/check_snap_install.sh