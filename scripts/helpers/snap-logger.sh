#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap-logger.sh step-name
EOF
}


# Args handling
function log() {
    while read -r
    do
        echo "$(date +%F\ %T.%3N) $REPLY" >> "${LOG_FILE_PATH}"
    done
}

mkdir -p "${SNAP_LOG_DIR}/"

LOG_FILE_PATH="${SNAP_LOG_DIR}/${1}.log"
rm -f "${LOG_FILE_PATH}"

# exec 3>&1 1>> >(log) 2>&1
exec > >(tee -a "${LOG_FILE_PATH}") 2>&1
