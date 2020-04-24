#!/usr/bin/env python
import logging
import sys
import json
import threading
import Queue
import argparse
from os import getenv
from time import time
import device

# Logging config, by default log to stderr
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
logger = logging.getLogger()
logger.addHandler(ch)

class InfoWorker(threading.Thread):
    def __init__(self, jobQueue, outputQueue):
        threading.Thread.__init__(self)
        self.jobQueue = jobQueue
        self.outputQueue = outputQueue

    def run(self):
        while True:
            try:
                job = self.jobQueue.get()
            except Queue.Empty:
                break
            c = {"sysname": job['hostname'], "id": job['id']}
            d = device.Device(job['hostname'])
            try:
                reachable = d.snmpConfig(job['oid'], job['snmpVersion'], job['snmpCommunity'], test=True)
            except:
                reachable = False
            if reachable:
                c.update(d.getDeviceInfo())
            self.outputQueue.put({job['hostname']: c})
            self.jobQueue.task_done()

def build_topology(oid_file, device_list, out_file):
    ''' Build network topology.
    An input list contains network devices.
    SNMP requests to all network devices are sent via queue.
    A network topology with additional system info is built based on
    the SNMP response and stored in the given JSON file.
    '''
    # Load OID data
    with open(oid_file) as oidlist:
        oid = json.load(oidlist)

    # SNMP request and response
    community = 'public'
    workers = 100
    snmp_version = 2
    request_q = Queue.Queue()
    response_q = Queue.Queue()

    # Populate job queue (hostname index in device_list is used as 'id' here)
    for hostname in device_list:
        request_q.put({'hostname': hostname, 'id': str(device_list.index(hostname)),
                  'oid': oid, 'snmpVersion': snmp_version, 'snmpCommunity': community})

    # Start threads
    for i in range(min(workers, len(device_list))):
        w = InfoWorker(request_q, response_q)
        w.daemon = True
        w.start()

    # Wait for workers to complete
    request_q.join()

    devices = {}
    # Build a list out of output queue
    try:
        while True:
            devices.update(response_q.get_nowait())
    except Queue.Empty:
        pass

    with open(out_file, 'w') as f:
        json.dumps(devices, sort_keys=True, indent=4, separators=(',', ': '))

if __name__ == "__main__":
    # Benchmarking performance
    startTime = time()

    # Fallback values
    defaultCommunity = getenv('SNMPCOMMUNITY', 'public')
    defaultLogfile = getenv('LOGFILE', None)
    defaultOidfile = getenv('OIDFILE', 'oid.json')
    defaultWorkers = getenv('WORKERS', 100)
    snmpVersion = 2

    # Command line option parsing and help text (-h)
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--inputfile",
                        help="File to read list of devices from (defaults to reading from stdin)")
    parser.add_argument("-c", "--community", default=defaultCommunity,
                        help="SNMP community (default: %s)" % defaultCommunity)
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Do not display or log errors")
    parser.add_argument("-l", "--logfile", default=defaultLogfile,
                        help="Log file (default is logging to STDERR)")
    parser.add_argument("-v", "--verbose", action="count", default=0,
                        help="Increase verbosity when using logfile.")
    parser.add_argument("-o", "--oidfile", default=defaultOidfile,
                        help="JSON file containing SNMP OIDs (default: %s)" % defaultOidfile)
    parser.add_argument("-w", "--workers", default=defaultWorkers,
                        help="Number of threads to spawn (default: %s)" % defaultWorkers)
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
    inputlist = []
    devices = {}
    inputtext = None
    jobQ = Queue.Queue()
    resultQ = Queue.Queue()

    # Load OID data
    with open(args.oidfile) as oidlist:
        oid = json.load(oidlist)

    if args.inputfile:
        try:
            with open(args.inputfile) as f:
                inputtext = f.read()
        except IOError:
            logger.error("Could not read from file %s" % args.inputfile)

    if not inputtext:
        if sys.stdin.isatty():
            logger.debug("Detected TTY at STDIN.")
            logger.error("Reading list of devices from STDIN. Press ^D when done, or ^C to quit.")
        inputtext = "".join(sys.stdin)

    logger.info(inputtext)
    try:
        inputlist = json.loads(inputtext)
    except ValueError:
        logger.error("No valid JSON detected in input")
        inputlist = inputtext.split()

    mainLoopStartTime = time()

    # Populate job queue (hostname index in inputlist is used as 'id' here)
    for hostname in inputlist:
        jobQ.put({'hostname': hostname, 'id': str(inputlist.index(hostname)), 'oid': oid, 'snmpVersion': snmpVersion, 'snmpCommunity': args.community})

    # Start threads
    for i in range(min(args.workers, len(inputlist))):
        w = InfoWorker(jobQ, resultQ)
        w.daemon = True
        w.start()

    # Wait for workers to complete
    jobQ.join()

    # Build a list out of output queue
    try:
        while True:
            devices.update(resultQ.get_nowait())
    except Queue.Empty:
        pass

    logger.debug("Time spent in main loop: %s" % (time() - mainLoopStartTime))

    print(json.dumps(devices, sort_keys=False, indent=4, separators=(',', ': ')))
    logger.debug("Time spent in program: %s" % (time() - startTime))
