#!/bin/bash

# Devices and hosts under test
ttf_pexaria_names=(pexaria5_18t pexaria5_27t pexaria5_41t pexaria5_15t pexaria5_14t pexaria5_43t)
ttf_pexaria_dev_ids=(dev/wbm0 dev/wbm1 dev/wbm2 dev/wbm3 dev/wbm4 dev/wbm5)
ttf_pexaria_hosts=(tsl011 tsl011 tsl011 tsl011 tsl011 tsl011)
ttf_pexaria_user=root

ttf_scu_names=(scuxl0001t scuxl0099t scuxl0007t scuxl0085t scuxl0088t scuxl0133t)
ttf_scu_hosts=(scuxl0001 scuxl0099 scuxl0007 scuxl0085 scuxl0088 scuxl0133)
ttf_scu_dev_id=dev/wbm0
ttf_scu_user=root

ttf_vetar_names=(vetar14t)
ttf_vetar_hosts=(kp1cx01)
ttf_vetar_dev_id=dev/wbm0
ttf_vetar_user=root

# Data master(s)
ttf_data_master="udp/192.168.191.92"
ttf_data_master_backup="udp/192.168.191.96"
ttf_data_master_pps_core_id=0
ttf_data_master_traffic_core_id=1

# Other defines and constants
tff_postfix="acc.gsi.de"
ttf_default_saft_dev="baseboard"
