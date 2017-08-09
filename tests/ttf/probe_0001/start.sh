#!/bin/bash

# Get all ttf devices
source ../probe_0001/devices.sh

# Control saftd ($1 = 0/1 (stop/start safdt))
function control_saftd()
{
  # Pexarias
  pex_id=0
  saftd_args=""
  saftd_devs=0
  saftd_host=""
  saftd_host_prev=""
  for i in ${ttf_pexaria_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saftd... ($i@${ttf_pexaria_hosts[$pex_id]})"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pex_id]}.$tff_postfix "killall saftd; pkill -f saft" > /dev/null 2>&1
    elif [ $1 -eq 1 ]; then
      echo "Starting saftd... ($i@${ttf_pexaria_hosts[$pex_id]})"
      # While host name is still the same -> collect devices
      if [ $saftd_devs -ne 0 ]; then
        saftd_host_prev=$saftd_host
      else
        saftd_host_prev=${ttf_pexaria_hosts[$pex_id]}
      fi
      saftd_host=${ttf_pexaria_hosts[$pex_id]}
      if [ "$saftd_host" == "$saftd_host_prev" ]; then
        # Collect arguments for saftd
        saftd_args=$saftd_args$i:${ttf_pexaria_dev_ids[$saftd_devs]}" "
        saftd_devs=$((saftd_devs+1))
        if [ $saftd_devs -eq ${#ttf_pexaria_names[@]} ]; then
          # Given list ends here
          ssh $ttf_pexaria_user@$saftd_host_prev.$tff_postfix "saftd $saftd_args" > /dev/null 2>&1
          ssh $ttf_pexaria_user@$saftd_host_prev.$tff_postfix "ps -ax | grep saftd | grep -v grep" 2>/dev/null
        fi
      elif [ "$saftd_host" != "$saftd_host_prev" ]; then
        # Found other host
        ssh $ttf_pexaria_user@$saftd_host_prev.$tff_postfix "saftd $saftd_args" > /dev/null 2>&1
        ssh $ttf_pexaria_user@$saftd_host_prev.$tff_postfix "ps -ax | grep saftd | grep -v grep" 2>/dev/null
        saftd_args=""
        saftd_devs=0
      else
        echo "Something is wrong with the configuration file!"
      fi
    else
      echo "======================================================================"
      echo "Probing... ($i@${ttf_pexaria_hosts[$pexaria_id]}@$ttf_pexaria_dev_id)"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "saft-ctl $i -i"; echo ""
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "saft-ctl $i -s"; echo ""
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "saft-io-ctl $i -i"; echo ""
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "saft-io-ctl $i -l"; echo ""
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "eb-info ${ttf_pexaria_dev_ids[$pexaria_id]}"; echo ""
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pexaria_id]}.$tff_postfix "eb-ls ${ttf_pexaria_dev_ids[$pexaria_id]}"; echo ""
      echo "======================================================================"
    fi
    pex_id=$((pex_id+1))
  done

  # Vetar
  vetar_id=0
  saftd_args=""
  saftd_devs=0
  saftd_host=""
  saftd_host_prev=""
  for i in ${ttf_vetar_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saftd... ($i@${ttf_vetar_hosts[$vetar_id]})"
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "killall saftd; pkill -f saft" > /dev/null 2>&1
    elif [ $1 -eq 1 ]; then
      echo "Starting saftd... ($i@${ttf_vetar_hosts[$vetar_id]})"
      # While host name is still the same -> collect devices
      if [ $saftd_devs -ne 0 ]; then
        saftd_host_prev=$saftd_host
      else
        saftd_host_prev=${ttf_vetar_hosts[$vetar_id]}
      fi
      saftd_host=${ttf_vetar_hosts[$vetar_id]}
      if [ "$saftd_host" == "$saftd_host_prev" ]; then
        # Collect arguments for saftd
        saftd_args=$saftd_args$i:${ttf_vetar_dev_ids[$saftd_devs]}" "
        saftd_devs=$((saftd_devs+1))
        if [ $saftd_devs -eq ${#ttf_vetar_names[@]} ]; then
          # Given list ends here
          ssh $ttf_vetar_user@$saftd_host_prev.$tff_postfix "/usr/sbin/saftd $saftd_args" > /dev/null 2>&1
          ssh $ttf_vetar_user@$saftd_host_prev.$tff_postfix "ps -ax | grep saftd | grep -v grep" 2>/dev/null
        fi
      elif [ "$saftd_host" != "$saftd_host_prev" ]; then
        # Found other host
        ssh $ttf_vetar_user@$saftd_host_prev.$tff_postfix "saftd $saftd_args" > /dev/null 2>&1
        ssh $ttf_vetar_user@$saftd_host_prev.$tff_postfix "ps -ax | grep saftd | grep -v grep" 2>/dev/null
        saftd_args=""
        saftd_devs=0
      else
        echo "Something is wrong with the configuration file!"
      fi
    else
      echo "======================================================================"
      echo "Probing... ($i@${ttf_vetar_hosts[$vetar_id]}@$ttf_vetar_dev_id)"
      echo $ttf_vetar_user ${ttf_vetar_hosts[$vetar_id]} $tff_postfix  $i
      sleep 5
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "saft-ctl $i -i"; echo ""
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "saft-ctl $i -s"; echo ""
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "saft-io-ctl $i -i"; echo ""
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "saft-io-ctl $i -l"; echo ""
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "eb-info ${ttf_vetar_dev_ids[$vetar_id]}"; echo ""
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "eb-ls ${ttf_vetar_dev_ids[$vetar_id]}"; echo ""
      echo "======================================================================"
    fi
    vetar_id=$((vetar_id+1))
  done

  # SCUs
  scu_id=0
  for i in ${ttf_scu_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saftd... ($i@${ttf_scu_hosts[$scu_id]})"
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "killall saftd; pkill -f saft" > /dev/null 2>&1
    elif [ $1 -eq 1 ]; then
      echo "Starting saftd... ($i@${ttf_scu_hosts[$scu_id]})"
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "/usr/sbin/saftd $ttf_default_saft_dev:$ttf_scu_dev_id"
      ssh $ttf_scu_user@${ttf_scu_hosts[$vetar_id]}.$tff_postfix "ps | grep saftd | grep -v grep" 2>/dev/null
    else
      echo "======================================================================"
      echo "Probing... ($i@${ttf_scu_hosts[$scu_id]}@$ttf_scu_dev_id)"
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "saft-ctl $ttf_default_saft_dev -i"; echo ""
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "saft-ctl $ttf_default_saft_dev -s"; echo ""
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "saft-io-ctl $ttf_default_saft_dev -i"; echo ""
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "saft-io-ctl $ttf_default_saft_dev -l"; echo ""
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "eb-info $ttf_scu_dev_id"; echo ""
      ssh $ttf_scu_user@${ttf_scu_hosts[$scu_id]}.$tff_postfix "eb-ls $ttf_scu_dev_id"; echo ""
      echo "======================================================================"
    fi
    scu_id=$((scu_id+1))
  done
  # exploders
  exploder_id=0
  for i in ${ttf_exploder_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Stopping saftd... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "killall saftd; pkill -f saft" > /dev/null 2>&1
    elif [ $1 -eq 1 ]; then
      echo "Starting saftd... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saftd ${ttf_exploder_names[$exploder_id]}:$ttf_exploder_dev_id"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "ps | grep saftd | grep -v grep" 2>/dev/null
    else
      echo "======================================================================"
      echo "Probing... ($i@${ttf_exploder_hosts[$exploder_id]}@$ttf_exploder_dev_id)"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-ctl ${ttf_exploder_names[$exploder_id]} -i"; echo ""
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-ctl ${ttf_exploder_names[$exploder_id]} -s"; echo ""
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-io-ctl ${ttf_exploder_names[$exploder_id]} -i"; echo ""
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-io-ctl ${ttf_exploder_names[$exploder_id]} -l"; echo ""
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "eb-info ${ttf_exploder_names[$exploder_id]}"; echo ""
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "eb-ls ${ttf_exploder_names[$exploder_id]}"; echo ""
      echo "======================================================================"
    fi
    exploder_id=$((exploder_id+1))
  done
}

# Configure LEDs (will react to all events) ($1 = 0/1 (enable/disable))
function config_leds()
{
  # Start logging, remove old log files and filter PPS events
  # Pexarias
  pex_id=0
  for i in ${ttf_pexaria_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Disabling LEDs... ($i@${ttf_pexaria_hosts[$pex_id]})"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pex_id]}.$tff_postfix "saft-io-ctl $i -n LED1_ADD_R -x;\
                                                                        saft-io-ctl $i -n LED2_ADD_B -x;\
                                                                        saft-io-ctl $i -n LED3_ADD_G -x;\
                                                                        saft-io-ctl $i -n LED4_ADD_W -x;\
                                                                        saft-io-ctl $i -n LED1_BASE_R -x;\
                                                                        saft-io-ctl $i -n LED2_BASE_B -x;\
                                                                        saft-io-ctl $i -n LED3_BASE_G -x;\
                                                                        saft-io-ctl $i -n LED4_BASE_W -x;"
    else
      echo "Enabling LEDs... ($i@${ttf_pexaria_hosts[$pex_id]})"
      ssh $ttf_pexaria_user@${ttf_pexaria_hosts[$pex_id]}.$tff_postfix "saft-io-ctl $i -n LED1_ADD_R -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED1_ADD_R -c 0x0 0x0 31250000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED2_ADD_B -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED2_ADD_B -c 0x0 0x0 62500000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED3_ADD_G -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED3_ADD_G -c 0x0 0x0 125000000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED4_ADD_W -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED4_ADD_W -c 0x0 0x0 250000000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED1_BASE_R -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED1_BASE_R -c 0x0 0x0 31250000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED2_BASE_B -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED2_BASE_B -c 0x0 0x0 62500000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED3_BASE_G -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED3_BASE_G -c 0x0 0x0 125000000 0xf 0 -u;\
                                                                        saft-io-ctl $i -n LED4_BASE_W -c 0x0 0x0 0 0xf 1 -u;\
                                                                        saft-io-ctl $i -n LED4_BASE_W -c 0x0 0x0 250000000 0xf 0 -u;"
    fi
    pex_id=$((pex_id+1))
  done

  # Vetar
  vetar_id=0
  for i in ${ttf_vetar_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Disabling LEDs... ($i@${ttf_vetar_hosts[$vetar_id]})"
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix  "saft-io-ctl $i -n LED9 -x;\
                                                                      saft-io-ctl $i -n LED10 -x;\
                                                                      saft-io-ctl $i -n LED11 -x;\
                                                                      saft-io-ctl $i -n LED12 -x;\
                                                                      saft-io-ctl $i -n LED_DACK -x;"


    else
      echo "Enabling LEDs... ($i@${ttf_vetar_hosts[$vetar_id]})"
      ssh $ttf_vetar_user@${ttf_vetar_hosts[$vetar_id]}.$tff_postfix "saft-io-ctl $i -n LED9 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED9 -c 0x0 0x0 31250000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED10 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED10 -c 0x0 0x0 62500000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED11 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED11 -c 0x0 0x0 125000000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED12 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED12 -c 0x0 0x0 250000000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED_DACK -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED_DACK -c 0x0 0x0 31250000 0xf 0 -u;"

    fi
    vetar_id=$((vetar_id+1))
  done

  # SCUs
  scu_id=0
  for i in ${ttf_scu_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Disabling LEDs... ($i@${ttf_scu_hosts[$scu_id]})"
    else
      echo "Enabling LEDs... ($i@${ttf_scu_hosts[$scu_id]})"
    fi
    scu_id=$((scu_id+1))
  done

  # exploders
  exploder_id=0
  for i in ${ttf_exploder_names[@]}; do
    if [ $1 -eq 0 ]; then
      echo "Disabling LEDs... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-io-ctl $i -n LED1 -x;\
                                                                      saft-io-ctl $i -n LED2 -x;\
                                                                      saft-io-ctl $i -n LED3 -x;\
                                                                      saft-io-ctl $i -n LED4 -x;"
    else
      echo "Enabling LEDs... ($i@${ttf_exploder_hosts[$exploder_id]})"
      ssh $ttf_exploder_user@${ttf_exploder_hosts[$exploder_id]}.$tff_postfix "saft-io-ctl $i -n LED1 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED1 -c 0x0 0x0 31250000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED2 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED2 -c 0x0 0x0 62500000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED3 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED3 -c 0x0 0x0 125000000 0xf 0 -u;\
                                                                      saft-io-ctl $i -n LED4 -c 0x0 0x0 0 0xf 1 -u;\
                                                                      saft-io-ctl $i -n LED4 -c 0x0 0x0 250000000 0xf 0 -u;"
    fi
    exploder_id=$((exploder_id+1))
  done
}

# Start configuration
case "$1" in
  "stop")
    control_saftd 0
    ;;
  "start")
    control_saftd 1
    ;;
  "restart")
    control_saftd 0
    echo "Waiting until all watchdog(s) are expired... (10 seconds)"
    sleep 10
    control_saftd 1
    ;;
   "probe")
    control_saftd 2
    ;;
    "led_init")
    config_leds 1
    ;;
    "led_deinit")
    config_leds 0
    ;;
  *)
    echo "You have failed to specify what to do correctly!"
    echo "Possible arguments are: stop/start/restart/probe/led_init/led_deinit"
    exit 1
    ;;
esac
