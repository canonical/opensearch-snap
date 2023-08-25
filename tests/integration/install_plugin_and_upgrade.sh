#!/usr/bin/bash
# Copyright 2023 Canonical Ltd.
# See LICENSE file for licensing details.

sudo -E "${OPENSEARCH_BIN}"/opensearch-plugin install --batch repository-s3

echo "TEST" | sudo tee -a testkey

sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore add-file s3.client.default.access_key ${PWD}/testkey
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore add-file s3.client.default.secret_key ${PWD}/testkey

sudo snap restart opensearch
sleep 20s

sudo cp /var/snap/opensearch/current/etc/opensearch/certificates/node-cm0.pem ./
cert=./node-cm0.pem

cluster_resp=$(curl --cacert ${cert} -XGET https://localhost:9200 -u 'admin:admin')
echo -e "Cluster Response: \n ${cluster_resp}"
node_name=$(echo "${cluster_resp}" | yq -r .name)
if [ "${node_name}" != "cm0" ]; then
    exit 1
fi

# Upgrade snap
version="$(cat snap/snapcraft.yaml | yq .version)"
sudo snap install opensearch_${version}_amd64.snap --dangerous --jailmode

if [ "$(ls /var/snap/opensearch/x2)" ]; then
    echo "Snap upgraded."
else
    exit 1
fi

sudo -E "${OPENSEARCH_BIN}"/opensearch-plugin remove repository-s3
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore remove s3.client.default.access_key
sudo -E "${OPENSEARCH_BIN}"/opensearch-keystore remove s3.client.default.secret_key