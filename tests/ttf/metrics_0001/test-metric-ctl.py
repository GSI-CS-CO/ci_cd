#!/usr/bin/env python

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
v_metrics = {"temp":"temp", "offset":"offset", "sync":"sync", "offsyn":"offsyn"}
v_msg_graphite = ""
v_sync_map = """[{ "status": "TRACKING", "value": "100"},
                 { "status": "NO SYNC",  "value": "20"}]"""

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
    if v_metrics['temp'] in metric_key:
        # cmd_output depends on device capability and can be one of followings:
        # - current temperature (Celsius): 56
        # - no temperature sensor is available in this device!
        if "(Celsius):" in cmd_output:
            value = cmd_output.partition("(Celsius):")[2].strip()
            metric = "%s %s %s" % (metric_key, value, timestamp)
            metric_list.append(metric)
    elif v_metrics['offset'] in metric_key:
        # cmd_output has only a numeric value: 36999 or 37000
        if cmd_output:
            value = str(cmd_output).rstrip('\n')
            metric = "%s %s %s" % (metric_key, value, timestamp)
            metric_list.append(metric)
    elif v_metrics['sync'] in metric_key:
        # cmd_output has the WR sync status in text: TRACKING | NO SYNC | TIME | PPS
        if cmd_output:
            # Map text to numeric value
            value = func_numeric_sync(cmd_output)
            if value:
                metric = "%s %s %s" % (metric_key, value, timestamp)
                metric_list.append(metric)
    elif v_metrics['offsyn'] in metric_key:
        # cmd_output has values of "offset" and "sync" metrics
        values = cmd_output.split('\n')
        for value in values:
            if func_is_int(value):
                # offset
                metric = "%s %s %s" % (metric_key.replace(v_metrics['offsyn'], v_metrics['offset']), str(value), timestamp)
                metric_list.append(metric)
            elif value:
                # sync
                val = func_numeric_sync(value)
                if val:
                    metric = "%s %s %s" % (metric_key.replace(v_metrics['offsyn'], v_metrics['sync']), val, timestamp)
                    metric_list.append(metric)
    return metric_list

########################################################################################################################
def func_send_metric(metric_list):
    # send metric set through UDP socket (on remote side run 'nc -ulk <v_port>' to check socket transmission)
    for i in range(len(metric_list)):
        v_sock.sendto(metric_list[i], v_graphite_addr)

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
        print e

########################################################################################################################
def func_start_poll():
    # Poll metric periodically (temperature, offset, sync etc)
    cmd_list = []
    test_target = "" # developer test device, <user>@<host.domain>

    # Build strings with metric key and polling command (either test device or devices in facility)
    if "@" in test_target:
        # Build a header of metric key with "test.host"
        m_head = "test.%s" % (test_target.partition('@')[2].split('.')[0])
        # Build a string with metric key and polling command
        cmd = "%s.%s timeout 10 ssh %s saft-ctl -ft bla" % (m_head, v_metrics['temp'], test_target)
        cmd_list.append(cmd)
        #cmd = "%s.%s timeout 10 ssh %s eb-mon -o dev/wbm0" % (m_head, v_metrics['offset'], test_target)
        #cmd_list.append(cmd)
        # Find a valid option to get the WR sync status because the option varies for eb-mon
        sync_opt = func_find_option(test_target, "sync")
        cmd = "%s.%s timeout 10 ssh %s eb-mon -o %s dev/wbm0" % (m_head, v_metrics['offsyn'], test_target, sync_opt)
        cmd_list.append(cmd)
    else:
        try:
            with open('../devices.json') as json_file:
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
                            # Find a valid option to get the WR sync status because the option varies for eb-mon
                            sync_opt = func_find_option(login_to_host, "sync")
                            if sync_opt:
                                cmd = "%s.%s timeout 10 ssh %s eb-mon -o %s %s" % (m_head, v_metrics['offsyn'], login_to_host, sync_opt, q['slot'])
                            else:
                                cmd = "%s.%s timeout 10 ssh %s eb-mon -o %s" % (m_head, v_metrics['offsyn'], login_to_host, q['slot'])
                            cmd_list.append(cmd)
        except (ValueError, KeyError, TypeError):
            print "JSON format error"

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
                    print e

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
