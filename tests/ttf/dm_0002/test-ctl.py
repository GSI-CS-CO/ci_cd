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
import time
from time import gmtime, strftime

########################################################################################################################
# Schedule settings
v_total_cores = 4
v_schedule_name = "fuzzer"
v_start_time_offset = 50000000000 # ns
v_verbose = 0

########################################################################################################################
# Random schedule settings
v_max_period_duration = 1000000000 # ns
v_max_periods = 9 # One additional period will be added by DM
v_max_events = 10

########################################################################################################################
# Global settings  (do not change this)
v_data_master = ""
v_data_master_login = ""
v_data_master_slot = ""
v_total_events_dm = 0
v_test_iterations = 0
v_test_finished = 0
v_current_time = 0
v_start_time = 0
v_stop_time = 0
v_reports = []

########################################################################################################################
# Report class
class report_class:
    v_total_events = 0
    v_late_events = 0
    v_early_events = 0
    v_delayed_events = 0
    v_conflict_events = 0
    v_events_matching = 0
    v_name = "empty"
    v_failed = 0

    def __init__(self, name, events, late_events, early_events, delayed_events, conflict_events, events_matching):
        global v_total_events
        self.v_name = name
        self.v_total_events = events
        self.v_late_events = late_events
        self.v_early_events = early_events
        self.v_delayed_events = delayed_events
        self.v_conflict_events = conflict_events
        self.v_events_matching = events_matching
        self.v_name = name
        if self.v_late_events == 1:
            self.v_failed += 1
        if self.v_early_events == 1:
            self.v_failed += 1
        if self.v_total_events != v_total_events_dm:
            self.v_failed += 1
        if self.v_events_matching == 0:
            self.v_failed += 1

    def show_result(self):
        print self.v_name
        print "-- Received events:  %s" % (self.v_total_events)
        print "-- Expected events:  %s" % (v_total_events_dm)
        print "-- Late events:      %s" % (self.v_late_events)
        print "-- Early events:     %s" % (self.v_early_events)
        print "-- Delayed events:   %s" % (self.v_delayed_events)
        print "-- Conflict events:  %s" % (self.v_conflict_events)
        print "-- Events matchting: %s" % (self.v_events_matching)
        print "-- Failed:           %s" % (self.v_failed)
        print ""
        return self.v_failed

    def archive(self):
        archive_file_name = "%s.rpt" % (self.v_name)
        file_handle = open(archive_file_name, 'w+')
        header = "%s\n" % (self.v_name)
        file_handle.write(header)
        file_handle.write('-------------------------\n')
        res = "Received/expected events: %s/%s\n" % (self.v_total_events, v_total_events_dm)
        file_handle.write(res)
        res = "Late/early/delayed/conflict events: %s/%s/%s/%s\n" % (self.v_late_events, self.v_early_events, self.v_delayed_events, self.v_conflict_events)
        file_handle.write(res)
        res = "Events matching events: %s\n" % (self.v_events_matching)
        file_handle.write(res)
        res = "Test result: %s\n\n" % (self.v_failed)
        file_handle.write(res)
        file_handle.close()

########################################################################################################################
def signal_handler(signal, frame):
    # Catch CTRL+C
    global v_test_finished
    v_test_finished = 1
    print "Caught CTRL+C => Test will finish now..."

########################################################################################################################
def clean_up_and_build(ver):
    # (Re)Build sched-builder application
    global v_reports
    subprocess.call(["rm","*.cmp"])
    subprocess.call(["rm","*.dot"])
    subprocess.call(["rm","*.rpt"])
    subprocess.call(["make", "clean"])
    subprocess.call(["make"])
    v_reports = []

########################################################################################################################
def generate_schedules(ver):
    # Build schedule for each CPU
    global v_total_events_dm
    v_total_events_dm = (v_max_periods+1)*v_max_events*v_total_cores
    for cpu_id in range(0, v_total_cores):
        print "Building schedule for CPU %d..." % (cpu_id)
        cmd = "./sched-builder %s %s %s %s %s" % (v_schedule_name, cpu_id, v_max_events, v_max_periods, v_max_period_duration)
        exitCode = subprocess.call((cmd.split()))
        if exitCode:
            exit(1)

