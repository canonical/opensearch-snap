#!/usr/bin/env bash

set -eux

source "${OPS_ROOT}"/helpers/snap-logger.sh "daemon"

usage() {
cat << EOF
usage: start.sh --init-security yes --admin-password ...
To be ran / setup once per cluster.
--init-security   (Optional)    Enum of either: yes (default), no . Should be ran ONCE per cluster IF security enabled.
--admin-password  (Optional)    Passphrase of the admin key
--help                          Shows help menu
EOF
}

# TODO: change defaults and register the service arguments in an arguments file


# Args
init_security=""
admin_password=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "init-security"
        "admin-password"
        "help"
    )
    # shellcheck disable=SC2155
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --init-security) shift
                init_security=$1
                ;;
            --admin-password) shift
                admin_password=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${init_security}" ] || [ "${init_security}" != "no" ]; then
        init_security="yes"
    fi
}


parse_args "$@"
set_defaults


# system config
if ! snapctl is-connected systemd-write;
then
    echo "Please run the following command: sudo snap connect opensearch:systemd-write"
    echo "Then run: sudo snap restart opensearch.daemon"
    exit 1
fi


# start
"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    "${OPENSEARCH_HOME}"/bin/opensearch


# run security_admin tool if security enabled
# How to set passphrases
# TODO only run once per cluster
if [ "${init_security}" == "yes" ]; then
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
fi
