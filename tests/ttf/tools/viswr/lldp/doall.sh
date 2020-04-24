#!/bin/bash

# Author Adam Wujek <adam.wujek@cern.ch>
# getopts part based on
# https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash

RUN_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

usage() {
    echo "Usage: $0 -s <switch> -g <file.svg>" 1>&2;
    echo "  -s <switch>       - hostname of a switch which will be represented as a root of a graph" 1>&2;
    echo "                      Note: It does not have to be Grand master switch" 1>&2;
    echo "  -g <file.svg>     - File to store a topology graph" 1>&2;
    exit 1; }

while getopts "s:g:v:" o; do
    case "${o}" in
        s)
            host=${OPTARG}
            ;;
        g)
            graph_file=${OPTARG}
            ;;
        v)
            vis_file=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${host}" ]; then
    usage
fi

set -e
# defaults
TPL_FILE="$RUN_DIR"/topology.json        # network topology
WRTPL_FILE="$RUN_DIR"/wr_topology.json  # network topology with WR status
VIS_FILE="$RUN_DIR"/graph.json          # output file for web visualization
GRAPH_FILE="$RUN_DIR"/graph.svg         # output file with topology graph
LOG_FILE="$RUN_DIR"/topology.log        # log
export OIDFILE="$RUN_DIR"/oid.json

if [ -z "${vis_file}" ]; then
    vis_file=$VIS_FILE
fi

if [ -z "${graph_file}" ]; then
    graph_file=$GRAPH_FILE
fi

# get network topology
"$RUN_DIR"/lldp.py list "$host" -l $LOG_FILE | "$RUN_DIR"/getinfo.py > $TPL_FILE

# extend a network topology with WR status
"$RUN_DIR"/wrs.py -i $TPL_FILE -t $WRTPL_FILE

# create an output file for visualization
"$RUN_DIR"/vis.py -i $WRTPL_FILE -o "$vis_file"

# create an output file with topology graph
"$RUN_DIR"/graph.py -i $WRTPL_FILE -o "$graph_file" "$host" -l $LOG_FILE
