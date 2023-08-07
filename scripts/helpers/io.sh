#!/usr/bin/env bash

set -eu


# Set final permissions
# Following recommendation from: https://forum.snapcraft.io/t/system-usernames/13386/7
function set_access_restrictions () {
    if [[ $# -eq 2 ]]; then
        chmod -R "${2}" "${1}"
    fi

    chown -R snap_daemon "${1}"
    chgrp root "${1}"
}

function add_folder () {
    mkdir -p "${1}"
    set_access_restrictions "${1}" "${2}"
}

function add_file () {
    touch "${1}"
    set_access_restrictions "${1}" "${2}"
}

function file_copy () {
    mkdir -p "${2}"
    cp -r -p "${SNAP}/${1}" "${2}"

    if [[ $# -eq 3 ]]; then
        set_access_restrictions "${2}" "${3}"
    else
        set_access_restrictions "${2}"
    fi
}
