#!/bin/bash

set -e

"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    "${JAVA_HOME}"/bin/java \
    -Xms256m -Xmx256m \
    -Xshare:auto \
    -Djava.security.manager=allow \
    -cp "${OPENSEARCH_LIB}/*" \
    -Dopensearch.path.home="${OPENSEARCH_HOME}" \
    -Dopensearch.path.conf="${OPENSEARCH_PATH_CONF}" \
    org.opensearch.bootstrap.OpenSearch "${@}"
