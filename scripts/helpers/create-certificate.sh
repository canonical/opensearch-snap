#!/usr/bin/env bash

set -eux


usage() {
cat << EOF
usage: create-certificate.sh --password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for encrypting the key
--type            (Required)    Enum of either: root, admin, node, client
--root-password   (Optional)    Password for encrypting the root key
--name            (Optional)    Name of certificate: required for nodes and clients
--subject         (Optional)    Subject for the certificate, defaults to CN=localhost
--target-dir      (Optional)    The target directory where the certificates and related resources are created
--help                          Shows help menu
EOF
}


# Defaults
ALLOWED_CERT_TYPES=("root" "admin" "node" "client") # "node" refers to the transport layer, whereas "client" refers to the "Rest" layer
KEY_SIZE_BITS=2048
LIFESPAN_DAYS=730
declare -A SUBJECTS=( ["root"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=localhost"  # CN=root.dns.a-record
                      ["admin"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=admin"
                      ["node"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=localhost")  # CN=node1.dns.a-record


# Args
password=""
root_password=""
type=""
res_name=""
subject=""
target_dir=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "password"
        "root-password"
        "type"
        "name"
        "subject"
        "target-dir"
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
            --password) shift
                password=$1
                ;;
            --root-password) shift
                root_password=$1
                ;;
            --type) shift
                type=$1
                ;;
            --name) shift
                res_name=$1
                ;;
            --subject) shift
                subject=$1
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

function set_defaults () {
    if [ -z "${subject}" ] && [ "${type}" != "client" ]; then
        subject="${SUBJECTS["${type}"]}"
    fi

    if [ "${type}" == "node" ] || [ "${type}" == "client" ]; then
        res_name="${type}-${res_name}"
    else
        res_name="${type}"
    fi

    if [ -z "${target_dir}" ]; then
        target_dir="."
    fi

    if [ -z "${root_password}" ]; then
        root_password="${password}"
    fi
}

function validate_args () {
    err_message=""
#    if [ -z "${password}" ]; then
#        err_message=" - '--password' is required \n"
#    fi

    if [ -z "${root_password}" ] && [ "${type}" != "root" ]; then
        err_message="${err_message}- '--root-password' must be set.\n"
    fi

    if ! echo "${ALLOWED_CERT_TYPES[*]}" | grep -wq "${type}"; then
        err_message="${err_message}- '--type' must be set to one of: ${ALLOWED_CERT_TYPES[*]}.\n"
    fi

    if [ -n "${res_name}" ] && [ "${res_name}" == "${type}." ]; then
        err_message="${err_message}- '--name' of the resource must be provided for nodes and clients (i.e: --name node1).\n"
    fi

    if [ -z "${subject}" ]; then
        err_message="${err_message}- '--subject' must be correctly set if specified, as it overrides the default value for local setups otherwise. \n"
    fi

    if [ -z "${target_dir}" ]; then
        err_message="${err_message}- '--target-dir' must be a correct path, or not set to point to the current directory. \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


# Certs creation
function create_root_certificate () {
    # generate a private key
    openssl genrsa \
        -out "${target_dir}/root-ca-key.pem" \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # generate a root certificate
    openssl req \
        -new \
        -x509 \
        -sha256 \
        -passin pass:"${password}" \
        -passout pass:"${password}" \
        -key "${target_dir}/root-ca-key.pem" \
        -out "${target_dir}/root-ca.pem" \
        -subj "${subject}" \
        -days ${LIFESPAN_DAYS}
}


function create_certificate () {
    # generate a private key certificate
    openssl genrsa \
        -out "${target_dir}/${res_name}-key-temp.pem" \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # convert created key to PKS-8 Java compatible format
    openssl pkcs8 \
        -inform PEM \
        -outform PEM \
        -in "${target_dir}/${res_name}-key-temp.pem" \
        -topk8 \
        -v1 PBE-SHA1-3DES \
        -passout pass:"${password}" \
        -passin pass:"${password}" \
        -out "${target_dir}/${res_name}-key.pem"

    # create a CSR
    openssl req \
        -new \
        -passout pass:"${password}" \
        -passin pass:"${password}" \
        -key "${target_dir}/${res_name}-key.pem" \
        -subj "${subject}" \
        -out "${target_dir}/${res_name}.csr"

    # generate the certificate
    openssl x509 \
        -req \
        -in "${target_dir}/${res_name}.csr" \
        -CA "${target_dir}/root-ca.pem" \
        -CAkey "${target_dir}/root-ca-key.pem" \
        -CAcreateserial \
        -sha256 \
        -passin pass:"${root_password}" \
        -out "${target_dir}/${res_name}.pem" \
        -days ${LIFESPAN_DAYS}
}


parse_args "$@"
set_defaults
validate_args

mkdir -p "${target_dir}"

if [[ "${type}" == "root" ]]; then
    create_root_certificate
else
    create_certificate
fi

