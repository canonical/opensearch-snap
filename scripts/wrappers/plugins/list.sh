#!/usr/bin/env bash


# Fetch the list of installed plugins
INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)
echo "${INSTALLED_PLUGINS}"
