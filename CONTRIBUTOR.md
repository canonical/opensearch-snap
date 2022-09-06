## Developer Guide:



Steps to install it locally:
```
# build and package the snap
snapcraft --debug

# install the snap
sudo snap install opensearch_2.2.0_amd64.snap --dangerous --jailmode

# connect interfaces
sudo snap connect opensearch:log-observe
sudo snap connect opensearch:mount-observe
sudo snap connect opensearch:process-control
sudo snap connect opensearch:procsys-read
sudo snap connect opensearch:procsys-write
sudo snap connect opensearch:system-observe

# create the certificates
sudo snap run opensearch.setup \
    --node-name master0 \
    --node-roles cluster_manager,data \
    --tls-root-password root1234 \
    --tls-admin-password admin1234 \
    --tls-node-password node1234 \
    --tls-init-setup yes                 # this creates the root and admin certs as well.

# set the admin password
sudo snap set opensearch admin-password=admin1234

# only in the first cluster setup, or for rebuilding the security index
sudo snap set opensearch init-security=yes

# system configs required by opensearch, can set one of the following ways:
    # 1- by users in local machines, adjust values if needed
        sysctl -w vm.swappiness=0
        sysctl -w vm.max_map_count=262144
        sysctl -w net.ipv4.tcp_retries2=5
        
    # 2- by juju or cloud deployments:
        sudo snap set set-sysctl-props=yes

# start opensearch
sudo snap start opensearch.daemon
```
