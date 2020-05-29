#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time
import getopt
import random

########################################################################################################################
v_fixed_min_count = 1 # Don't edit this
v_fixed_min_interval = 0.2 # Don't edit this

########################################################################################################################
v_min_interval = v_fixed_min_interval
v_max_count = v_fixed_min_count
v_max_size = 56
v_para_count = 1
v_random_mode = 0
v_host_mode = 0
v_verbose = 0

########################################################################################################################
def func_print_help():
    print("TBD -> Help")

########################################################################################################################
def func_generate_test_configuration():
    devices=0
    random_count=v_fixed_min_count
    random_interval=v_fixed_min_interval
    random.seed(1)

    # Parse devices file
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            f = open("test_configuration.sh", "w")

            # Write IP addresses
            f.write("declare -a devices=(")
            for p in data:
                for q in p['receivers']:
                    for i in range(v_para_count):
                        if v_host_mode == 0:
                            f.write("%s " % q['iptg'])
                        else:
                            f.write("%s%s " % (p['name'], p['extension']))
                        devices=devices+1
            f.write(")\n")

            # Write individual interval
            f.write("declare -a interval=(")
            for x in range(devices):
                for i in range(v_para_count):
                    if v_random_mode == 0:
                        f.write("%s " % v_min_interval)
                    else:
                        random_interval = random.uniform(v_fixed_min_interval, float(v_min_interval))
                        f.write("%s " % str(random_interval))
            f.write(")\n")

            # Write individual count
            f.write("declare -a count=(")
            for x in range(devices):
                for i in range(v_para_count):
                    if v_random_mode == 0:
                        f.write("%s " % v_max_count)
                    else:
                        random_count = random.randint(v_fixed_min_count, int(v_max_count))
                        f.write("%s " % str(random_count))
            f.write(")\n")

            # Write individual count
            f.write("declare -a size=(")
            for x in range(devices):
                for i in range(v_para_count):
                    f.write("%s " % v_max_size)
            f.write(")\n")

            f.close()
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

########################################################################################################################
def main():
    global v_min_interval
    global v_max_count
    global v_max_size
    global v_para_count
    global v_random_mode
    global v_host_mode
    global v_verbose
    v_print_help = 0

    # Get arguments
    try:
        opts, args = getopt.getopt(sys.argv[1:], "c:i:s:p:xthv", ["v_max_count=", "v_min_interval=", "v_max_size=", "v_para_count=", "v_random_mode", "v_host_mode", "help", "verbose"])
    except getopt.GetoptError, err:
        print(err)
        sys.exit(1)

    for opt, args in opts:
        if opt in ('-c'):
            v_max_count = args
        elif opt in ('-i'):
            v_min_interval = args
        elif opt in ('-s'):
            v_max_size = arg
        elif opt in ('-p'):
            v_para_count = int(args)
        elif opt in ('-x'):
            v_random_mode = 1
        elif opt in ('-t'):
            v_host_mode = 1
        elif opt in ('-v'):
            v_verbose = 1
        else:
            v_print_help = 1

    # Print help (if wanted) or ...
    if v_print_help != 0:
        func_print_help()
    # ... generate test test configuration
    else:
        print("Generating test configuration...")
        if v_verbose != 0:
            print("Parameters:")
            print("-- Packet count (max): %s" % str(v_max_count))
            print("-- Interval (min): %s" % str(v_min_interval))
            print("-- Packet size (max): %s" % str(v_max_size))
            print("-- Parallel processes: %s" % str(v_para_count))
            print("-- Random mode: %s" % str(v_random_mode))
            print("-- Scan hosts: %s" % str(v_host_mode))
        func_generate_test_configuration()

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
