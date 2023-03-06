#!/usr/bin/env bash

set -eu

source "${OPS_ROOT}"/helpers/snap-interfaces.sh


# Args
set_sysctl_props=""


# Args handling
function parse_args () {
    # set_sysctl_props boolean - from the charm, this should be set to "yes".
    set_sysctl_props="$(snapctl get set-sysctl-props)"
}

function set_defaults () {
    if [ -z "${set_sysctl_props}" ] || [ "${set_sysctl_props}" != "yes" ]; then
        set_sysctl_props="no"
    fi
}

function set_ulimits () {
    exit_if_missing_perm "sys-fs-cgroup-service"

    # 1. Set the number of open file handles
    # ulimit -n 1024 -- default in local machine
    if [ "$(ulimit -n)" -lt 65535 ]; then
        ulimit -n 65535
    fi

    # 2. Set the number of threads Opensearch can create, should be configured automatically if opensearch ran as a service
    # ulimit -u 60921 -- default in local machine
    max_threads="$(ulimit -u)"
    if [ "${max_threads}" != "unlimited" ] || [ "${max_threads}" -lt 4096 ]; then
        ulimit -u 4096
    fi

    # 3. Set the locked-in memory size to unlimited
    # ulimit -l 1964328 -- default in local machine
    # if snapctl is-connected "process-control"; then
    # ulimit -l unlimited
    # fi
}


function set_proc_conf () {
    # 1. Allow the opensearch user to Disable all swap files:
    # swapon -a -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.swappiness=0

    # 2. Ensuring sufficient virtual memory: https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
    # sysctl -w vm.max_map_count=65530 -- default in local machine
    "${SNAP}"/sbin/sysctl -w vm.max_map_count=262144

    # 3. Reduce TCP retransmission timeout = ~6 seconds
    # sysctl -w net.ipv4.tcp_retries2=15 -- default in local machine
    "${SNAP}"/sbin/sysctl -w net.ipv4.tcp_retries2=5
}


parse_args
set_defaults

set_ulimits

if [ "${set_sysctl_props}" == "yes" ]; then
    set_proc_conf
fi
