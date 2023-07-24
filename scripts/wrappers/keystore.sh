#!/usr/bin/env bash

# Ensure add-file is loading files to the right place: /var/snap/opensearch/current folder
params=$@

if [ "$1" == "add-file" ]; then
	shift # discard add-file

	# Discard any options and get the file path
        while [ $# -gt 0 ]; do
        case $1 in
                -s|--silent|-v|--verbose) # We have the params stored already
                        ;;
                -E) # More than one argument
                        shift
                        ;;
                -h|--help)
			"${OPENSEARCH_BIN}"/opensearch-keystore add-file --help
                        exit
                        ;;
                *)
			# Found the file name
			file=$1
                        ;;
        esac
        shift
        done
        if [[ "$file" != "/var/snap/opensearch/current"* ]]; then
                echo "ERROR! File path must be set to /var/snap/opensearch/current/* to correctly add the key"
                exit 1
        fi
fi

# run the command
"${OPENSEARCH_BIN}"/opensearch-keystore ${params}

# opensearch.keystore must be set to the opensearch process user, fix permissions if file exists
chown snap_daemon:snap_daemon "${SNAP_DATA}"/etc/opensearch/opensearch.keystore > /dev/null 2>&1 || true
