#!/bin/bash
set +e
v_repo=https://raw.githubusercontent.com/GSI-CS-CO/ci_cd/master/tests/ttf/tools/icinga2
for v_file in groups.conf hosts.conf services.conf commands.conf service_check_tr_gateware.sh fetch_config_files.sh
do
  rm $v_file
  wget $v_repo/$v_file
  chmod +x $v_file
done
sudo systemctl reload icinga2
