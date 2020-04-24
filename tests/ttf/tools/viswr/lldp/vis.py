#!/usr/bin/env python
# Create Gephi-compatible JSON file to be processed by vis Javascript library

# Usage: python vis.py -i wr_topology.json -o graph.json

import sys
import json
import argparse
from os import getenv
import logging
import re
from collections import defaultdict

import binascii

from graph import get_object_from_file, get_object_from_stdin, ptp_synched_states

# Logging config, by default log to stderr
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
logger = logging.getLogger()
logger.addHandler(ch)

# Globals
checked_nodes = []
checked_edges = defaultdict(list)  # unique edges between nodes

vis_graph = {}                # JSON object
edges = []                    # JSON array "edges"
nodes = []                    # JSON array "nodes"
labels = {}                   # get node ID by node name, {label:id}

regex_ip = "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"  # regex used to check IP address

# VisJS constants
Vis_Ptp_Servo_TP = '#00bfff'    # deepskyblue for TRACK_PHASE
Vis_Ptp_Servo_Other = '#ff9900' # orange for other status
Vis_Ptp_State_MS = '#adff2f'    # greenyellow for master/slave state
Vis_Ptp_State_Other = '#dc322f' # solarized red for other states
Vis_Non_WR = '#808080'          # grey for non-WR devices

def build_vis_graph(devices_json, dev_name, nodes, labels, edges, info=None):
    '''
    Parse JSON input from file, return JSON compatible with the vis-network JS library
    '''

    if not devices_json:
        logger.error("Device dict empty.")
        return None

    if dev_name in checked_nodes:
        logger.warning("%s already checked. Skipping." % dev_name)
        return None

    dev_name = str(dev_name)
    checked_nodes.append(dev_name)
    dev_attrs = devices_json.get(dev_name)

    if not dev_attrs:
        logger.error("No data on %s" % dev_name)
        return None

    dev_sysname = dev_attrs.get('sysname')
    dev_id = dev_attrs.get('id')
    labels[dev_sysname] = dev_id
    logger.info("Checking %s" % dev_sysname)

    node = {}
    node["id"] = int(dev_id)
    node["label"] = dev_sysname
    node["title"] = 'location ' + dev_sysname
    nodes.append(node)

    vis_attrs = {}     # attributes: WR, PTP, system info etc
    vis_attrs["group"] = "other"
    if dev_sysname.startswith("nwt"):
        vis_attrs["group"] = "nwt"
    elif dev_sysname.startswith("nwe"):
        vis_attrs["group"] = "nwe"
    if "uptime" in dev_attrs:
        vis_attrs["uptime"] = dev_attrs.get('uptime')
    if "ptp_servo" in dev_attrs:
        vis_attrs["ptp_servo"] = dev_attrs.get('ptp_servo')

    # optional visjs color attribute, color table from https://www.w3schools.com/colors/colors_shades.asp
    if vis_attrs.get('group') == "nwt":
        if vis_attrs.get('ptp_servo') == 'TRACK_PHASE':
            node["color"] = Vis_Ptp_Servo_TP
        else:
            node["color"] = Vis_Ptp_Servo_Other
    elif vis_attrs.get('group') == "nwe":
        node["color"] = Vis_Non_WR
    else:
        node["size"] = 10.0
        node["color"] = Vis_Ptp_State_Other
        if info is not None:
            if info.get('ptp_state') in ptp_synched_states:
                node["color"] = Vis_Ptp_State_MS

    node["attributes"] = vis_attrs

    if dev_attrs.get('if') is not None:

        vis_attrs["if"] = dev_attrs.get('if')

        for interface in dev_attrs.get('if'):
            neighbour = interface.get('neighbour')
            logger.info("Device %s has neighbour %s" % (dev_sysname, neighbour))
            neighbour_str = str(neighbour)

            if neighbour_str not in checked_nodes or (dev_name in checked_edges.keys() and neighbour_str not in checked_edges[dev_name]):
                checked_edges[neighbour_str].append(dev_name)
                logger.info("Adding relationship to graph")
                edge = {}
                edge["id"] = len(edges) + 1
                edge["source"] = node.get('id')
                edge["target_name"] = neighbour          # use target_name to set target ID!

                # edge label has format: from-to
                edge_from = interface.get('name')
                edge_to = interface.get('neighbour_port')
                if re.search(regex_ip, edge_to):  # valid IP address, do not include it
                    edge["label"] = edge_from
                else:
                    edge["label"] = edge_from + '-' + edge_to

                edges.append(edge)

                build_vis_graph(devices_json, neighbour, nodes, labels, edges, interface)

def get_root_name(devices_json):
    '''
    Return name of device with the least ID number
    '''
    min_id = sys.maxint
    dev_sysname = ""

    if not devices_json:
        return dev_sysname

    for device in devices_json:
        dev_id = int(devices_json.get(device).get('id'))
        if dev_id < min_id:
            min_id = dev_id
            dev_sysname = devices_json.get(device).get('sysname')

    return dev_sysname

def complete_edges(labels, edges):

    for edge in edges:
        if not "target" in edge:
            dev_sysname = edge.get('target_name')
            if dev_sysname:
                dev_id = labels.get(dev_sysname)

                if dev_id:
                    edge["target"] = int(dev_id)

def visualize_graph(wr_network_json, root_name):
    nodes = []
    edges = []
    labels = {}

    build_vis_graph(wr_network_json, root_name, nodes, labels, edges)
    complete_edges(labels, edges)

    vis_graph = {}
    vis_graph["n_nodes"] = str(len(nodes))
    vis_graph["n_edges"] = str(len(edges))
    vis_graph["nodes"] = nodes
    vis_graph["edges"] = edges

    return vis_graph

if __name__ == "__main__":
    # Fallback values
    defaultLogfile = getenv('LOGFILE', None)
    defaultInfile = getenv('INFILE', 'wr_topology.json')
    defaultOutfile = getenv('OUTFILE', 'graph.json')

    # Parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--infile", default=defaultInfile,
                        help="JSON file with WR network topology (default: %s)" % defaultInfile)
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
    devices_json = get_object_from_file(args.infile)
    if not devices_json:
        logger.error("No JSON found in %s. Giving up." % args.infile)
        sys.exit(1)

    dev_name = get_root_name(devices_json)

    if dev_name:
        build_vis_graph(devices_json, dev_name, nodes, labels, edges)
        complete_edges(labels, edges)

        vis_graph["n_nodes"] = str(len(nodes))
        vis_graph["n_edges"] = str(len(edges))
        vis_graph["nodes"] = nodes
        vis_graph["edges"] = edges

        with open(args.outfile, 'w') as f:
            json.dump(vis_graph, f, sort_keys=True, indent=4, separators=(',', ': '))
    else:
        logger.error("Root device not found! Nothing done")
        sys.exit(2)

