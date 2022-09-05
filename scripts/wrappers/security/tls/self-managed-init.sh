#!/usr/bin/env bash

set -eux


source "${OPS_ROOT}"/helpers/set-conf.sh


usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--root-password   (Required)    Password for encrypting the root key
--admin-password  (Optional)    Password for encrypting the admin key
--root-subject    (Optional)    Subject for the root certificate, defaults to [..../CN=localhost]
--admin-subject   (Optional)    Subject for the admin certificate
--rest-with-tls   (Optional)    Enum of either: yes (default), no. Enables the certificate for both the transport and rest layers or just the former
--target-dir      (Optional)    Where the certificates get stored
--help                          Shows help menu
EOF
}


# Args
root_password=""
admin_password=""
root_subject=""
admin_subject=""
rest_with_tls=""
target_dir=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "root-password"
        "admin-password"
        "root-subject"
        "admin-subject"
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
            --root-password) shift
                root_password=$1
                ;;
            --admin-password) shift
                admin_password=$1
                ;;
            --root-subject) shift
                root_subject=$1
                ;;
            --admin-subject) shift
                admin_subject=$1
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


# create the root cert
source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --password "${root_password}" \
    --subject "${root_subject}" \
    --target-dir "${target_dir}" \
    --type "root"

# create the admin cert
source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --root-password "${root_password}" \
    --password "${admin_password}" \
    --subject "${admin_subject}" \
    --target-dir "${target_dir}" \
    --type "admin"


# set conf
opensearch_yaml="${OPENSEARCH_PATH_CONF}/opensearch.yml"

set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.pemtrustedcas_filepath" "${target_dir}/root-ca.pem"
set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.transport.enforce_hostname_verification" "true"

if [ "${rest_with_tls}" == "yes" ]; then
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.pemtrustedcas_filepath" "${target_dir}/root-ca.pem"
    set_yaml_prop "${opensearch_yaml}" "plugins.security.ssl.http.enabled" "true"
fi


inverted_admin_subject=$(
    openssl x509 \
        -subject \
        -nameopt RFC2253 \
        -noout \
        -in "${target_dir}/admin.pem" \
        -passin pass:"${admin_password}"
)
inverted_admin_subject="${inverted_admin_subject##subject=}"
set_yaml_prop "${opensearch_yaml}" "plugins.security.authcz.admin_dn" "[${inverted_admin_subject}]"
