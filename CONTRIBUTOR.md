## Developer Guide:



Steps to install it locally:
```
# build and package the snap
snapcraft --debug

# install the snap
sudo snap install opensearch_2.3.0_amd64.snap --dangerous --jailmode

# connect interfaces
sudo snap connect opensearch:log-observe
sudo snap connect opensearch:mount-observe
sudo snap connect opensearch:process-control
sudo snap connect opensearch:system-observe
sudo snap connect opensearch:cgroup-service-read

# create the certificates
sudo snap run opensearch.setup \
    --node-name cm0 \
    --node-roles cluster_manager,data \
    --tls-root-password root1234 \
    --tls-admin-password admin1234 \
    --tls-node-password node1234 \
    --tls-init-setup yes                 # this creates the root and admin certs as well.

# system configs required by opensearch, should be set using the following way:
sysctl -w vm.swappiness=0
sysctl -w vm.max_map_count=262144
sysctl -w net.ipv4.tcp_retries2=5

# start opensearch
sudo snap start opensearch.daemon

# initialize the security index
# should only be called once per cluster, or for rebuilding the security index
sudo snap run opensearch.security-init --admin-password=admin1234
```
