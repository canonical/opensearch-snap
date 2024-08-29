# Wazuh-Indexer-Snap
[![Build and Test](https://github.com/canonical/wazuh-indexer-snap/actions/workflows/ci.yaml/badge.svg)](https://github.com/canonical/wazuh-indexer-snap/actions/workflows/ci.yaml)
[![Publish](https://github.com/canonical/wazuh-indexer-snap/actions/workflows/release.yaml/badge.svg)](https://github.com/canonical/wazuh-indexer-snap/actions/workflows/release.yaml)

[//]: # (<h1 align="center">)
[//]: # (  <a href="wazuh.com/">)
[//]: # (    <img src="https://wazuh.com/uploads/2022/05/WAZUH.png" alt="Wazuh" />)
[//]: # (  </a>)
[//]: # (  <br />)
[//]: # (</h1>)

This is the snap for [Wazuh Indexer](https://documentation.wazuh.com/current/getting-started/components/wazuh-indexer.html), a community-driven, Apache 2.0-licensed open source search and
analytics suite that makes it easy to ingest, search, visualize, and analyze data.


### Installation:
[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/wazuh-indexer)

or:
```
sudo snap install wazuh-indexer --channel=latest/edge
sudo snap connect wazuh-indexer:process-control
```

### Environment configuration:
OpenSearch has a set of [pre-requisites](https://opensearch.org/docs/latest/opensearch/install/important-settings/) to function properly, they can be set as follows:
```
sudo sysctl -w vm.swappiness=0
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.ipv4.tcp_retries2=5
```

### Starting Wazuh Indexer:
#### Creating certificates:
```
# create the certificates
sudo snap run wazuh-indexer.setup          \
    --node-name cm0                     \
    --node-roles cluster_manager,data   \
    --tls-priv-key-root-pass root1234   \
    --tls-priv-key-admin-pass admin1234 \
    --tls-priv-key-node-pass node1234   \
    --tls-init-setup yes    # this creates the root and admin certs as well.
```

#### Starting Wazuh Indexer:
```
sudo snap start wazuh-indexer.daemon
```

#### Creating the Security Index:
```
sudo snap run wazuh-indexer.security-init --tls-priv-key-admin-pass=admin1234
```

### Testing the Wazuh Indexer setup:
You can either consume the REST API yourself or see if the below commands succeed, and you see that the tests `"PASSED"` successfully: 
```
# Check if cluster is healthy (green):
sudo snap run wazuh-indexer.test-cluster-health-green
> ....
> PASSED


# Check if node is up:
sudo snap run wazuh-indexer.test-node-up
> ....
> PASSED


# Check if the security index is well initialised:
sudo snap run wazuh-indexer.test-security-index-created
> ....
> PASSED
```

or:
```
sudo cp /var/snap/wazuh-indexer/current/etc/wazuh-indexer/certificates/node-cm0.pem ./
curl --cacert node-cm0.pem -XGET https://admin:admin@localhost:9200/_cluster/health?pretty
> {
  "cluster_name": "opensearch-cluster",
  "status": "green",
  "timed_out": false,
  "number_of_nodes": 1,
  "number_of_data_nodes": 1,
  "discovered_master": true,
  "discovered_cluster_manager": true,
  "active_primary_shards": 2,
  "active_shards": 2,
  "relocating_shards": 0,
  "initializing_shards": 0,
  "unassigned_shards": 0,
  "delayed_unassigned_shards": 0,
  "number_of_pending_tasks": 0,
  "number_of_in_flight_fetch": 0,
  "task_max_waiting_in_queue_millis": 0,
  "active_shards_percent_as_number": 100
}
```

## Running OpenSearch CLI commands not exposed by the snap:
In some cases, users may need to run cli commands that are not exposed by the Wazuh Indexer snap. To achieve this, those commands must be run as the `snap_daemon` user with the required environment variables passed: 

```
$ sudo -u snap_daemon \
	    OPENSEARCH_JAVA_HOME=/snap/wazuh-indexer/current/usr/lib/jvm/java-21-openjdk-amd64 \
	    OPENSEARCH_PATH_CONF=/var/snap/wazuh-indexer/current/etc/wazuh-indexer \
	    OPENSEARCH_HOME=/var/snap/wazuh-indexer/current/usr/share/wazuh-indexer \
	    OPENSEARCH_LIB=/var/snap/wazuh-indexer/current/usr/share/wazuh-indexer/lib \
	    OPENSEARCH_PATH_CERTS=/var/snap/wazuh-indexer/current/etc/wazuh-indexer/certificates \
	    /snap/wazuh-indexer/current/usr/share/wazuh-indexer/bin/<command> [options]
```

## License
The Wazuh Indexer Snap is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/wazuh-indexer-snap/blob/main/licenses/LICENSE-snap)
for more information.
