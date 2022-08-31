#!/usr/bin/env bash


function set_yaml_prop () {
    key="${2}:"
    full_line="${key} ${3}"

    if grep -q "^#\?\s*${key}" "${1}";
    then
        sed -i "s@.*${key}.*@${full_line}@" "${1}"
    else
        echo "${full_line}" >> "${1}"
    fi
}
