#!/usr/bin/env bash


source "${OPS_ROOT}"/helpers/snap-logger.sh "set-sys-config"


function set_system_conf () {
    exit_if_missing_perm "procsys-read"

    # 1. Set the number of open file handles
    # ulimit -n 1024 -- default in local machine
    ulimit -n 65535

    # 2. Set the number of threads Opensearch can create, should be configured automatically if opensearch ran as a service
    # ulimit -u 60921 -- default in local machine
    if [ "$(ulimit -u)" -lt 4096 ]; then
        ulimit -u 4096
    fi

    # 3. Set the locked-in memory size to unlimited
    # ulimit -l 1964328 -- default in local machine
    ulimit -l unlimited

    # 4. Allow the opensearch user to Disable all swap files:
    # swapon -a -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.swappiness=0

    # 5. Ensuring sufficient virtual memory: https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
    # sysctl -w vm.max_map_count=65530 -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.max_map_count=262144

    # 6. Reduce TCP retransmission timeout = ~6 seconds
    # sysctl -w net.ipv4.tcp_retries2=15 -- default in local machine
    "${SNAP}"/sbin/sysctl -w net.ipv4.tcp_retries2=5
}

set_system_conf
