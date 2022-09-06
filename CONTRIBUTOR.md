## Developer Guide:



Steps to install it locally:
```
# build and package the snap
snapcraft --debug

# install the snap
sudo snap install opensearch_2.2.0_amd64.snap --dangerous --jailmode

# connect interfaces
sudo snap connect opensearch:log-observe                                                                                                            ✔  20s  Python3.10   22:31:09 
sudo snap connect opensearch:mount-observe                                                                                                                ✔  Python3.10   22:31:34 
sudo snap connect opensearch:process-control                                                                                                              ✔  Python3.10   22:31:41 
sudo snap connect opensearch:procsys-read

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

# system configs required by opensearch
sysctl -w vm.swappiness=0
sysctl -w vm.max_map_count=262144
sysctl -w net.ipv4.tcp_retries2=5

# start opensearch
sudo snap start opensearch.daemon
```
