#!/usr/bin/env python
# FreeBSD requirements:
# Compile net-snmp with python bindings

import logging
from json import dumps, load
from argparse import ArgumentParser
from os import getenv
import device

# Logging config, by default log to stderr
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
logger = logging.getLogger()
logger.addHandler(ch)

def gettree(checked, host, trunk="id", branches="children"):
    '''
    returns None if SNMP failed, or a dict with device info and neighbours.
    '''
    # List of devices we've already checked.
    c = {trunk: host}

    try:
        d = device.Device(host)
        d.snmpConfig(oid, snmpVersion, args.community)
    except:
        return c

    neighbours = d.getNeighbours()
    if not neighbours:
        return c

    children = []

    # Have we already checked this device? Loop prevention.
    for x in neighbours.values():
        if x and (x not in checked):
            logger.debug("%s has neighbour %s", host, x)
            # Recurse!
            checked.append(x)
            children.append(gettree(checked, x))
    if children:
        c[branches] = children
    return c

def get_list(host):
    # List of devices we've already checked.
    device_list = []
    device_list.append(host)

    # Recursion
    gettree(device_list, host)

    return device_list

if __name__ == "__main__":
    # Fallback values
    defaultCommunity = getenv('SNMPCOMMUNITY', 'public')
    defaultLogfile = getenv('LOGFILE', None)
    defaultOidfile = getenv('OIDFILE', 'oid.json')
    snmpVersion = 2

    # Command line option parsing and help text (-h)
    usage = "%(prog)s [options] COMMAND HOST"
    parser = ArgumentParser(usage=usage)
    parser.add_argument("command",
                        help="list or tree (default: list)", metavar="COMMAND")
    parser.add_argument("host",
                        help="hostname or IP address", metavar="HOST")
    parser.add_argument("-c", "--community", default=defaultCommunity,
                        help="SNMP community (default: %s)" % defaultCommunity)
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Do not display or log errors")
    parser.add_argument("-l", "--logfile", default=defaultLogfile,
                        help="Log file (Default is logging to STDERR)")
    parser.add_argument("-o", "--oidfile", default=defaultOidfile,
                        help="JSON file containing SNMP OIDs (default: oid.json)")
    args = parser.parse_args()

    # If file name provided for logging, write detailed log.
    if args.logfile:
        fh = logging.FileHandler(args.logfile)
        fh.setLevel(logging.DEBUG)
        logger.addHandler(fh)
    # If quiet mode, disable all logging.
    if args.quiet:
        logger.disabled = True

    # Load OID data
    with open(args.oidfile) as oidlist:
        oid = load(oidlist)

    # List of devices we've already checked.
    checked = []

    checked.append(args.host)
    t = gettree(checked, args.host)
    logger.debug("-1- %s",t)

    if "tree" not in args.command:
        t = checked
    logger.debug("-2- %s",t)

    print(dumps(t, sort_keys=False, indent=4, separators=(',', ': ')))
