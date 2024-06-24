# OpenSearch-Snap
[![Build and Test](https://github.com/canonical/opensearch-snap/actions/workflows/ci.yaml/badge.svg)](https://github.com/canonical/opensearch-snap/actions/workflows/ci.yaml)
[![Publish](https://github.com/canonical/opensearch-snap/actions/workflows/release.yaml/badge.svg)](https://github.com/canonical/opensearch-snap/actions/workflows/release.yaml)

[//]: # (<h1 align="center">)
[//]: # (  <a href="https://opensearch.org/">)
[//]: # (    <img src="https://opensearch.org/assets/brand/PNG/Logo/opensearch_logo_default.png" alt="OpenSearch" />)
[//]: # (  </a>)
[//]: # (  <br />)
[//]: # (</h1>)

This is the snap for [OpenSearch](https://opensearch.org), a community-driven, Apache 2.0-licensed open source search and
analytics suite that makes it easy to ingest, search, visualize, and analyze data.


### Installation:
[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/opensearch)

or:
```
sudo snap install opensearch --channel=2/candidate
sudo snap connect opensearch:process-control
sudo snap connect opensearch:sys-fs-hugepages-folder
```

### Environment configuration:
OpenSearch has a set of [pre-requisites](https://opensearch.org/docs/latest/opensearch/install/important-settings/) to function properly, they can be set as follows:
```
sudo sysctl -w vm.swappiness=0
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.ipv4.tcp_retries2=5
```

### Starting OpenSearch:
#### Creating certificates:
```
# create the certificates
sudo snap run opensearch.setup          \
    --node-name cm0                     \
    --node-roles cluster_manager,data   \
    --tls-priv-key-root-pass root1234   \
    --tls-priv-key-admin-pass admin1234 \
    --tls-priv-key-node-pass node1234   \
    --tls-init-setup yes    # this creates the root and admin certs as well.
```

#### (Optional) Set `snap_daemon` homedir:

If your machine will be running only OpenSearch snap, or running it alongside other snaps that do not need homedir for snap_daemon, then set it as follows:
```
sudo mkdir /var/snap/opensearch/common/home
sudo chown -R snap_daemon:snap_daemon /var/snap/opensearch/common/home
sudo usermod -d /var/snap/opensearch/common/home snap_daemon
```

#### Starting OpenSearch:
```
sudo snap start opensearch.daemon
```

#### Creating the Security Index:
```
sudo snap run opensearch.security-init --tls-priv-key-admin-pass=admin1234
```

### Testing the OpenSearch setup:
You can either consume the REST API yourself or see if the below commands succeed, and you see that the tests `"PASSED"` successfully: 
```
# Check if cluster is healthy (green):
sudo snap run opensearch.test-cluster-health-green
> ....
> PASSED


# Check if node is up:
sudo snap run opensearch.test-node-up
> ....
> PASSED


# Check if the security index is well initialised:
sudo snap run opensearch.test-security-index-created
> ....
> PASSED
```

or:
```
sudo cp /var/snap/opensearch/current/etc/opensearch/certificates/node-cm0.pem ./
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
In some cases, users may need to run cli commands that are not exposed by the OpenSearch snap. To achieve this, those commands must be run as the `snap_daemon` user with the required environment variables passed: 

```
$ sudo -u snap_daemon \
	    OPENSEARCH_JAVA_HOME=/snap/opensearch/current/usr/lib/jvm/java-21-openjdk-amd64 \
	    OPENSEARCH_PATH_CONF=/var/snap/opensearch/current/etc/opensearch \
	    OPENSEARCH_HOME=/var/snap/opensearch/current/usr/share/opensearch \
	    OPENSEARCH_LIB=/var/snap/opensearch/current/usr/share/opensearch/lib \
	    OPENSEARCH_PATH_CERTS=/var/snap/opensearch/current/etc/opensearch/certificates \
	    /snap/opensearch/current/usr/share/opensearch/bin/<command> [options]
```

## License
The Opensearch Snap is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/opensearch-snap/blob/main/licenses/LICENSE-snap)
for more information.
