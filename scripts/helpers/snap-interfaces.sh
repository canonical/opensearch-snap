#!/usr/bin/env bash


function exit_if_missing_perm () {
    if ! snapctl is-connected "${1}";
    then
        echo "Please run the following command: sudo snap connect opensearch:${1}"
        echo "Then run: sudo snap start opensearch.daemon"
        exit 1
    fi
}