########################################################################################################################
def get_time_from_data_master(ver):
    # Get the current WR time from dm-cmd <eb-device> status call
    global v_current_time
    cmd = "ssh %s@%s dm-cmd %s %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "status", "| grep \"ECA-Time: 0x\"")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    (out, err) = proc.communicate()
    data = out.split()
    # Save current white rabbit to v_current_time (global access)
    v_current_time = data[5]
    if ver == 1:
        print "Current time is:     %s" % v_current_time

########################################################################################################################
def set_start_time(ver):
    # Set the test start time (adding current time and defined start time offset)
    global v_start_time_offset
    global v_current_time
    global v_start_time
    global v_stop_time
    v_start_time = v_start_time_offset + int(v_current_time, 16)
    v_start_time = "0x%016x" % v_start_time
    if ver == 1:
        print "Test will start at:  %s" % v_start_time
    v_stop_time = int(v_start_time,16) + (v_max_period_duration*(v_max_periods+1))
    v_stop_time = "0x%016x" % v_stop_time
    if ver == 1:
        print "Test will finish at: %s" % v_stop_time

########################################################################################################################
def patch_comparison_files(ver):
    # Repleace time offset by final timestamps
    comparison_file_name = "%s.cmp" % (v_schedule_name)
    comparison_file_name = open(comparison_file_name, "w")
    for cpu_id in range(0, v_total_cores):
        print "Patching comparison file for CPU %d..." % (cpu_id)
        file_name = "%s_cpu%s.cmp" % (v_schedule_name, cpu_id)
        for iter in range(0, v_max_periods+1):
            file_handle = open(file_name, "r")
            for events in file_handle:
                event = events
                execution_time = event.split()
                execution_time_real = int(execution_time[0], 16) + int(v_start_time, 16)
                execution_time_real = (v_max_period_duration*iter)+execution_time_real
                execution_time_real = "0x%016x" % execution_time_real
                # Print <execution time> <event id> <parameter> to file
                write_line = "%s %s %s\n" % (execution_time_real, execution_time[1], execution_time[2])
                comparison_file_name.write(write_line)
            if ver == 1:
                print "%s -> %s" % (execution_time[0], execution_time_real)
        file_handle.close()
        if (v_total_cores-1) == 0:
            break
    comparison_file_name.close()

########################################################################################################################
def start_data_master(ver):
    cmd = "ssh %s@%s dm-cmd %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "stop")
    subprocess.call(cmd.split())
    cmd = "ssh %s@%s dm-cmd %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "halt")
    subprocess.call(cmd.split())
    cmd = "ssh %s@%s dm-sched %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "status")
    subprocess.call(cmd.split())
    if ver == 1:
        print cmd
    cmd = "ssh %s@%s dm-sched %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "clear")
    subprocess.call(cmd.split())
    if ver == 1:
        print cmd
    for cpu_id in range(0, v_total_cores):
        print "Uploading schedule to CPU %d..." % (cpu_id)
        file_name = "%s_cpu%s.dot" % (v_schedule_name, cpu_id)
        cmd = "scp %s %s@%s:/" % (file_name, v_data_master_login, v_data_master)
        subprocess.call(cmd.split())
        if ver == 1:
            print cmd
        cmd = "ssh %s@%s dm-sched %s add -s %s" % (v_data_master_login, v_data_master, v_data_master_slot, file_name)
        subprocess.call(cmd.split())
        if ver == 1:
            print cmd
        starter = "CPU%s_START" % (cpu_id)
        cmd = "ssh %s@%s dm-cmd %s origin -c %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, cpu_id, starter)
        subprocess.call(cmd.split())
        if ver == 1:
            print cmd
        cmd = "ssh %s@%s dm-cmd %s -c %s -t 0 starttime %s" % (v_data_master_login, v_data_master, v_data_master_slot, cpu_id, v_start_time)
        subprocess.call(cmd.split())
        if ver == 1:
            print cmd
        cmd = "ssh %s@%s dm-cmd %s start -c %s" % (v_data_master_login, v_data_master, v_data_master_slot, cpu_id)
        subprocess.call(cmd.split())
        if ver == 1:
            print cmd

