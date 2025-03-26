#!/bin/bash

set -e

if ! ls ${SNAP_DATA_CURRENT}/etc/java-extra-opts > /dev/null 2>&1; then
    echo 'OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g"' > ${SNAP_DATA_CURRENT}/etc/java-extra-opts
fi

source "${SNAP_DATA_CURRENT}"/etc/java-extra-opts

"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    ${OPENSEARCH_BIN}/${bin_script} "${@}"
