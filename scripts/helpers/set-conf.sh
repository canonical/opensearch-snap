#!/usr/bin/env bash


function replace_in_file() {
    "${SNAP}"/usr/bin/setpriv \
        --reuid snap_daemon -- sed -i "s@${2}@${3}@" "${1}"
}

function set_yaml_prop() {
    local target_file="${1}"
    local full_key_path="${2}"
    local value="${3}"
    local append="${4:-"no"}"
    local split_array_content="${5:-"yes"}"

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

    # yq fails serializing values starting with or containing special characters so they must be wrapped in double quotes
    # so, wrap any non number
    if [[ "${value}" == [* ]]; then
        value=${value:1:-1}

        if [ "${split_array_content}" == "yes" ]; then
            IFS=',' read -r -a arr_elts <<< "${value}"

            value=""
            for key in "${arr_elts[@]}"
            do
                key=$(echo -e "${key}" | tr -d '[:space:]')
                if ! [[ ${key} =~ ^[0-9]+$ ]] && ! [[ ${key} =~ ^\".*\"$ ]]; then
                    key="\"${key}\""
                fi
                value="${value}${key},"
            done
            value="[${value:0:-1}]"
        else
            value="[${value}]"
        fi
    elif ! [[ "${value}" =~ ^[0-9]+$ ]]  && ! [[ ${value} =~ ^\".*\"$ ]]; then
       value="\"${value}\""
    fi

    "${SNAP}"/bin/yq -i "${expression} ${operator} ${value}" "${target_file}"
}
