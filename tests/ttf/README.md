# Timing Test Facility (+++ README Draft 1.0 +++)

This folder contains all test cases and configurations for the timing test facility.

---------------------------------------------------------------------------------------------------

# JSON Files

* abandoned_devices.json: These devices still exist inside the test facility, but they are not tested or monitored.
* devices.json: All active devices which will be tested and monitored.
* switches.json: All White Rabbit switches.

---------------------------------------------------------------------------------------------------

# Test DM_0002

## Synopsis and Usage

* Creates a random schedule (for every core) and plays it.
* The application saft-ctl (snoop mode) will be opened on every device.
* After sending all events, the script will check if every device got all events.
* Additionally the script will search for late and early events.
* Failed tests will be archived inside the log directory.

`./test-ctl.py iterations`

## Example

`./test-ctl.py 10` - Will run 10 random schedules.

## Arguments

* iterations: Defines how many schedules should be created and tested.

## Applications under Test

* dm-cmd
* dm-sched
* saft-ctl

---------------------------------------------------------------------------------------------------

# Test PROBE_0002

## Synopsis and Usage

* Advanced device control and monitoring.

`./test-ctl.py operation target`

`./test-ctl.py operation target gateware_update_file`

## Example

`./test-ctl.py restart scu2` - Restarts saftd on every scu2 device.

`./test-ctl.py probe all` - Probes all devices.

`./test-ctl.py flash_secure exploder5 exploder5_gateware.rpd` - Flashes all Exploder5 devices (secure mode).

## Arguments

* operation: Defines the operation which will be performed:
  * start: Starts saftd.
  * stop: Stops saftd.
  * restart: Restarts saftd (with additional 10 seconds delay between).
  * probe: Checks eb-ls, eb-info, eb-mon and saft-ctl.
  * reset: Issues eb-reset and reboots the host.
  * wrstatreset: Resets statistics for eCPU stalls and WR time.
  * flash: Flashes new gateware (not recommended!).
  * flash_secure: Flashes new gateware using "secure" parameters (recommended!).

* target: Defines a target/timing receiver type:
  * scu2
  * scu3
  * pexarria5
  * exploder5
  * microtca
  * pmc
  * vetar2a
  * vetar2a-ee-butis
  * ftm
  * all

* gateware_update_file: Your device specific gateware.rpd, target <<all>> will be ignored.

## Applications under Test

* saftd
* saft-ctl
* eb-ls
* eb-info
* eb-mon
* eb-reset
* eb-flash

---------------------------------------------------------------------------------------------------

# Test PPS_0002

## Synopsis and Usage

* Synchronization Monitoring.
* Starts or stops a PPS (one pulse per second) schedule.
* A set of defined timing receivers (JSON => "role" : "pps_monitor") will latch each PPS from other timing receivers.
* Script scope.py can be used to monitor the synchronization quality.

`./test-ctl.py operation`

## Example

`./test-ctl.py init` - Spawns saft-pps-gen on all receivers.

`./test-ctl.py start` - Plays PPS schedule forever.

`./scope.py` - Opens the python-based scope.

## Arguments

* start: Starts the PPS schedule.
* stop: Stops the PPS schedule.
* init: Spawns: Spawns saft-pps-gen on all receivers, external PPS schedule required.
* init_local: Spawns saft-pps-gen on all receivers, works without data master/external schedule.
* deinit: Kills saft-pps-gen every device.

## Applications under Test

* dm-cmd
* dm-sched
* saft-pps-gen

---------------------------------------------------------------------------------------------------

# Tools

## Icinga2

* Pleae check the Makefile header.
