SHELL := /bin/bash # Use bash syntax
.PHONY: start-all stop-all testing check-ramdisk-passwd

start-all: check-ramdisk-passwd
	python test-metric-ctl.py start scu2 &
	python test-metric-ctl.py start scu3 &
	python test-metric-ctl.py start pexarria5 &
	python test-metric-ctl.py start exploder5 &
	python test-metric-ctl.py start pmc &
	python test-metric-ctl.py start vetar2a &

stop-all:
	-python test-metric-ctl.py stop scu2
	-python test-metric-ctl.py stop scu3
	-python test-metric-ctl.py stop pexarria5
	-python test-metric-ctl.py stop exploder5
	-python test-metric-ctl.py stop pmc
	-python test-metric-ctl.py stop vetar2a

testing: check-ramdisk-passwd
	-python test-metric-ctl.py stop exploder5
	python test-metric-ctl.py start exploder5 &

check-ramdisk-passwd:
# Proper user credentials must be provided to log in to remote Linux hosts
# equipped with timing receivers. User name is taken from an external
# configuration file, devices.json, but not password. Hence, two environment
# variables, PASSWD_RAMDISK_YES and PASSWD_RAMDISK_NO, are used to hold
# the password on run-time. Depending on boot situation (ramdisk or local)
# this password might be different: so two variables are needed.
ifndef PASSWD_RAMDISK_YES
	$(error Environment variable PASSWD_RAMDISK_YES need to be set)
endif
ifndef PASSWD_RAMDISK_NO
	$(error Environment variable PASSWD_RAMDISK_NO need to be set)
endif
