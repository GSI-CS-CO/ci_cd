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

    # Create config file for each type
    func_get_node_types(ver)
    for x in l_types:
        for i in range(len(l_dev_types)):
            if l_dev_types[i] == x:
                print_line = "object Host \"wrn_%s_%s\" {\n" % (l_dev_nodes[i], l_dev_roles[i])
                l_all_lines.append(print_line)
                print_line = "        address = \"%s\"\n" % (l_dev_ips[i])
                l_all_lines.append(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                print_line = "        groups = [ \"nodes\" ]\n"
                l_all_lines.append(print_line)
                l_all_lines.append("}\n\n")

########################################################################################################################
def func_get_switches(ver):
    # Vars
    global l_all_lines

    # Try to find all kinds of nodes
    try:
        with open('../../switches.json') as json_file:
            data = json.load(json_file)
            for p in data:
                print_line = "object Host \"wrs_%s_%s\" {\n" % (p['name'], p['role'])
                l_all_lines.append(print_line)
                print_line = "        address = \"%s\"\n" % (p['ip'])
                l_all_lines.append(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                print_line = "        groups = [ \"switches\" ]\n"
                l_all_lines.append(print_line)
                l_all_lines.append("}\n\n")
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

########################################################################################################################
def func_get_chassis(ver):
    # Vars
    global l_all_lines

    # Try to find all kinds of nodes
    try:
        with open('../../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                print_line = "object Host \"host_%s\" {\n" % (p['name'])
                l_all_lines.append(print_line)
                print_line = "        address = \"%s%s\"\n" % (p['name'], p['extension'])
                l_all_lines.append(print_line)
                print_line = "        check_command = \"hostalive\"\n"
                l_all_lines.append(print_line)
                print_line = "        groups = [ \"chassis\" ]\n"
                l_all_lines.append(print_line)
                l_all_lines.append("}\n\n")
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

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
def func_create_groups_dot_conf(ver):
    # Write file
    file_name = "groups.conf"
    cfgfile = open(file_name, 'w+')
    cfgfile.write("object HostGroup \"switches\" {\n")
    cfgfile.write("        display_name = \"White Rabbit Switches\"\n")
    cfgfile.write("}\n\n")
    cfgfile.write("object HostGroup \"nodes\" {\n")
    cfgfile.write("        display_name = \"White Rabbit Nodes (Timing Receivers)\"\n")
    cfgfile.write("}\n\n")
    cfgfile.write("object HostGroup \"chassis\" {\n")
    cfgfile.write("        display_name = \"Timing Receiver Chassis (Hosts)\"\n")
    cfgfile.write("}\n\n")
    cfgfile.close()

########################################################################################################################
def main():
    # Get nodes
    func_get_nodes(0)

    # Get switches
    func_get_switches(0)

    # Get hosts
    func_get_chassis(0)

    # Create files
    func_create_hosts_dot_conf(0)
    func_create_groups_dot_conf(0)

    # Done
    print "Success! Created all dot conf files!"
    exit(0)

# Main
if __name__ == "__main__":
    main()
