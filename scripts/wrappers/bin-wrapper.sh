#!/bin/bash

set -e

if [ -z "${OPENSEARCH_JAVA_OPTS}" ]; then
    OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g"
fi

OPENSEARCH_JAVA_OPTS="${OPENSEARCH_JAVA_OPTS}" "${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    ${OPENSEARCH_BIN}/${bin_script} "${@}"
