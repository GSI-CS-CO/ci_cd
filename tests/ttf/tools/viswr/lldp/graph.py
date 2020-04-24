#!/usr/bin/env python
# Generates graph from getinfo.py JSON output

import sys
import json
import argparse
from os import getenv
import logging
import pydot
from collections import defaultdict

# Logging config, by default log to stderr
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
logger = logging.getLogger()
logger.addHandler(ch)

# Globals
ptp_servo_track_phase = '4'      # numeric value of 'track phase' (WR-SWITCH-MIB.txt)
ptp_synched_states = ['6', '9']  # PTP FSM states (master, slave) of WR port (White Rabbit Specification v2.0)

def get_object_from_file(filename):
    '''
    Parse json input from file, return object(s) or None
    '''
    inputtext = None
    j = None
    # Open and read file
    try:
        with open(filename) as f:
            inputtext = f.read()
    except IOError:
        logger.error("Could not read from file %s" % filename)
        return None
    # Try to parse text as json
    try:
        j = json.loads(inputtext)
    except ValueError:
        logger.error("No valid JSON detected in input")
    # Return parsed object or None
    return j


def get_object_from_stdin():
    '''
    Parse json input from stdin, return object(s) or None
    '''
    inputtext = None
    j = None
    # Read STDIN if it is not a TTY
    if not sys.stdin.isatty():
        inputtext = "".join(sys.stdin)
    else:
        logger.debug("Detected TTY at STDIN")
        return None
    # Try to parse text as json
    try:
        j = json.loads(inputtext)
    except ValueError:
        logger.error("No valid JSON detected in input")
    # Return parsed object or None
    return j


def build_graph(devicelist, root, graph, links, checked, ptp_state = '0'):
    '''
    Build dot graph from the WR network topology in JSON

    Parameters:
    - devicelist: network topology in JSON (Gephi-compatible)
    - graph:      dot graph
    - links:      list with unique links between network devices
    - root:       root switch
    - ptp_state:  WR attribute
    - checked:    list with network devices that are already included in a graph
    '''

    if not devicelist:
        logger.error("Device list empty.")
        return None

    if root in checked:
        logger.warning("%s already checked. Skipping." % root)
        return None

    root = str(root)
    checked.append(root)
    device = devicelist.get(root)

    if not device:
        logger.error("No data on %s" % root)
        return None

    logger.info("Checking %s" % device.get('sysname'))
    node = pydot.Node(device.get('sysname'))
    node.set_style('filled')
    if (device.get('sysname').startswith("nwt")):
        node.set_fillcolor('orange')
        if 'ptp_servo_n' in device and device.get('ptp_servo_n') == ptp_servo_track_phase:
            node.set_fillcolor('deepskyblue')
    if (device.get('sysname').startswith("WR")):
        node.set_fillcolor('#dc322f')  # solarized red
        if ptp_state in ptp_synched_states:
            node.set_fillcolor('greenyellow')
    else:
        node.set_width(3)
        node.set_height(1)

    graph.add_node(node)

    if device.get('if') is not None:
        for interface in device.get('if'):
            device_sysname = device.get('sysname')
            neighbour = interface.get('neighbour')
            logger.info("Device %s has neighbour %s" % (device_sysname, neighbour))
            neighbour_str = str(neighbour)
            if neighbour_str not in checked or (root in links.keys() and neighbour_str not in links[root]):
                links[neighbour_str].append(root)
                logger.info("Adding relationship to graph")
                edge = pydot.Edge(device_sysname, neighbour, minlen='1.5', headlabel=interface.get('neighbour_port'),
                                  taillabel=interface.get('name'), labeldistance=2, labelstyle="sloped", color="gray" )
                if interface.get('speed', 10) > 100:
                    edge.set_style('bold')
                graph.add_edge(edge)

                # PTP state extension
                ptp_state = '0'
                if 'ptp_state' in interface:                           # PTP state is known for this interface
                    ptp_state = interface.get('ptp_state')

                build_graph(devicelist, neighbour, graph, links, checked, ptp_state)

def export_to_svg(network_json, root_dev, output_svg_file):
    '''
    Export network in JSON to graph in SVG

    Parameters:
    - network_json:    network description in the Gephi-compatible JSON format
    - root_dev:        root network device
    - output_svg_file: network graph in the SVG format
    '''
    links = defaultdict(list) # unique links between devices
    graph = pydot.Dot(graph_type='graph', ranksep='1', filled=True)
    checked = []

    build_graph(network_json, root_dev, graph, links, checked)

    for node in graph.get_node_list():
        if node.get_label():
          node.set_fillcolor('orange')

    return graph.write(output_svg_file, format='svg')

if __name__ == "__main__":
    # Fallback values
    defaultInfofile = getenv('INFOFILE', 'info.json')
    defaultLogfile = getenv('LOGFILE', None)
    defaultOutfile = getenv('OUTFILE', 'graph.svg')

    # Parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("root",
                        help="Device to put as root of the graph", metavar="ROOT")
    parser.add_argument("-i", "-f", "--infofile", default=defaultInfofile,
                        help="File to read info about devices from (default: %s or stdin)" % defaultInfofile)
    parser.add_argument("-o", "--outfile", default=defaultOutfile,
                        help="File to write to (default: %s)" % defaultOutfile)
    parser.add_argument("-l", "--logfile", default=defaultLogfile,
                        help="Log file (default is logging to STDERR)")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Do not display or log errors")
    parser.add_argument("-v", "--verbose", action="count", default=0,
                        help="Increase verbosity when using logfile.")
    args = parser.parse_args()

    # In the logging module, following levels are defined:
    # Critical: 50, Error: 40, Warn: 30, Info: 20, Debug: 10
    # args.verbose holds the number of '-v' specified.
    # We substract 10 times that value from our default of 40 (Error)
    # If we go too low, use value 10 (Debug)
    loglevel = min((40 - (args.verbose * 10)), 10)

    # Logging handlers
    # If file name provided for logging, write detailed log.
    if args.logfile:
        fh = logging.FileHandler(args.logfile)
        fh.setLevel(loglevel)
        logger.addHandler(fh)
    # If quiet mode, disable all logging.
    if args.quiet:
        logger.disabled = True

    # Main logic
    devicelist = get_object_from_file(args.infofile)
    if not devicelist:
        devicelist = get_object_from_stdin()
    if not devicelist:
        logger.error("No JSON found in %s or in stdin. Giving up." % args.infofile)
        sys.exit()

    links = defaultdict(list) # unique links between devices
    graph = pydot.Dot(graph_type='graph', ranksep='1', filled=True)
    checked = []

    build_graph(devicelist, args.root, graph, links, checked)

    for node in graph.get_node_list():
        if node.get_label():
          node.set_fillcolor('orange')

    graph.write(args.outfile, format='svg')
