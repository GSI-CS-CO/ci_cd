#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import filecmp
import signal
import sys
import glob
import random
from time import gmtime, strftime

########################################################################################################################
l_types = []
l_dev_nodes = []
l_dev_ips = []
l_dev_types = []
l_dev_roles = []
l_all_lines = []

########################################################################################################################
def func_get_node_types(ver):
    # Vars
    global l_types
    global l_dev_nodes
    global l_dev_ips
    global l_dev_types
    global l_dev_roles
    global l_all_lines

    # Try to find all kinds of nodes
    try:
        with open('../../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if any(q['type'] in s for s in l_types):
                        pass
                    else:
                        l_types.append(q['type'])
                    l_dev_nodes.append(q['dev_name'])
                    l_dev_ips.append(q['iptg'])
                    l_dev_types.append(q['type'])
                    l_dev_roles.append(q['role'])
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

    # Show gathered information
    if (ver == 1):
        for x in l_types:
            print x
            for i in range(len(l_dev_types)):
                if l_dev_types[i] == x:
                    print l_dev_nodes[i]
                    print l_dev_ips[i]

########################################################################################################################
def func_get_nodes(ver):
    # Vars
    global l_types
    global l_dev_nodes
    global l_dev_ips
    global l_dev_types
    global l_dev_roles
    global l_all_lines

    func_get_node_types(ver)

    # Create config file for each type
    for x in l_types:
        # Create file
        file_name = "nodes_%s.cfg" % x
        cfgfile = open(file_name, 'w+')

        # Hostgroup
        #cfgfile.write("define hostgroup {\n")
        #print_line =  "        hostgroup_name %s\n" % x
        #cfgfile.write (print_line)
        #print_line =  "        alias %s\n" % x
        #cfgfile.write (print_line)
        #print_line =  "        "
        #cfgfile.write (print_line)
        #members_printed = 0
        #for i in range(len(l_dev_types)):
        #    if l_dev_types[i] == x:
        #        if members_printed == 0:
        #            members_printed = 1
        #            cfgfile.write("members ")
        #        gather_devices = "%s, " % (l_dev_nodes[i])
        #        cfgfile.write(gather_devices)
        #print_line =  "\n        }\n\n"
        #cfgfile.write(print_line)

        # Devices
        for i in range(len(l_dev_types)):
            if l_dev_types[i] == x:
                print_line = "object Host \"wrn_%s_%s\" {\n" % (l_dev_nodes[i], l_dev_roles[i])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        address = \"%s\"\n" % (l_dev_ips[i])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                l_all_lines.append("}\n\n")
                cfgfile.write("}\n\n")
        cfgfile.close()

########################################################################################################################
def func_get_switches(ver):
    # Vars
    global l_all_lines

    # Create file
    file_name = "switches.cfg"
    cfgfile = open(file_name, 'w+')

    # Try to find all kinds of nodes
    try:
        with open('../../switches.json') as json_file:
            data = json.load(json_file)
            for p in data:
                print_line = "object Host \"wrs_%s_%s\" {\n" % (p['name'], p['role'])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        address = \"%s\"\n" % (p['ip'])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                l_all_lines.append("}\n\n")
                cfgfile.write("}\n\n")
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    cfgfile.close()

########################################################################################################################
def func_get_chassis(ver):
    # Vars
    global l_all_lines

    # Create file
    file_name = "chassis.cfg"
    cfgfile = open(file_name, 'w+')

    # Try to find all kinds of nodes
    try:
        with open('../../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                print_line = "object Host \"host_%s\" {\n" % (p['name'])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        address = \"%s%s\"\n" % (p['name'], p['extension'])
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                cfgfile.write(print_line)
                l_all_lines.append("}\n\n")
                cfgfile.write("}\n\n")
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    cfgfile.close()

########################################################################################################################
def func_create_hosts_dot_conf(ver):
    # Vars
    global l_all_lines

    # Write file
    file_name = "hosts.conf"
    cfgfile = open(file_name, 'w+')
    for x in l_all_lines:
        cfgfile.write(x)
    cfgfile.close()

########################################################################################################################
def main():
    # Get nodes
    func_get_nodes(0)

    # Get switches
    func_get_switches(0)

    # Get hosts
    func_get_chassis(0)

    # Done
    func_create_hosts_dot_conf(0)
    exit(0)

# Main
if __name__ == "__main__":
    main()
