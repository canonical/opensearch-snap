#!/usr/bin/bash

set -eux

run_python_yaml () {
    python3 -c "import yaml; y=open('$1').read(); print(yaml.safe_load(y)['$2'])"
}

sudo cp "${OPENSEARCH_PATH_CERTS}"/node-cm0.pem ./
cert=./node-cm0.pem

# Check node name
curl --cacert ${cert} -XGET https://localhost:9200 -u 'admin:admin' > /tmp/cluster_resp
echo -e "Cluster Response: \n $(cat /tmp/cluster_resp)"
node_name="$(run_python_yaml /tmp/cluster_resp name)"
if [ "${node_name}" != "cm0" ]; then
    exit 1
fi

# Check cluster health
curl --cacert "${cert}" -XGET https://localhost:9200/_cluster/health -u 'admin:admin' > /tmp/health_resp
echo -e "Cluster Health Response: \n $(cat /tmp/health_resp)"
cluster_status="$(run_python_yaml /tmp/health_resp status)"

# TODO: once this https://github.com/opensearch-project/OpenSearch/issues/8862 is fixed
# replace the following condition by "${cluster_status}" != "green"  
if [ "${cluster_status}" == "red" ]; then
    curl --cacert ${cert} -XGET https://localhost:9200/_cat/shards -u 'admin:admin'
    exit 1
fi