#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap run opensearch.plugins-add --name [opensearch.]security --location https://..plugin.zip
To be ran / setup once per cluster.
--name        (Required)    Name of the plugin, can be prefixed by "opensearch." or not.
--location    (Required)    Location of the zip plugin, served through https:// or file:///
--help                      Shows help menu
EOF
}


# Args
name=""
location=""  # zip served through https:// or file:///


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "name"
        "location"
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
            --location) shift
                location=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}


function install_plugin () {

    # Fetch the list of installed plugins
    INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)

    if ! echo "${INSTALLED_PLUGINS}" | grep -q "$1";
    then
        echo y | "${OPENSEARCH_HOME}"/bin/opensearch-plugin install "$2"
    fi

    INSTALLATION_PATH="${OPENSEARCH_PLUGINS}/$1"
    CONFIG_PATH="${OPENSEARCH_PATH_CONF}/$1"

    for path in "${INSTALLATION_PATH}" "${CONFIG_PATH}"; do
        chmod -R 770 "${path}"
        chown -R snap_daemon:snap_daemon "${path}"
    done

}

parse_args "$@"


if [[ "${name}" != "opensearch-*" ]]; then
    name="opensearch-${name}"
fi
install_plugin "${name}" "${location}"
