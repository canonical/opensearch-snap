#!/usr/bin/env bash

set -eux

source "${OPS_ROOT}"/helpers/snap-logger.sh "daemon"
source "${OPS_ROOT}"/helpers/snap-interfaces.sh


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
    exit_if_missing_perm "mount-observe"
    exit_if_missing_perm "procsys-read"
    exit_if_missing_perm "log-observe"

    # start
    "${SNAP}"/usr/bin/setpriv \
        --clear-groups \
        --reuid snap_daemon \
        --regid snap_daemon -- \
        "${OPENSEARCH_HOME}"/bin/opensearch &

    # give it some time to bootstrap
    sleep 30s
}

function init_security_plugin () {
    sec_args=(
        "-cd" "${OPENSEARCH_PATH_CONF}/opensearch-security/"
        "-icl" "-nhnv"
        "-cacert" "${OPENSEARCH_PATH_CERTS}/root-ca.pem"
        "-cert" "${OPENSEARCH_PATH_CERTS}/admin.pem"
        "-key" "${OPENSEARCH_PATH_CERTS}/admin-key.pem"
    )

    if [ -n "${admin_password}" ]; then
        sec_args+=("-keypass" "${admin_password}")
    fi

    source \
        "${OPENSEARCH_PLUGINS}/opensearch-security/tools/securityadmin.sh" \
        "${sec_args[@]}"
}


parse_args "$@"
set_defaults

start_opensearch

if [ "${init_security}" == "yes" ]; then
    init_security_plugin
fi
