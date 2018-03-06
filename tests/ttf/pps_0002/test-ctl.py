#!/usr/bin/env python

########################################################################################################################
import os
import subprocess
import sys
import json
import time

########################################################################################################################
v_data_master = ""
v_data_master_alias = ""
v_operation = "none"
v_debug = 0

########################################################################################################################
def func_start():
    # Start data master
    print "Starting data master..."
    cmd = "timeout 30 dm-sched %s %s" % (v_data_master, "status")
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-sched %s %s" % (v_data_master, "clear")
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-sched %s add -s pps.dot" % (v_data_master)
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-cmd %s %s %s" % (v_data_master, "status", "| grep \"WR-Time: 0x\"")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    (out, err) = proc.communicate()
    data = out.split()
    v_start_time = data[5]
    cmd = "timeout 30 dm-cmd %s origin -c 0 CPU0_START" % (v_data_master)
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-cmd %s -c 0 -t 0 starttime %s" % (v_data_master, v_start_time)
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-cmd %s start -c 0" % (v_data_master)
    subprocess.call(cmd.split())

########################################################################################################################
def func_stop():
    # Start data master
    print "Stopping data master..."
    cmd = "timeout 30 dm-cmd %s abort" % (v_data_master)
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-sched %s %s" % (v_data_master, "clear")
    subprocess.call(cmd.split())
    cmd = "timeout 30 dm-sched %s %s" % (v_data_master, "status")
    subprocess.call(cmd.split())

########################################################################################################################
def func_init():
    # Start saft-pps-gen
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        cmd = "nohup ssh %s@%s%s saft-pps-gen %s -s -e >> /dev/null &" % (p['login'], p['name'], p['extension'], q['dev_name'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def func_deinit():
    # Stop saft-pps-gen
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        cmd = "ssh %s@%s%s killall saft-pps-gen" % (p['login'], p['name'], p['extension'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def func_get_pps_data_master():
    global v_data_master
    global v_data_master_alias
    v_data_master_found = 0
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                saftd_stop_found = 0
                for q in p['receivers']:
                    if ("data_master_pps" == str(q['role'])):
                        v_data_master = "udp/%s" % (str(q['iptg']))
                        v_data_master_alias = str(q['dev_name'])
                        v_data_master_found = 1
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    if (v_data_master_found == 1):
        print "Found data master [%s@%s]!" % (v_data_master_alias, v_data_master)
        return 0
    else:
        print "No data master found!"
        return 1


########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)

    # Plausibility check
    try:
        if cmdtotal == 2:
            v_operation = str(sys.argv[1])
        else:
            print "Error: Please provide operation name [start/stop/init/deinit]"
            exit(1)
    except:
        print "Error: Could not parse given arguments!"
        exit(1)

    # Find PPS data master
    if func_get_pps_data_master() != 0:
        exit(1)

    # Perform operation
    if v_operation == "start":
        func_start()
    elif v_operation == "stop":
        func_stop()
    elif v_operation == "init":
        func_init()
    elif v_operation == "deinit":
        func_deinit()
    else:
        print "Error: Ambiguous arguments!"
        exit(1)

    # Done
    exit(0)

# Main
if __name__ == "__main__":
    main()
