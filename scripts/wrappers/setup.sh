#!/usr/bin/env bash

set -eux


usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--cluster-name        (Required)      Name of the cluster
--node-name           (Required)      Name of the current node
--node-roles          (Required)      Type of the node, array combination of: [cluster_manager, data, voting_only, ..]
--node-host           (Required)      IP address used to bind the node, default: [ _local_, _site_ ]
--seed-hosts          (Required)      Private IP of all the cluster-manager eligible nodes, default: ["127.0.0.1", "[::1]"]
--security-disabled   (Optional)      Enum of either yes, no (default). Enables or disables the security plugin.
--tls-self-managed    (Optional)      Enum of either yes (default), no. Generates and self-signs the certificates.
--tls-init-setup      (Optional)      Enum of either yes, no (default). Creates a root and admin certs if set to yes.
--tls-root-password   (Optional)      Password for encrypting the root key
--tls-root-subject    (Optional)      Subject for the root
--tls-admin-password  (Optional)      Password for encrypting the admin key
--tls-admin-subject   (Optional)      Subject for the admin certificate
--tls-node-password   (Optional)      Password for encrypting the node key
--tls-node-subject    (Optional)      Subject for the node certificate
--tls-for-rest        (Optional)      Enum of either: yes (default), no. Enables the certificate for both the transport and rest layers or just the former
--help                                Shows help menu
EOF
}

source "${OPS_ROOT}"/helpers/snap-logger.sh "setup"
source "${OPS_ROOT}"/helpers/set-conf.sh


# Args
cluster_name=""
node_name=""
node_roles=""
node_host=""
seed_hosts=""

security_disabled=""

tls_self_managed=""
tls_init_setup=""
tls_root_password=""
tls_root_subject=""
tls_admin_password=""
tls_admin_subject=""
tls_node_password=""
tls_node_subject=""
tls_for_rest=""

# Args handling
function parse_args() {
    local LONG_OPTS_LIST=(
        "cluster-name"
        "node-name"
        "node-roles"
        "node-host"
        "seed-hosts"
        "security-disabled"
        "tls-self-managed"
        "tls-init-setup"
        "tls-root-password"
        "tls-root-subject"
        "tls-admin-password"
        "tls-admin-subject"
        "tls-node-password"
        "tls-node-subject"
        "tls-for-rest"
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
            --cluster-name) shift
                cluster_name=$1
                ;;
            --node-name) shift
                node_name=$1
                ;;
            --node-roles) shift
                node_roles=$1
                ;;
            --node-host) shift
                node_host=$1
                ;;
            --seed-hosts) shift
                seed_hosts=$1
                ;;
            --security-disabled) shift
                security_disabled=$1
                ;;
            --tls-self-managed) shift
                tls_self_managed=$1
                ;;
            --tls-init-setup) shift
                tls_init_setup=$1
                ;;
            --tls-root-password) shift
                tls_root_password=$1
                ;;
            --tls-admin-password) shift
                tls_admin_password=$1
                ;;
            --tls-node-password) shift
                tls_node_password=$1
                ;;
            --tls-root-subject) shift
                tls_root_subject=$1
                ;;
            --tls-admin-subject) shift
                tls_admin_subject=$1
                ;;
            --tls-node-subject) shift
                tls_node_subject=$1
                ;;
            --tls-for-rest) shift
                tls_for_rest=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}


function set_defaults () {
    if [ -z "${cluster_name}" ]; then
        cluster_name="opensearch-cluster"
    fi

    if [ -z "${node_host}" ]; then
        node_host="[_local_, _site_]"
    fi

    if [ -z "${seed_hosts}" ]; then
        seed_hosts="[\"127.0.0.1\", \"[::1]\"]"
    fi

    node_roles="[ ${node_roles} ]"

    if [ -z "${security_disabled}" ] || [ "${security_disabled}" != "yes" ]; then
        security_disabled="no"
    fi

    if [ -z "${tls_self_managed}" ] || [ "${tls_self_managed}" != "no" ]; then
        tls_self_managed="yes"
    fi

    if [ -z "${tls_init_setup}" ] || [ "${tls_init_setup}" != "yes" ]; then
        tls_init_setup="no"
    fi

    if [ -z "${tls_for_rest}" ] || [ "${tls_for_rest}" != "no" ]; then
        tls_for_rest="yes"
    fi
}


function validate_args () {
    err_message=""
    if [ -z "${node_name}" ]; then
        err_message="- '--node-name' is required \n"
    fi

    if [ "${tls_self_managed}" == "yes" ]; then
        if [ -z "${tls_root_password}" ]; then
            err_message="${err_message}- '--tls-root-password' is required \n"
        fi
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


parse_args "$@"
set_defaults
validate_args


opensearch_yaml="${OPENSEARCH_PATH_CONF}/opensearch.yml"
set_yaml_prop "${opensearch_yaml}" "cluster.name" "${cluster_name}"
set_yaml_prop "${opensearch_yaml}" "node.name" "${node_name}"
set_yaml_prop "${opensearch_yaml}" "node.roles" "${node_roles}"
set_yaml_prop "${opensearch_yaml}" "network.host" "${node_host}"
set_yaml_prop "${opensearch_yaml}" "discovery.seed_hosts" "${seed_hosts}"

if [ "${security_disabled}" == "yes" ]; then
    set_yaml_prop "${opensearch_yaml}" "plugins.security.disabled" "true"
else
    set_yaml_prop "${opensearch_yaml}" "plugins.security.disabled" "false"
fi

if [ "${tls_self_managed}" ]; then
    TLS_DIR="${OPS_ROOT}/security/tls"

    if [ "${tls_init_setup}" == "yes" ]; then
        # create root and admin certs
        source \
            "${TLS_DIR}"/self-managed-init.sh \
                --root-password "${tls_root_password}" \
                --admin-password "${tls_admin_password}" \
                --root-subject "${tls_root_subject}" \
                --admin-subject "${tls_admin_subject}" \
                --rest-with-tls "${tls_for_rest}" \
                --target-dir "${OPENSEARCH_PATH_CERTS}"
    fi

    # create node cert
    source \
        "${TLS_DIR}"/self-managed-node.sh \
            --name "${node_name}" \
            --root-password "${tls_root_password}" \
            --node-password "${tls_node_password}" \
            --node-subject "${tls_node_subject}" \
            --rest-with-tls "${tls_for_rest}" \
            --target-dir "${OPENSEARCH_PATH_CERTS}"
fi


chmod -R 774 "${OPENSEARCH_PATH_CERTS}"
chown -R snap_daemon:snap_daemon "${OPENSEARCH_PATH_CERTS}"
