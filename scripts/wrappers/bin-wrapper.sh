#!/bin/bash

set -e

if ! ls ${SNAP_DATA_CURRENT}/etc/opensearch/java-extra-opts > /dev/null 2>&1; then
    echo 'export OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g"' | tee ${SNAP_DATA_CURRENT}/etc/opensearch/java-extra-opts
fi

source "${SNAP_DATA_CURRENT}"/etc/opensearch/java-extra-opts

"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    ${OPENSEARCH_BIN}/${bin_script} "${@}"
