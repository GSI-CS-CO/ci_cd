#!/usr/bin/env python
# Generates graph from getinfo.py JSON output

import sys
import json
import argparse
from os import getenv
import logging
import pydot
from collections import defaultdict

# Logging config
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# Globals
checked = []
links = defaultdict(list) # unique links between devices
graph = pydot.Dot(graph_type='graph', ranksep='1', filled=True)

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


def build_graph(devicelist, root, ptp_state = '0'):
    global checked
    global graph
    global links

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
        node.set_fillcolor('yellow')
        if ptp_state in ptp_synched_states:
            node.set_fillcolor('greenyellow')
    else:
        node.set_width(3)
        node.set_height(1)

    graph.add_node(node)

    if device.get('if') is not None:
        for interface in device.get('if'):
            logger.info("Device %s has neighbour %s" % (device.get('sysname'), interface.get('neighbour')))
            neighbour = str(interface.get('neighbour'))
            if neighbour not in checked or (root in links.keys() and neighbour not in links[root]):
                links[str(neighbour)].append(root)
                logger.info("Adding relationship to graph")
                edge = pydot.Edge(device.get('sysname'), interface.get('neighbour'), minlen='1.5', headlabel=interface.get('neighbour_port'),
                                  taillabel=interface.get('name'), labeldistance=2, labelstyle="sloped", color="gray" )
                if interface.get('speed', 10) > 100:
                    edge.set_style('bold')
                graph.add_edge(edge)

                # PTP state extension
                ptp_state = '0'
                if 'ptp_state' in interface:                           # PTP state is known for this interface
                    ptp_state = interface.get('ptp_state')

                build_graph(devicelist, interface.get('neighbour'), ptp_state)

if __name__ == "__main__":
    # Fallback values
    defaultInfofile = getenv('INFOFILE', 'info.json')
    defaultLogfile = getenv('LOGFILE', None)
    defaultOutfile = getenv('OUTFILE', 'graph.png')

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
    else:
        # By default, log to stderr.
        ch = logging.StreamHandler()
        ch.setLevel(logging.ERROR)
        logger.addHandler(ch)
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

    build_graph(devicelist, args.root)

    for node in graph.get_node_list():
        if node.get_label():
          print "ss"
          node.set_fillcolor('orange')
    graph.write_svg(args.outfile)
