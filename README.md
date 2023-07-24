# OpenSearch-Snap

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
sudo cp /var/snap/opensearch/current/config/certificates/node-cm0.pem ./
curl --cacert node-cm0.pem -XGET https://admin:admin@localhost:9200/_cluster/health
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

## CLI Commands

Snaps overload the environment variables such as OPENSEARCH_HOME and sets them to the /snap and /var/snap folder paths.

To use the CLI commands, either use the snap commands, such as ```opensearch.<command>``` or call other CLI commands as described below.

The snap overloads the following commands:

### Plugin CLI

Snap provides a way to safely manage plugins into opensearch.

#### Install Plugins

```
opensearch.plugin --install [--batch --verbose --silent] <plugin-name>

# For example:
$ sudo opensearch.plugin --install repository-s3 # demands root user
-> Installing repository-s3
-> Downloading repository-s3 from opensearch
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@     WARNING: plugin requires additional permissions     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* java.lang.RuntimePermission accessDeclaredMembers
* java.lang.RuntimePermission getClassLoader
* java.lang.reflect.ReflectPermission suppressAccessChecks
* java.net.NetPermission setDefaultAuthenticator
* java.net.SocketPermission * connect,resolve
* java.util.PropertyPermission opensearch.allow_insecure_settings read,write
See http://docs.oracle.com/javase/8/docs/technotes/guides/security/permissions.html
for descriptions of what these permissions allow and the associated risks.
-> Installed repository-s3 with folder name repository-s3
(failed reverse-i-search)`regstart': juju un^Cgister localhost-localhost
```

#### List Plugins

```
$ sudo opensearch.plugin --list
opensearch-alerting
opensearch-anomaly-detection
opensearch-asynchronous-search
opensearch-cross-cluster-replication
opensearch-geospatial
opensearch-index-management
opensearch-job-scheduler
opensearch-knn
opensearch-ml
opensearch-neural-search
opensearch-notifications
opensearch-notifications-core
opensearch-observability
opensearch-performance-analyzer
opensearch-reports-scheduler
opensearch-security
opensearch-security-analytics
opensearch-sql
repository-s3
```

#### Remove Plugins

```
opensearch.plugin --remove <plugin>

# For example:
$ sudo opensearch.plugin --remove repository-s3
-> removing [repository-s3]...
```

### Keystore CLI

Keystore CLI allows users to manage keystore similarly to OpenSearch's CLI.

The user must set only the command and use the same options and values as the upstream CLI.

```
$ opensearch.keystore [options] <value>
```

#### Adding key with file

Save the file in a path that snap can access: ```/var/snap/opensearch/current/<path to your file>```.

Then, execute the command as usual:

```
$ opensearch.keystore add-file [options] /var/snap/opensearch/current/<path to your file>
```

### Running other CLI commands

To run other CLI commands from opensearch, the appropriate environment variables must also be set.

Here is an example on how to set it:
```
$ sudo OPENSEARCH_JAVA_HOME=/snap/opensearch/current/usr/share/opensearch/jdk \
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
