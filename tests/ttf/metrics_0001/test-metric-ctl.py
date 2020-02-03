#!/usr/bin/env python

# Script: test-metric-ctl.py
# Author: Enkhbold Ochirsuren, GSI Helmholtz Centre for Heavy Ion Research GmbH
# Date:   Jan 17, 2020

# Description: This script is used to monitor certain metrics from
# timing receivers located in the GSI TTF.
# If the script should be launched in a different host (not the same host with
# Graphite), then user can easily specify/change the default Graphite host
# in the 'host' entry of the 'graphite.conf' configuration file.

# Usage: python test-metric-ctl.py <command> <device>
# - command : control commands (start, stop)
# - device  : timing receivers (scu2, scu3, pexarria5, exploder5, pmc, vetar2a)
#
# Example: python test-metric-ctl.py start scu3

# Note: Since the timing metrics are obtained from remote timing receivers via
# SSH access, please ensure that your SSH key has been added into the SSH
# authentication agent (ie., on your local host invoke: ssh-add ~/.ssh/id_rsa).

########################################################################################################################
import os
import subprocess
import sys
import json
import time
import socket
import atexit

########################################################################################################################
v_debug = 0
v_target = "none"
v_operation = "none"

v_graphite_conf = "graphite.conf"
v_host = "127.0.0.1"
v_port = 2003
v_interval_seconds = 60
v_graphite_addr = (v_host, v_port)
v_graphite_prefix = "ttf"
v_devices_json = "../devices.json" # configuration file with test devices

# metrics (metric_name:metric_key_for_graphite)
# metric_name: temp = FPGA temperature, offset = difference between TAI and UTC,
#              sync = WR sync status, temp1w = board temperature (1-wire sensor),
v_metrics = {"temp":"temp", "offset":"offset", "sync":"sync", "temp1w":"temp1w"}
v_msg_graphite = ""
v_msg_timeout_ssh = "Failed: SSH access to target might be timed out at password prompt. \
    \nYou may need to invoke 'ssh-add ~/.ssh/id_rsa' to add SSH key into ssh-agent!"
v_sync_map = """[{ "status": "TRACKING", "value": "100"},
                 { "status": "NO SYNC",  "value": "20"}]"""
# boards with 1-wire temperature sensor (board:family_code)
v_1w_boards = {"scu2":"0x42", "scu3":"0x42", "exploder5":"0x28", "pexarria5":"0x28"}

########################################################################################################################
def func_print_space():
    print "----------------------------------------------------------------------------------------------------"

########################################################################################################################
def func_is_int(string):
    try:
        num = int(string)
    except ValueError:
        return False
    return True

########################################################################################################################
def func_is_float(string):
    try:
        num = float(string)
    except ValueError:
        return False
    return True

########################################################################################################################
def func_create_pidfile():
    # Create a file with current process id
    pid = str(os.getpid())
    pidfile = "/tmp/%s.%s.pid" % (sys.argv[0], v_target)
    with open(pidfile, 'w') as file:
        file.write(pid)

########################################################################################################################
def func_delete_pidfile():
    # Delete a file, which holds an id of metric polling process
    pidfile = "/tmp/%s.%s.pid" % (sys.argv[0], v_target)
    if os.path.isfile(pidfile):
        os.unlink(pidfile)

########################################################################################################################
def func_read_pidfile():
    # Read an id of metric polling process
    pid = ""
    pidfile = "/tmp/%s.%s.pid" % (sys.argv[0], v_target)
    if os.path.isfile(pidfile):
        with open(pidfile, 'r') as file:
            pid = file.read()
    return pid

########################################################################################################################
def func_numeric_sync(text):
    # Map the state of the WR sync status into numeric value
    # Undefined sync status has value of "0"
    value = "0"
    global v_sync_map

    for item in v_sync_map:
        if item['status'] == text:
            value = item['value']
            break

    return value

