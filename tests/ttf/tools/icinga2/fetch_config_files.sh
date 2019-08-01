#!/bin/bash
set +e
v_repo=https://raw.githubusercontent.com/GSI-CS-CO/ci_cd/master/tests/ttf/tools/icinga2
for v_file in groups.conf hosts.conf services.conf commands.conf \
              service_check_tr_gateware.sh service_check_tr_state.sh service_check_tr_acquired_locks.sh \
              service_check_tr_eb_command.sh \
              service_check_generic_snmp.sh service_check_generic_snmp_string.sh \
              WR-SWITCH-MIB.txt \
              fetch_config_files.sh
do
  rm $v_file
  wget $v_repo/$v_file
  chmod +x $v_file
done
sudo systemctl reload icinga2