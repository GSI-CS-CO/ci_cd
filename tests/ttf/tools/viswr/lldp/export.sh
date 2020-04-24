#!/bin/bash

# Create a SVG file with network topology

RUN_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

usage() {
    echo "Usage: $0 -i <topology> -r <root> -o <graph>" 1>&2;
    echo "  -i <topology>   - File with the WR network topology" 1>&2;
    echo "  -r <root>       - Root WR switch" 1>&2;
    echo "  -o <graph>      - File to store a topology graph" 1>&2;
    exit 1; }

while getopts "i:r:o:" o; do
    case "${o}" in
        i)
            topology=${OPTARG}
            ;;
        r)
            root=${OPTARG}
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

if [ -z "${topology}" ]  || [ -z "${root}" ] || [ -z "${graph}" ]; then
    usage
fi

set -e
# defaults
WRTPL_FILE="$RUN_DIR"/wr_topology.json  # network topology with WR status
GRAPH_FILE="$RUN_DIR"/graph.svg         # output file with topology graph

# create an output file with topology graph
"$RUN_DIR"/graph.py -i "$topology" -o "$graph" "$root"