########################################################################################################################
def func_build_graphite_metric(cmd_output, metric_key, timestamp):
    # metric_key: timing metric key (temp, offset, sync etc)
    # cmd_output: output message from timing tool (eb-mon, saft-ctl)
    # returns: a list with graphite compatible metric strings
    metric_list = []
    key_parts = metric_key.rpartition('.'); # [host.domain, ".", metrics]
    if v_metrics['temp'] == key_parts[2]:
        # cmd_output depends on device capability and can be one of followings:
        # - current temperature (Celsius): 56
        # - no temperature sensor is available in this device!
        if "(Celsius):" in cmd_output:
            value = cmd_output.partition("(Celsius):")[2].strip()
            metric = "%s %s %s" % (metric_key, value, timestamp)
            metric_list.append(metric)
    elif key_parts[2]:
        # metric_key can contain more keys, such as "offset:sync:temp1w" or "offset:sync"
        keys = key_parts[2]
        values = cmd_output.split('\n')  # ["37000" , "TRACKING", "34.5678"]
        for value in values:
            if func_is_int(value) and v_metrics['offset'] in keys:
                # get offset value
                metric = "%s %s %s" % (key_parts[0] + key_parts[1] + v_metrics['offset'], str(value), timestamp)
                metric_list.append(metric)
                # remove the key to avoid re-use
                keys = keys.replace(v_metrics['offset'], " ")
            elif func_is_float(value) and v_metrics['temp1w'] in key_parts[2]:
                # get board temperature value
                metric = "%s %s %s" % (key_parts[0] + key_parts[1] + v_metrics['temp1w'], str(value), timestamp)
                metric_list.append(metric)
                # remove the key to avoid re-use
                keys = keys.replace(v_metrics['temp1w'], "")
            elif value and v_metrics['sync'] in key_parts[2]:
                # get sync value
                val = func_numeric_sync(value)
                if val:
                    metric = "%s %s %s" % (key_parts[0] + key_parts[1] + v_metrics['sync'], val, timestamp)
                    metric_list.append(metric)
                    # remove the key to avoid re-use
                    keys = keys.replace(v_metrics['sync'], "")
    return metric_list

########################################################################################################################
def func_send_metric(metric_list):
    # send metric set through UDP socket (on remote side run 'nc -ulk <v_port>' to check socket transmission)
    for i in range(len(metric_list)):
        v_sock.sendto(metric_list[i], v_graphite_addr)

########################################################################################################################
def func_get_1w_bus(login_to_host, slot):
    try:
        idx = ""
        cmd = "timeout 5 ssh %s eb-ls %s | grep User-1Wire" % (login_to_host, slot)
        output = subprocess.check_output(cmd.split(), stderr=subprocess.STDOUT)
        if output:
            idx = output.split(".")[0]
        return idx

    except subprocess.CalledProcessError as e:
        if e.returncode == 124: # timed out
            print v_msg_timeout_ssh

        print e

########################################################################################################################
def func_find_option(login_to_host, opt_key):
    try:
        timing_tool = "eb-mon"

        if opt_key == "temperature":
            timing_tool = "saft-ctl"

        cmd = "timeout 10 ssh %s %s -h" % (login_to_host, timing_tool)
        output = subprocess.check_output(cmd.split(), stderr=subprocess.STDOUT)
        if output:
            lines = output.split('\n')
            for line in lines:
                if opt_key in line:
                    opt = line.split()[0].strip()
                    return opt

    except subprocess.CalledProcessError as e:
        if e.returncode == 124: # timed out
            print v_msg_timeout_ssh

        print e

