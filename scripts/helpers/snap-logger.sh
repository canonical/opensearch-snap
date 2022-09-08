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
        echo "$(date +%F\ %T.%3N) $REPLY"
    done
}

[ -d "${SNAP_LOG_DIR}" ] || mkdir -p "${SNAP_LOG_DIR}/"

LOG_FILE_PATH="${SNAP_LOG_DIR}/${1}.log"
rm -f "${LOG_FILE_PATH}"

exec &> >(log | tee -a "${LOG_FILE_PATH}")
