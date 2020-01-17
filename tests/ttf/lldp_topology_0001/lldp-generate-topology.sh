#!/bin/bash

# Author Adam Wujek <adam.wujek@cern.ch>
# getopts part based on
# https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash

RUN_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
#"

usage() {
    echo "Usage: $0 -s <switch hostname> -o <file.svg>" 1>&2;
    echo "  -s <hostname>     - hostname of a switch which will be represented as a root of a graph" 1>&2;
    echo "                      Note: It does not have to be Grand master switch" 1>&2;
    echo "  -o <filename.svg> - File to store a topology graph" 1>&2;
    exit 1; }

while getopts "s:o:" o; do
    case "${o}" in
        s)
            host=${OPTARG}
            ;;
        o)
            graph_file=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${host}" ] || [ -z "${graph_file}" ]; then
    usage
fi

set -e
TMP_JSON=`mktemp --suffix=.json`
export OIDFILE="$RUN_DIR"/oid.json
"$RUN_DIR"/lldp.py list "$host" | "$RUN_DIR"/getinfo.py > $TMP_JSON
"$RUN_DIR"/graph.py -i $TMP_JSON -o "$graph_file" "$host"

rm $TMP_JSON
