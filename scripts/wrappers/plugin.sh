#!/usr/bin/env bash

usage() {
cat << EOF
usage: opensearch.plugin
  --install <plugin>	installs a plugin file. Must be a ZIP file or the name of an default plugin
  --remove  <plugin>	removes a plugin.
  --list		list all the installed plugins.
  --help		show this helper
EOF
}

function install_plugin() {
	params=$@
	while [ $# -gt 0 ]; do
	case $1 in
		--install|--batch|-b|-s|--silent|-v|--verbose) # We have the params stored already
			;;
		-E) # More than one argument
			shift
			;;
		-h|--help)
		        OPENSEARCH_MAIN_CLASS=org.opensearch.plugins.PluginCli \
		          "${OPENSEARCH_BIN}"/opensearch-cli \
		          install --help
			exit
			;;
		*)
			# Found the plugin name, save it
			# TODO: figure out the plugin post installation, so we can have multiple formats (zip, name, etc)
			plugin=$1
			;;
	esac
	shift
	done
	# Do not use opensearch-plugin but call the one-liner command without setting
        # OPENSEARCH_ADDITIONAL_CLASSPATH_DIRECTORIES, as it points to the temp home folder.
        OPENSEARCH_MAIN_CLASS=org.opensearch.plugins.PluginCli \
          "${OPENSEARCH_BIN}"/opensearch-cli \
          install ${params}

	# Set permissions
	chmod -R 770 "${OPENSEARCH_HOME}"/*
	# chown -R snap_daemon "${OPENSEARCH_HOME}"/*
	# chgrp root "${OPENSEARCH_HOME}"/*

	# Set permissions for configuration and jar files
	chown -R snap_daemon "${OPENSEARCH_PATH_CONF}"/"$plugin"
        chmod -R 775 "${OPENSEARCH_PLUGINS}"/"$plugin"
        chmod 660 "${OPENSEARCH_PLUGINS}"/"$plugin"/plugin-descriptor.properties
        chmod 660 "${OPENSEARCH_PLUGINS}"/"$plugin"/plugin-security.policy
	chown snap_daemon "${OPENSEARCH_PLUGINS}"/"$plugin"/plugin-descriptor.properties
	chown snap_daemon "${OPENSEARCH_PLUGINS}"/"$plugin"/plugin-security.policy

	mv "${OPENSEARCH_PATH_CONF}"/"$plugin" "${SNAP_DATA}"/etc/opensearch > /dev/null 2>&1
        mv "${OPENSEARCH_PLUGINS}"/"$plugin" "${SNAP_DATA}"/usr/share/opensearch/plugins > /dev/null 2>&1
        # Optional move, generally do not create files here
        mv "${OPENSEARCH_MODULES}"/"$plugin" "${SNAP_DATA}"/usr/share/opensearch/modules > /dev/null 2>&1 || true
        mv "${OPENSEARCH_HOME}"/bin/"$plugin" "${SNAP_DATA}"/usr/share/opensearch/bin > /dev/null 2>&1 || true

	rm -rf "${SNAP_DATA}/temp_plugin"
}

function remove_plugin() {
	params=$@
        while [ $# -gt 0 ]; do
        case $1 in
                --remove|--batch|-b|-s|--silent|-v|--verbose) # We have the params stored already
                        ;;
                -E) # More than one argument
                        shift
                        ;;
                -h|--help)
                        OPENSEARCH_MAIN_CLASS=org.opensearch.plugins.PluginCli \
                          "${OPENSEARCH_BIN}"/opensearch-cli \
                          remove --help
                        exit
                        ;;
                *)
                        # Found the plugin name, save it
                        # TODO: figure out the plugin post installation, so we can have multiple formats (zip, name, etc)
                        plugin=$1
                        ;;
        esac
        shift
        done
	# Move to the correct folder, according to the path conf
        mv "${SNAP_DATA}"/etc/opensearch/"$plugin" "${OPENSEARCH_PATH_CONF}" > /dev/null 2>&1
        mv "${SNAP_DATA}"/usr/share/opensearch/plugins/"$plugin" "${OPENSEARCH_PLUGINS}" > /dev/null 2>&1
        # Optional move, generally do not create files here
        mv "${SNAP_DATA}"/usr/share/opensearch/modules/"$plugin" "${OPENSEARCH_MODULES}" > /dev/null 2>&1 || true
        mv "${SNAP_DATA}"/usr/share/opensearch/bin/"$plugin" "${OPENSEARCH_HOME}"/bin > /dev/null 2>&1 || true

        OPENSEARCH_MAIN_CLASS=org.opensearch.plugins.PluginCli \
          "${OPENSEARCH_BIN}"/opensearch-cli \
          remove ${params}

	rm -rf "${SNAP_DATA}/temp_plugin"
}

function list_plugins() {
	# Reset the env variables, as we want an actual list of the plugins
        OPENSEARCH_PATH_CONF="${SNAP_DATA}/etc/opensearch"
	OPENSEARCH_HOME="${SNAP_DATA}/usr/share/opensearch"
	OPENSEARCH_LIB="${SNAP_DATA}/usr/share/opensearch/lib"
	OPENSEARCH_PLUGINS="${SNAP_DATA}/usr/share/opensearch/plugins"
	OPENSEARCH_MODULES="${SNAP_DATA}/usr/share/opensearch/modules"

        "${OPENSEARCH_BIN}"/opensearch-plugin list
}



# Create temporary folders for the plugin, from the overloaded env variables
declare -a dirs=("${OPENSEARCH_PATH_CONF}" "${OPENSEARCH_PLUGINS}" "${OPENSEARCH_MODULES}" "${OPENSEARCH_HOME}"/bin)
for dir in "${dirs[@]}"; do
	mkdir -p "${dir}"
done

case $1 in
	--install)
		shift
		# --batch may be passed as argument as well
		install_plugin "$@"
                exit
		;;
	--remove)
		shift
		remove_plugin "$@"
                exit
		;;
	--list)
		list_plugins
                exit
                ;;
        --help)
                usage
                exit
                ;;
esac

usage
