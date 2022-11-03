#!/usr/bin/env bash

set -eux


source "${OPS_ROOT}"/helpers/set-conf.sh


usage() {
cat << EOF
usage: change-conf.sh --operation put --file opensearch.yml --key cluster.name --val my-cluster...
Run to add/update/delete config blocks based on the passed key.
--operation (Required)  Enum of either "put", "delete". Operation to run on a value on a yaml config file.
--file      (Required)  Target config file on which the operation must be ran.
--key       (Required)  The full path to the target key.
--val       (Optional)  The value to set, in case of "put".
--append    (Optional)  Enum of either: yes, no (default). Whether to append in case of "put", for arrays.
--help                  Shows help menu.
EOF
}


# Args
operation=""
target_file=""
key=""
val=""
append=""


# Args handling
function parse_args() {
    local LONG_OPTS_LIST=(
        "operation"
        "file"
        "key"
        "val"
        "append"
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
            --operation) shift
                operation="${1,,}"
                ;;
            --file) shift
                target_file=$1
                ;;
            --key) shift
                key=$1
                ;;
            --val) shift
                val=$1
                ;;
            --append) shift
                val="${1,,}"
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${append}" ] || [ "${append}" != "yes" ]; then
        append="no"
    fi
}

function validate_args () {
    err_message=""
    if [ -z "${operation}" ]; then
        err_message="- '--operation' is required \n"
    elif [ "${operation}" != "put" ] && [ "${operation}" != "delete" ]; then
        err_message="- '--operation' can be either be one of: 'put', 'delete' \n"
    fi

    if [ -z "${file}" ]; then
        err_message="- '--file' is required \n"
    fi

    if [ -z "${key}" ]; then
        err_message="${err_message}- '--key' is required \n"
    fi

    if [ "${operation}" == "put" ] && [ -z "${val}" ]; then
        err_message="${err_message}- '--val' is required on 'put' operations \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


parse_args "$@"
set_defaults
validate_args

if [ "${operation}" == "put" ]; then
    set_yaml_prop "${target_file}" "${key}" "${value}" "${append}" "yes"
else
    remove_yaml_prop "${target_file}" "${key}"
fi