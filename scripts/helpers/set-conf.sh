#!/usr/bin/env bash


function replace_in_file () {
    sed -i "s@${2}@${3}@" "${1}"
}


function set_yaml_prop() {
    local target_file="${1}"
    local full_key_path="${2}"
    local value="${3}"
    local append="${4:-"no"}"

    operator="="

    # allow appending
    if [ "${append}" == "yes" ]; then
        operator="+="
    fi

    # traversal must be done through the "/" separator to allow for "." in key names
    IFS='/' read -r -a keys <<< "${full_key_path}"

    expression=""
    for key in "${keys[@]}"
    do
        prefix=""
        suffix=""
        if [[ "${key}" != [* ]]; then
            prefix=".\""
            suffix="\""
        fi
        expression="${expression}${prefix}${key}${suffix}"
    done

    # yq fails serializing values starting with "/" must be escaped
    if [[ "${value}" == /* ]]; then
        value="\"${value}\""
    fi

    yq -i "${expression} ${operator} ${value}" "${target_file}"
}


#function set_python_prop () {
#    python3 \
#        "${OPS_ROOT}"/helpers/conf-setter.py \
#        --file "${1}" \
#        --key "${2}" \
#        --value "${3}" \
#        --output "persist"
#}
