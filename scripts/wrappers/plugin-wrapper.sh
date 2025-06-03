#!/usr/bin/env bash

set -e -o pipefail

snap run --shell opensearch.daemon -- /snap/opensearch/current/usr/share/opensearch/bin/opensearch-plugin.orig "${@}"
