#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap run opensearch.plugins-add --name [opensearch.]security --location https://..plugin.zip
To be ran / setup once per cluster.
--name        (Required)    Name of the plugin, will have the prefix "opensearch-" if not set.
--purge       (Required)    Enum of yes, no (default). Removes any config file related to this plugin if set to yes.
--help                      Shows help menu
EOF
}


# Args
name=""
purge=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "name"
        "purge"
        "help"
    )
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --name) shift
                name=$1
                ;;
            --purge) shift
                purge=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${purge}" ] || [ "${purge}" != "yes" ]; then
        purge="no"
    fi

    if [[ "${name}" != "opensearch-*" ]]; then
        name="opensearch-${name}"
    fi
}


function remove_plugin () {

    # Fetch the list of installed plugins
    INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)

    if ! echo "${INSTALLED_PLUGINS}" | grep -q "$1";
    then
        echo "Plugin not installed."
        exit 0
    fi

    cmd_args=( "$1" )
    if [ "${purge}" == "yes" ]; then
        cmd_args+=( "--purge" )
    fi

    echo y | "${OPENSEARCH_HOME}"/bin/opensearch-plugin remove "${cmd_args[@]}"
    echo "Plugin: ${name} removed."
}

parse_args "$@"
set_defaults

remove_plugin "${name}"
