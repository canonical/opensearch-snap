#!/usr/bin/env bash

set -eu

usage() {
cat << EOF
usage: test-cluster-health-green.sh --admin-auth-password admin
Tests if the cluster's health status is green.
--admin-auth-password  (Optional) Password for basic auth with the opensearch rest api, default "admin"
--help                            Shows help menu
EOF
}


# Args
admin_auth_password=""


# Args handling
function parse_args () {
    # init-security boolean - from the charm, this should be based on a flag on the app data bag.
    local LONG_OPTS_LIST=(
        "admin-auth-password"
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
            --admin-auth-password) shift
                admin_auth_password=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${admin_auth_password}" ]; then
        admin_auth_password="admin"
    fi
}


parse_args "$@"
set_defaults


# Check cluster health
endpoint="https://localhost:9200/_cluster/health"

health_resp=$(curl -k -XGET "${endpoint}" -u "admin:${admin_auth_password}")
echo -e "Cluster Health Response: \n ${health_resp}"

cluster_status=$(echo "${health_resp}" | yq -r .status)
if [ "${cluster_status}" != "green" ]; then
    exit 1
fi

echo "PASSED."
