#!/usr/bin/env bash

set -eu


function set_access_restrictions () {
    if [[ $# -eq 2 ]]; then
        chmod -R "${2}" "${1}"
    fi

    chown -R snap_daemon "${1}"
    chgrp root "${1}"
}

function add_folder () {
    [ -d "${1}" ] || mkdir -p "${1}"
    set_access_restrictions "${1}" "${2}"
}

function add_file () {
    touch "${1}"
    set_access_restrictions "${1}" "${2}"
}

function dir_copy_if_not_exists () {
    cp -R -n "${SNAP}/${1}" "${2}"

    if [[ $# -eq 3 ]]; then
        set_access_restrictions "${2}/${1}" "${3}"
    else
        set_access_restrictions "${2}/${1}"
    fi
}

function file_copy () {
    cp -n "${SNAP}/${1}" "${2}"

    if [[ $# -eq 3 ]]; then
        set_access_restrictions "${2}" "${3}"
    else
        set_access_restrictions "${2}"
    fi
}

function copy_files_between_folder () {
    cp -r "$1"* "$2"
    chmod -R 770 "$2"
    find "$2" -type f -exec chmod 660 {} \;
}