########################################################################################################################
def func_start_poll():
    # Poll metric periodically (temperature, offset, sync etc)
    cmd_list = []
    test_target = "" # fill it to test with a developer local device: <user>@<host.domain>

    # Build strings with metric key and polling command (either test device or devices in facility)
    if "@" in test_target:
        # Build a header of metric key with "test.host"
        m_head = "test.%s" % (test_target.partition('@')[2].split('.')[0])

        # Build a string with metric key and polling command
        # - FPGA temperature
        cmd = "%s.%s timeout 10 ssh %s saft-ctl -ft bla" % (m_head, v_metrics['temp'], test_target)
        cmd_list.append(cmd)

        # Multiple metrics are obtained with single command 'eb-mon'
        # - offset (-o)
        opts = "-o"
        metric_key = v_metrics['offset']
        # - WR sync (-y or -z, find a valid option to get the WR sync status because the option varies for eb-mon)
        sync_opt = func_find_option(test_target, "sync")
        # - board temperature (-t<bus_idx> -f<family>)
        temp_1w_opt = ""
        # Get board temperature if 1-wire temperature sensor is available in target
        if v_target in v_1w_boards:
            bus_idx = func_get_1w_bus(test_target, "dev/wbm0")
            if bus_idx:
                temp_1w_opt = "-t%s -f%s" % (bus_idx, v_1w_boards[v_target])
        if sync_opt:
            opts += " " + sync_opt
            metric_key += ":" + v_metrics['sync']
        if temp_1w_opt:
            opts += " " + temp_1w_opt
            metric_key += ":" + v_metrics['temp1w']
        cmd = "%s.%s timeout 10 ssh %s eb-mon dev/wbm0 %s" % (m_head, metric_key, test_target, opts)
        cmd_list.append(cmd)
    else:
        try:
            with open(v_devices_json) as json_file:
                data = json.load(json_file)
                for p in data:
                    for q in p['receivers']:
                        if (v_target == str(q['type'])) or (v_target == "all"):
                            login_to_host = p['login'] + "@" + p['name'] + p['extension']
                            # Build a header of metric key  with "prefix.host.dev.type.role"
                            m_head = "%s.%s.%s.%s.%s" % (v_graphite_prefix, p['name'], q['dev_name'], q['type'], q['role'])
                            # Build a string with metric key and polling command
                            cmd = "%s.%s timeout 10 ssh %s saft-ctl -t %s" % (m_head, v_metrics['temp'], login_to_host, q['dev_name'])
                            cmd_list.append(cmd)

                            # Multiple metrics are obtained with single command 'eb-mon'
                            # - offset (-o)
                            opts = "-o"
                            metric_key = v_metrics['offset']
                            # - WR sync (-y or -z, find a valid option to get the WR sync status because the option varies for eb-mon)
                            sync_opt = func_find_option(login_to_host, "sync")
                            # - board temperature (-t<bus_idx> -f<family>)
                            temp_1w_opt = ""
                            # Get board temperature if 1-wire temperature sensor is available in target
                            if v_target in v_1w_boards:
                                bus_idx = func_get_1w_bus(login_to_host, q['slot'])
                                if bus_idx:
                                    temp_1w_opt = "-t%s -f%s" % (bus_idx, v_1w_boards[v_target])
                            if sync_opt:
                                opts += " " + sync_opt
                                metric_key += ":" + v_metrics['sync']
                            if temp_1w_opt:
                                opts += " " + temp_1w_opt
                                metric_key += ":" + v_metrics['temp1w']
                            cmd = "%s.%s timeout 10 ssh %s eb-mon %s %s" % (m_head, metric_key, login_to_host, q['slot'], opts)
                            cmd_list.append(cmd)

        except (ValueError, KeyError, TypeError):
            print "JSON format error"

        if len(cmd_list) == 0:
            print "Failed: %s target not found in %s. Exit!" % (v_target, v_devices_json)
            return

    # Print metric keys with corresponding polling commands
    for entry in cmd_list:
        print entry
        func_print_space()

    print v_msg_graphite

    # Periodic metric polling and forwarding them to Graphite host
    if v_debug == 0:

        # Create a file that holds the current process id
        func_create_pidfile()

        while True:
            metric_list = []

            for i in range(len(cmd_list)):
                # Get metric key from a string
                metric_key = cmd_list[i].split()[0]
                # Get polling command from a string
                cmd = cmd_list[i].partition(metric_key)[2].strip()
                # Get timestamp
                ts = str(int(time.time()))

                # Call polling command and evaluate its output to get a metric value
                try:
                    # System call with polling command
                    cmd_output = subprocess.check_output(cmd.split(), stderr=subprocess.STDOUT)

                    # Evaluate command output and build Graphite compatible metric strings (metric_key metric_value timestamp)
                    str_list = func_build_graphite_metric(cmd_output, metric_key, ts)

                    for string in str_list:
                        metric_list.append(string)

                except subprocess.CalledProcessError as e:
                    if e.returncode == 124: # timed out
                        print v_msg_timeout_ssh

                    print "Failed (%d): %s -- %s" % (e.returncode, e.output, e.cmd)

            # Send metrics to Graphite host
            if metric_list:
                func_send_metric(metric_list)

            # Make pause and repeat it again
            time.sleep(v_interval_seconds)

