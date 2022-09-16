#!/usr/bin/env bash

set -eux


usage() {
cat << EOF
usage: start.sh --init-security yes --admin-password ...
To be ran / setup once per cluster - or when wanting to rebuild the security index.
--admin-password  (Optional)    Passphrase of the admin key
--help                          Shows help menu
EOF
}


# Args
admin_password=""


# Args handling
function parse_args () {
    # init-security boolean - from the charm, this should be based on a flag on the app data bag.
    local LONG_OPTS_LIST=(
        "admin-password"
        "help"
    )
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --admin-password) shift
                admin_password=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done

    # in case those are set through snap.set
    # init_security="$(snapctl get init-security)"
    # admin_password="$(snapctl get admin-password)"
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

# give it some time to bootstrap in case the commands were chained
# replace later with a request to the opensearch rest api
# and test on "OpenSearch Security not initialized." output
sleep 10s

source "${OPS_ROOT}"/helpers/snap-logger.sh "security-config"
init_security_plugin
