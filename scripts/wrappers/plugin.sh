#!/usr/bin/env bash

set -eu


source "${OPS_ROOT}"/helpers/snap-logger.sh "plugin"

usage() {
cat << EOF
usage: opensearch.plugin
  --install <plugin>	installs a plugin file. Must be a ZIP file
  --remove  <plugin>	removes a plugin.
  --list		list all the installed plugins.
  --help		show this helper
EOF
}

function install_plugin() {
	# Check if a valid URL
	plugin=$1
	if [ -z "$(wget $1 -O /var/snap/opensearch/common/plugin.zip > /dev/null 2>&1)" ]; then
		plugin="/var/snap/opensearch/common/plugin.zip"
	fi
	# Now, try to zip it
	if [ "$(file ${plugin} | grep Zip)" ]; then
		echo "ERROR: install only support zip files."
		exit 1
	fi
	"${OPENSEARCH_BIN}"/opensearch-plugin install ${plugin}
}

function remove_plugin() {
        "${OPENSEARCH_BIN}"/opensearch-plugin remove ${plugin}
}

function list_plugins() {
        "${OPENSEARCH_BIN}"/opensearch-plugin list
}

case $1 in
	--install)
		install_plugin $2
		;;
	--remove)
		remove_plugin $2
		;;
	--list)
		list_plugins
                ;;
        --help)
                usage
                exit
                ;;
esac
