#!/bin/bash

set -e

OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g"

"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    ${OPENSEARCH_BIN}/${bin_script} "${@}"
