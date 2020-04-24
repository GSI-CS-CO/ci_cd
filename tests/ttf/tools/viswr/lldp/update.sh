#!/bin/bash

# Create a JSON file for network topology visualization
# Network topology is compatible with the Gephi specification

RUN_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

usage() {
    echo "Usage: $0 -i <topology> -o <graph>" 1>&2;
    echo "  -i <topology>   - File with the WR network topology" 1>&2;
    echo "  -o <graph>      - File to store a topology graph" 1>&2;
    exit 1; }

while getopts "i:o:" o; do
    case "${o}" in
        i)
            topology=${OPTARG}
            ;;
        o)
            graph=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

#if [ -z "${host}" ]; then
#    usage
#fi

set -e
# defaults
TPL_FILE="$RUN_DIR"/topology.json        # network topology
WRTPL_FILE="$RUN_DIR"/wr_topology.json  # network topology with WR status
VIS_FILE="$RUN_DIR"/graph.json          # output file for web visualization
GRAPH_FILE="$RUN_DIR"/graph.svg         # output file with topology graph
LOG_FILE="$RUN_DIR"/topology.log        # log
export OIDFILE="$RUN_DIR"/oid.json

if [ -z "${topology}" ]; then
    if [ -e "$TPL_FILE" ]; then
        topology=$TPL_FILE
    else
        exit 2
    fi
fi

if [ -z "${graph}" ]; then
    graph=$GRAPH_FILE
fi

# get network topology
#"$RUN_DIR"/lldp.py list "$host" -l $LOG_FILE | "$RUN_DIR"/getinfo.py > $TPL_FILE

# extend a network topology with WR status
"$RUN_DIR"/wrs.py -i "$topology" -t $WRTPL_FILE

# create an output file for visualization
"$RUN_DIR"/vis.py -i $WRTPL_FILE -o "$graph"

# create an output file with topology graph
#"$RUN_DIR"/graph.py -i $WRTPL_FILE -o "$graph_file" "$host" -l $LOG_FILE
