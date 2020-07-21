#!/usr/bin/env python

# Script: parse_json_file.py
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   Jan 17, 2020

# Description: This script is used to create an *.conf file with WR switch names
# by parsing an user provided JSON file commonly used in GSI Timing TTF.
# The name of output *.conf file is specified in the 'out_file' variable.

# Usage: python parse_json_file.py json_file
# Example: python parse_json_file switches.json

########################################################################################################################
import os
import sys
import json

########################################################################################################################
out_file = 'switches.conf'
l_all_lines = []

########################################################################################################################
def func_get_switches(switches_dot_json):
    # Vars
    global l_all_lines

    # Try to find all kinds of nodes
    try:
        with open(switches_dot_json) as json_file:
            data = json.load(json_file)
            for p in data:
                print_line = "%s%s\n" % (p['name'], p['extension'])
                l_all_lines.append(print_line)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

########################################################################################################################
def func_create_dot_conf(file_name):
    # Vars
    global l_all_lines

    # Write file
    cfgfile = open(file_name, 'w+')
    for x in l_all_lines:
        cfgfile.write(x)
    cfgfile.close()

########################################################################################################################
def main():

    # Check CLI arguments
    if len(sys.argv) != 2:
        print "Usage: python parse_json_file.py json_file"
        sys.exit(1)

    # Get switches
    func_get_switches(sys.argv[1])

    # Create switches dot conf file
    func_create_dot_conf(out_file)

    # Done
    print "Success! Created %s file!" % (out_file)
    exit(0)

# Main
if __name__ == "__main__":
    main()
