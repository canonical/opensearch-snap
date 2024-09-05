## Developer Guide:


### Installation:
Steps to install it locally:
```
# build and package the snap
snapcraft --debug

# install the snap
sudo snap install wazuh_indexer_4.8.2_amd64.snap --dangerous --jailmode
```

### Environment configuration:
Now, configuring the required system settings along with connecting the interfaces, in either of the following ways:

1. Provided [helper script](setup-dev-env.sh):
    ```
    bash setup-dev-env.sh
    ```
2. Manually:
    ```
    # connect interfaces
    sudo snap connect wazuh-indexer:log-observe
    sudo snap connect wazuh-indexer:mount-observe
    sudo snap connect wazuh-indexer:process-control
    sudo snap connect wazuh-indexer:system-observe
    sudo snap connect wazuh-indexer:sys-fs-cgroup-service
   
    # system configs required by wazuh-indexer, should be set using the following way:
    sudo sysctl -w vm.swappiness=0
    sudo sysctl -w vm.max_map_count=262144
    sudo sysctl -w net.ipv4.tcp_retries2=5
    ```

### Set-up an Wazuh Indexer cluster:
```
# create the certificates
sudo snap run wazuh-indexer.setup            \
    --node-name cm0                       \
    --node-roles cluster_manager,data     \
    --tls-priv-key-root-pass root1234     \
    --tls-priv-key-admin-pass admin1234   \
    --tls-priv-key-node-pass node1234     \
    --tls-init-setup yes    # this creates the root and admin certs as well.

# start wazuh-indexer
sudo snap start wazuh-indexer.daemon

# initialize the security index
# should only be called once per cluster, or for rebuilding the security index
sudo snap run wazuh-indexer.security-init --tls-priv-key-admin-pass=admin1234
```

### Test your installation:
The Wazuh Indexer setup can be tested either in either of the following ways:
1. Provided [helper script](test-dev-cluster.sh):
    ```
    bash test-dev-cluster.sh
    ```
2. Manually:
    ```
   # Check if cluster is healthy (green):
   sudo snap run wazuh-indexer.test-cluster-health-green
   
   # Check if node is up:
   sudo snap run wazuh-indexer.test-node-up
   
   # Check if the security index is well initialised:
   sudo snap run wazuh-indexer.test-security-index-created
   ```

### For live debugging:
1. The journal logs:
   ```
   sudo sysctl -w kernel.printk_ratelimit=0 ; journalctl --follow | grep wazuh-indexer
   ```
2. Snap logs:
   ```
   snappy-debug scanlog --only-snap=wazuh-indexer
   ```
