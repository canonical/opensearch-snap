#!/usr/bin/env bash

set -eux


source "${OPS_ROOT}"/helpers/set-conf.sh


usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--name            (Required)    Name of the node
--root-password   (Required)    Password for encrypting the root key
--node-password   (Optional)    Password for encrypting the node key
--node-subject    (Optional)    Subject for the node certificate
--rest-with-tls   (Optional)    Enum of either: yes (default), no. Enables the certificate for both the transport and rest layers or just the former
--target-dir      (Optional)    Where the certificates get stored
--help                          Shows help menu
EOF
}


# Args
name=""
root_password=""
node_password=""
node_subject=""
rest_with_tls=""
target_dir=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "name"
        "root-password"
        "node-password"
        "node-subject"
        "rest-with-tls"
        "target-dir"
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
            --name) shift
                name=$1
                ;;
            --root-password) shift
                root_password=$1
                ;;
            --node-password) shift
                node_password=$1
                ;;
            --node-subject) shift
                node_subject=$1
                ;;
            --rest-with-tls) shift
                rest_with_tls=$1
                ;;
            --target-dir) shift
                target_dir=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function validate_args () {
    err_message=""
    if [ -z "${root_password}" ]; then
        err_message="- '--root-password' is required \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


parse_args "$@"
validate_args


# create the node cert
source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --name "${name}" \
    --root-password "${root_password}" \
    --password "${node_password}" \
    --subject "${node_subject}" \
    --target-dir "${target_dir}" \
    --type "node"


# set conf
opensearch_yaml="${OPENSEARCH_PATH_CONF}/opensearch.yml"

set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.pemtrustedcas_filepath" "${target_dir}/root-ca.pem"
set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.pemcert_filepath" "${target_dir}/node-${name}.pem"
set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.pemkey_filepath" "${target_dir}/node-${name}-key.pem"
if [ -n "${node_password}" ]; then
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.pemkey_password" "${node_password}"
fi

if [ "${rest_with_tls}" == "yes" ]; then
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.pemtrustedcas_filepath" "${target_dir}/root-ca.pem"
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.pemcert_filepath" "${target_dir}/node-${name}.pem"
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.pemkey_filepath" "${target_dir}/node-${name}-key.pem"
    if [ -n "${node_password}" ]; then
        set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.pemkey_password" "${node_password}"
    fi
fi

inverted_node_subject=$(
    openssl x509 \
        -subject \
        -nameopt RFC2253 \
        -noout \
        -in "${target_dir}/node-${name}.pem" \
        -passin pass:"${node_password}"
)
inverted_node_subject="${inverted_node_subject##subject=}"
set_yaml_prop "${opensearch_yaml}" "plugins.security.nodes_dn" "[\"${inverted_node_subject}\"]"
