## Developer Guide:



Steps to install it locally:
```
snapcraft --debug

sudo snap install opensearch_2.2.0_amd64.snap --dangerous --devmode

sudo snap connect opensearch:systemd-write

sudo snap run opensearch.setup \
    --node-name master0 \
    --node-roles cluster_manager \
    --tls-root-password root1234 \
    --tls-admin-password admin1234 \
    --tls-node-password node1234 \
    --tls-init-setup yes 

sudo snap restart opensearch.daemon
```