########################################################################################################################
def stop_snooping(ver):
    # Stop snooping by killing saft-ctl instances
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        cmd = "ssh %s@%s%s killall saft-ctl" % (p['login'], p['name'], p['extension'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def start_snooping(ver):
    # Remove old CMP files and start snooping
    cmd_clean_list = []
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        cmd_clean = "ssh %s@%s%s rm /%s.cmp" % (p['login'], p['name'], p['extension'], q['dev_name'])
                        cmd_clean_list.append(cmd_clean)
                        cmd = "nohup ssh %s@%s%s saft-ctl %s snoop 0 0 0 -x >> /%s.cmp &" % (p['login'], p['name'], p['extension'], q['dev_name'], q['dev_name'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_clean_list)):
        subprocess.call(cmd_clean_list[i].split())
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def get_comparison_files(ver):
    # Collect all CMP files (from ever host)
    cmd_list = []
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        cmd = "scp %s@%s%s:/%s.cmp ." % (p['login'], p['name'], p['extension'], q['dev_name'])
                        cmd_list.append(cmd)
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    for i in range(len(cmd_list)):
        subprocess.call(cmd_list[i].split())

########################################################################################################################
def compare_results(ver):
    # Create working copy and remove bloat
    global v_reports
    try:
        # Sort files by execution time
        cmd = "sort %s.cmp" % (v_schedule_name)
        schedule_sor = "%s_sorted.cmp" % (v_schedule_name)
        output = subprocess.check_output(cmd.split())
        save_file = open(schedule_sor, 'w+')
        for line in output:
            save_file.write(line)
        save_file.close()
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                for q in p['receivers']:
                    if q['role'] == "node":
                        line_cnt = 0
                        late_cnt = 0
                        early_cnt = 0
                        delayed_cnt = 0
                        conflict_cnt = 0
                        file_name = "%s.cmp" % (q['dev_name'])
                        file_name_new = "%s_stripped.cmp" % (q['dev_name'])
                        file_name_sor = "%s_sorted.cmp" % (q['dev_name'])
                        f1 = open(file_name, 'r')
                        f2 = open(file_name_new, 'w+')
                        for line in f1:
                            dont_save_line = 0
                            # PPS event found? Skip this event!
                            if "EvtID: 0x1fff000000000000" in line:
                                dont_save_line = 1
                            if (dont_save_line == 0):
                                line_cnt += 1
                                if line.find("late") != -1:
                                    late_cnt += 1
                                if line.find("early") != -1:
                                    early_cnt += 1
                                if line.find("delayed") != -1:
                                    delayed_cnt += 1
                                if line.find("conflict") != -1:
                                    conflict_cnt += 1
                                smart_line = line.replace('!', ' !')
                                smart_line = smart_line.replace('tDeadline: ', '')
                                smart_line = smart_line.replace('EvtID: ', '')
                                smart_line = smart_line.replace('Param: ', '')
                                print_line = smart_line.split()
                                print_line = "%s %s %s\n" % (print_line[0], print_line[1], print_line[2])
                                f2.write(print_line)
                        f1.close()
                        f2.close()
                        # Sort file by execution time
                        cmd = "sort %s" % (file_name_new)
                        schedule_sor = "%s_sorted.cmp" % (q['dev_name'])
                        output = subprocess.check_output(cmd.split())
                        save_file = open(schedule_sor, 'w+')
                        for line in output:
                            save_file.write(line)
                        save_file.close()
                        # Compare files
                        equal = filecmp.cmp(file_name_new, schedule_sor)
                        v_reports.append(report_class(q['dev_name'],line_cnt,late_cnt,early_cnt,delayed_cnt,conflict_cnt,equal))
            for p in data:
                for q in p['receivers']:
                    file_name = "%s.cmp" % (q['dev_name'])
                    file_name_new = "%s_stipped.cmp" % (q['dev_name'])
    except (ValueError, KeyError, TypeError):
        print "JSON format error"

########################################################################################################################
def wait_until_end(ver):
    # Wait until time is up
    global v_current_time
    global v_stop_time
    ns_left = 0
    while True:
        get_time_from_data_master(1)
        time.sleep(5)
        ns_left = (int(v_stop_time,16) - int(v_current_time,16))
        if ns_left < 0:
            break
        if ver == 1:
            print "Nanoseconds left:    %s (%s)" % (("0x%016x" % ns_left), ns_left)

########################################################################################################################
def evaluate_reports(ver):
    # Just print results
    global v_reports
    archive = 0
    print "=============================================================================="
    test_result = 0
    for report in v_reports:
        if report.show_result() != 0:
            test_result += 1
            report.archive()
            archive = 1
    if archive == 1:
        archive_reports(1)
    print "=============================================================================="
    return test_result

########################################################################################################################
def func_gen_random_parameters(ver):
    # Generate new parameters
    global v_max_period_duration
    global v_max_periods
    global v_max_events
    v_max_period_duration = random.randint(500000000, 1000000000)
    v_max_events = random.randint(1, 20)
    v_max_periods = random.randint(1, 100)

########################################################################################################################
def archive_reports(ver):
    # Get time and create directory
    timestamp = strftime("%Y-%m-%d_%H-%M-%S", gmtime())
    timestamp_dir = "log/%s" % timestamp
    subprocess.call(["mkdir",timestamp_dir])
    timestamp_dir = "log/%s/" % timestamp
    # Save dot files
    dot_files = (glob.glob("*.dot"))
    dot_files = ' '.join(str(e) for e in dot_files)
    copy_cmd = "cp %s %s" % (dot_files, timestamp_dir)
    subprocess.call(copy_cmd.split())
    # Save cmp files
    dot_files = (glob.glob("*.cmp"))
    dot_files = ' '.join(str(e) for e in dot_files)
    copy_cmd = "cp %s %s" % (dot_files, timestamp_dir)
    subprocess.call(copy_cmd.split())
    # Save DM status
    cmd = "ssh %s@%s dm-sched %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "clear")
    subprocess.call(cmd.split())
    cmd = "ssh %s@%s dm-cmd %s %s" % (v_data_master_login, v_data_master, v_data_master_slot, "details")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    (out, err) = proc.communicate()
    save_file = open("dm_status.rpt", 'w+')
    for line in out:
        save_file.write(line)
    save_file.close()
    # Save rpt file
    dot_files = (glob.glob("*.rpt"))
    dot_files = ' '.join(str(e) for e in dot_files)
    copy_cmd = "cp %s %s" % (dot_files, timestamp_dir)
    subprocess.call(copy_cmd.split())

########################################################################################################################
def func_get_data_master():
    # Find data master in config file
    global v_data_master
    global v_data_master_login
    global v_data_master_alias
    global v_data_master_slot
    v_data_master_found = 0
    try:
        with open('../devices.json') as json_file:
            data = json.load(json_file)
            for p in data:
                saftd_stop_found = 0
                for q in p['receivers']:
                    if ("data_master_rnd" == str(q['role'])):
                        v_data_master = "%s%s" % (str(p['name']), str(p['extension']))
                        v_data_master_alias = str(q['dev_name'])
                        v_data_master_found = 1
                        v_data_master_login = str(p['login'])
                        v_data_master_slot = str(q['slot'])
    except (ValueError, KeyError, TypeError):
        print "JSON format error"
    if (v_data_master_found == 1):
        print "Found data master [%s:%s@%s]!" % (v_data_master_alias, v_data_master_login, v_data_master)
        return 0
    else:
        print "No data master found!"
        return 1

########################################################################################################################
def main():
    # Get arguments
    cmdtotal = len(sys.argv)
    cmdargs = str(sys.argv)
    test_result = 0
    iteration_cnt = 0
    global v_data_master
    global v_test_iterations
    global v_test_finished

    # Plausibility check
    if cmdtotal != 2:
        print "Error: Please provide a data master name (devices.json) and amount of test iterations!"
        print "Example: %s <<iterations>>" % (sys.argv[0])
        exit(1)
    else:
        try:
            signal.signal(signal.SIGINT, signal_handler)
            v_test_iterations = int(sys.argv[1])
            if func_get_data_master():
                exit(1)
        except:
            print "Error: Could not parse given arguments!"
            exit(1)

    # Start test
    while (v_test_finished == 0):
        # Clean up and build random schedule
        clean_up_and_build(0)
        generate_schedules(0)

        # Prepare Data Master
        get_time_from_data_master(0)
        set_start_time(0)
        patch_comparison_files(0)
        start_data_master(0)

        # Clean up (stop) and start snooping
        stop_snooping(0)
        start_snooping(0)

        # Wait until test should have finished
        wait_until_end(0)

        # Check test results
        get_comparison_files(0)
        compare_results(0)
        test_result = evaluate_reports(0)

        iteration_cnt += 1
        # End test?
        if v_test_iterations != 0:
            if iteration_cnt == v_test_iterations:
                v_test_finished = 1

        # Generate new parameters for the next run
        if v_test_finished == 0:
            func_gen_random_parameters(0)
        else:
            stop_snooping(0)

    # Done
    exit(test_result)

# Main
if __name__ == "__main__":
    main()