########################################################################################################################
def func_stop_poll():
    # Find and terminate a running process that polls timing metric

    pid = func_read_pidfile()
    if pid:
        # Kill a process with pid only if its command contains the name of this script and timing target type
        ps_cmd = "ps -fo cmd --no-headers --pid %s" % pid
        print "Find a process with PID: %s" % pid
        try:
            cmd_out = subprocess.check_output(ps_cmd.split(), stderr = subprocess.STDOUT)
            if sys.argv[0] in cmd_out and v_target in cmd_out:
                kill_cmd = "kill -9 %s" % pid
                print "Terminate a process with PID: %s" % pid
                try:
                    subprocess.call(kill_cmd.split())
                    print "Stopped metric polling for target type: %s" % v_target
                    func_delete_pidfile()
                except subprocess.CalledProcessError as e:
                    print e
            else:
                print "Check a process with PID: %s" % pid
                print "It could be an unrelated process: %s" % cmd_out
        except subprocess.CalledProcessError as e:
            if e.returncode == 1:
                print "No process found with PID: %s" % pid
                print "Probably outdated pid file in: %s" % pidfile
                print "Delete pid file after manual check."
            else:
                print e
    else:
        print "No process (metric polling) found: try with 'ps -eo pid,cmd | grep \"python %s\"'" % sys.argv[0]

########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)
    global v_target
    global v_operation
    global v_host
    global v_port
    global v_sock
    global v_graphite_addr
    global v_interval_seconds
    global v_graphite_prefix
    global v_msg_graphite
    global v_sync_map

    # Plausibility check
    try:
        if cmdtotal == 2:
            v_operation = str(sys.argv[1])
        elif cmdtotal == 3:
            v_operation = str(sys.argv[1])
            v_target = str(sys.argv[2])
        else:
            print "Error: Please provide operation: start target, stop target"
            print "Targets: all scu2 scu3 pexarria5 exploder5 microtca pmc vetar2a vetar2a-ee-butis ftm"
            exit(1)
        try:
            if os.path.exists(v_graphite_conf):
                with open(v_graphite_conf) as file:
                    obj = json.load(file)
                    if "host" in obj:
                        v_host = obj['host']
                    if "port" in obj:
                        v_port = obj['port']
                    if "interval" in obj:
                        v_interval_seconds = obj['interval']
                    if "prefix" in obj:
                        v_graphite_prefix = obj['prefix']
                    if "sync_map" in obj:
                        v_sync_map = obj['sync_map']

            v_msg_graphite = "send TR metrics to %s:%d (host:port) every %d seconds" % (v_host, v_port, v_interval_seconds)
        except (ValueError, KeyError, TypeError):
            print "JSON formar error: %s " % (file)

        v_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        v_graphite_addr = (v_host, v_port)

    except:
        print "Error: Could not parse given arguments!"
        exit(1)

    # Perform operation
    if v_operation == "start":
        func_start_poll()
    elif v_operation == "stop":
        func_stop_poll()
    else:
        print "Error: Ambiguous arguments!"
        exit(1)

    # Done
    func_delete_pidfile()
    exit(0)

# Main
if __name__ == "__main__":
    main()
