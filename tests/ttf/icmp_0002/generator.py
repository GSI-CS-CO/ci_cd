#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time

########################################################################################################################
def func_generate_test_configuration():
    devices=0
    interval=0.5
    count=1000
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            f = open("test_configuration.sh", "w")

            # Write IP addresses
            f.write("declare -a devices=(")
            for p in data:
                for q in p['receivers']:
                    f.write("%s " % q['iptg'])
                    devices=devices+1
            f.write(")\n")

            # Write individual interval
            f.write("declare -a interval=(")
            for x in range(devices):
                f.write("%s " % interval)
            f.write(")\n")

            # Write individual count
            f.write("declare -a count=(")
            for x in range(devices):
                f.write("%s " % count)
            f.write(")\n")

            f.close()
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

########################################################################################################################
def main():
    func_generate_test_configuration()

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
