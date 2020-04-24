#!/usr/bin/env python
# Apply the current WR status (PTP servo, PTP instances) into a timing
# network topology (JSON) created by the CERN LLDP topology discovery tool

# Usage: python wrs.py -i topology.json

import sys
import json
import argparse
from os import getenv
import logging

import snmp
import binascii
import socket

from graph import get_object_from_file, get_object_from_stdin
from device import domain

# Logging config, by default log to stderr
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
logger = logging.getLogger()
logger.addHandler(ch)

def apply_wr_status(devicelist, oid):
    '''
    Return devicelist extended with the current WR status (PTP servo, PTP instances)
    '''
    if not devicelist:
        logger.error("Device list empty.")
        return None

    if not oid:
        logger.error("OID is empty.")
        return None

    wrdevicelist = devicelist

    for name in wrdevicelist.keys():
        if wrdevicelist.get(name).get('if') is not None:
            wrswitch = wrdevicelist.get(name)        # get switch object: "nwt0099m66" : { ... }
            wrswitchname = name + domain             # add GSI timing domain: "nwt0099m66.timing"

            # get the PTP servo state (numeric and string)
            oid_ptpservo_n = str(oid['wr']['ptpservostaten'])
            try:
                ptpservo = snmp.Connection(wrswitchname).walk(oid_ptpservo_n) # dictionary { 'oid_ptpservo_n' : 'n' }
                if ptpservo is not None:
                    for k, v in ptpservo.items():
                        value = v
                    wrswitch[unicode('ptp_servo_n')] = unicode(value)
            except:  # if could not resolve host, then re-raise
                raise

            oid_ptpservo = str(oid['wr']['ptpservostate'])
            ptpservo = snmp.Connection(wrswitchname).walk(oid_ptpservo) # dictionary { 'oid_ptpservo' : 'state' }
            if ptpservo is not None:
                for k, v in ptpservo.items():
                    value = v
                wrswitch[unicode('ptp_servo')] = unicode(value)

            # get the PTP state of all WR ports
            ptpstate = snmp.Connection(wrswitchname).walk(oid['wr']['ptpinststate']) # dictionary { 'oid_ptpstate': 'state', ... }

            # assign the PTP state to WR switch interface
            # mapping of ptpstate to a proper switch interface is done based on the PTP port name (wriX)
            # get the PTP port name of all WR ports
            ptpportname = snmp.Connection(wrswitchname).walk(oid['wr']['ptpinstportname'])   # dictionary { 'oid_portname': 'name', ... }

            # add 'ptp_state' entry into WR switch interfaces
            # PTP state is unavailable in case of: release v4.2, non-WR ports (eth0)
            if ptpstate is not None:
                for oid_ptpstate in ptpstate.keys():
                    oid_portname = str(oid_ptpstate.replace(oid['wr']['ptpinststate'], oid['wr']['ptpinstportname']))
                    portname = ptpportname[oid_portname]
                    for iface in wrswitch['if']:
                        if 'name' in iface and iface['name'] == portname:
                            iface[unicode('ptp_state')] = unicode(ptpstate[oid_ptpstate])
                            break

    return wrdevicelist # return device list extended with the WR status

if __name__ == "__main__":
    # Fallback values
    defaultInfofile = getenv('INFOFILE', 'info.json')
    defaultLogfile = getenv('LOGFILE', None)
    defaultOutfile = getenv('OUTFILE', 'wr_topology.json')
    defaultOidfile = getenv('OIDFILE', 'oid.json')

    # Parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "-f", "--infofile", default=defaultInfofile,
                        help="File to read info about devices from (default: %s or stdin)" % defaultInfofile)
    parser.add_argument("-t", "--outfile", default=defaultOutfile,
                        help="File to write to (default: %s)" % defaultOutfile)
    parser.add_argument("-o", "--oidfile", default=defaultOidfile,
                        help="JSON file containing SNMP OIDs (default: oid.json)")
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
        sys.exit(1)

    oid = get_object_from_file(args.oidfile)
    if not oid:
        logger.error("No JSON found in %s. Exit." % args.oidfile)
        sys.exit(2)

    wrdevicelist = apply_wr_status(devicelist, oid)

    with open(args.outfile, 'w') as f:
        json.dump(wrdevicelist, f, sort_keys=False, indent=4, separators=(',', ': '))
