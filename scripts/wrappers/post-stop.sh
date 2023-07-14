#!/usr/bin/env bash

set -eu

# Remove the pid file
rm -f "${OPENSEARCH_HOME}"/pidfile
