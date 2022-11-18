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
```
sudo snap install opensearch --channel=2.4.0/edge
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
sudo snap run opensearch.setup         \
    --node-name cm0                    \
    --node-roles cluster_manager,data  \
    --tls-root-password root1234       \
    --tls-admin-password admin1234     \
    --tls-node-password node1234       \
    --tls-init-setup yes    # this creates the root and admin certs as well.
```

#### Starting OpenSearch:
```
sudo snap start opensearch.daemon
```

#### Creating the Security Index:
```
sudo snap run opensearch.security-init --admin-password=admin1234
```

### Testing the OpenSearch setup:
You can either consume the REST API yourself or see if the below commands succeed, and you see that the tests "PASS" successfully: 
```
# Check if cluster is healthy (green):
sudo snap run opensearch.test-cluster-health-green

# Check if node is up:
sudo snap run opensearch.test-node-up

# Check if the security index is well initialised:
sudo snap run opensearch.test-security-index-created
```
