#!/usr/bin/env bash

set -eux


# source "${OPS_ROOT}"/helpers/snap-logger.sh "daemon"
source "${OPS_ROOT}"/helpers/snap-interfaces.sh
source "${OPS_ROOT}"/sys/set-sys-config.sh


usage() {
cat << EOF
usage: start.sh --init-security yes --admin-password ...
To be ran / setup once per cluster.
--init-security   (Optional)    Enum of either: yes (default), no . Should be ran ONCE per cluster IF security enabled.
--admin-password  (Optional)    Passphrase of the admin key
--help                          Shows help menu
EOF
}


# Args
init_security=""
admin_password=""


# Args handling
function parse_args () {
    # init-security boolean - from the charm, this should be based on a flag on the app data bag.
    init_security="$(snapctl get init-security)"
    admin_password="$(snapctl get admin-password)"
}

function set_defaults () {
    if [ -z "${init_security}" ] || [ "${init_security}" != "no" ]; then
        init_security="yes"
    fi
}

function start_opensearch () {
    exit_if_missing_perm "log-observe"
    exit_if_missing_perm "mount-observe"
    exit_if_missing_perm "process-control"
    exit_if_missing_perm "procsys-read"
    exit_if_missing_perm "system-observe"

    # start
    "${SNAP}"/usr/bin/setpriv \
        --clear-groups \
        --reuid snap_daemon \
        --regid snap_daemon -- \
        "${OPENSEARCH_HOME}"/bin/opensearch
}


parse_args
set_defaults

start_opensearch
