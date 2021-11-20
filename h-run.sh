#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
LOGS_DIR="$SCRIPT_DIR/logs" # directory for pow-miner-gpu logs
MINER_KEYS=$( jq -r ".keys" $EXEC_CONF )
TMPFS_LOGS_ENEBLED=$( jq -r ".config.tmpfs_logs_enable" $EXEC_CONF )
UNITS_DIR="/etc/systemd/system"
#UNITS_DIR="$SCRIPT_DIR/config"

#-------------------------------------------------------------------------
# STOP AND REMOVE SYSTEMD UNITS
#-------------------------------------------------------------------------

systemctl list-units -t service --full | grep tonminer | awk '{print $1}' | xargs -i systemctl stop \{\}
rm $UNITS_DIR/tonminer*.service
systemctl daemon-reload
rm -f $SCRIPT_DIR/*blkstate*

#-------------------------------------------------------------------------
# 1. CHECK THE EXISTENCE OF DIRECTORY FOR POW-MINER-LOGS
# 2. CHECK THE THAT DIRECTORY IS A TMPFS MOUNT POINT
#-------------------------------------------------------------------------

if [ ! -d $LOGS_DIR ]
then
  mkdir $LOGS_DIR
fi

LOGS_DIR_MNT_CHECK="$( mount | grep $LOGS_DIR )"

echo "INFO:LOGS_DIR_MNT_CHECK=$LOGS_DIR_MNT_CHECK"

if [[ -z "$LOGS_DIR_MNT_CHECK" ]]; then
  umount $LOGS_DIR
  echo "INFO: mounting tmpfs logs dir \"$LOGS_DIR\""
  mount -t tmpfs -o size=50m tmpfs $LOGS_DIR
fi

#-------------------------------------------------------------------------
# CREATE SYSTEMD UNITS
#-------------------------------------------------------------------------

echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
  VARS=$(echo "{$CUSTOM_USER_CONFIG}" | jq "with_entries(select([.key] | inside([\"$KEY\"]))) | .[]")
  GIVER=$(echo $VARS | jq -r '.[0]')
  GPU_ID=$(echo $VARS | jq -r '.[1]')
  BOOST_FACTOR=$(echo $VARS | jq -r '.[2]')
  PLATFORM_ID=$(echo $VARS | jq -r '.[3]')
  VERBOSITY=$(echo $VARS | jq -r '.[4]')
  PARAMETERS=" -s $SCRIPT_DIR/logs/status-tonminer-$KEY.json"
  if [[ "$TMPFS_LOGS_ENEBLED" == "yes" ]]; then
    PARAMETERS="$PARAMETERS -l $SCRIPT_DIR/logs/log-tonminer-$KEY"
  fi
  UNIT_FILE="$UNITS_DIR/tonminer-$KEY.service"
  echo "INFO: create $UNIT_FILE"
  sed -e "s/{{KEY}}/$KEY/g" \
    -e "s/{{TYPE}}/$TYPE/g" \
    -e "s/{{GIVER}}/$GIVER/g" \
    -e "s/{{WALLET}}/$WALLET_ADR/g" \
    -e "s/{{GPU_ID}}/$GPU_ID/g" \
    -e "s/{{BOOST_FACTOR}}/$BOOST_FACTOR/g" \
    -e "s/{{PLATFORM_ID}}/$PLATFORM_ID/g" \
    -e "s/{{VERBOSITY}}/$VERBOSITY/g" \
    -e "s~{{PARAMETERS}}~$PARAMETERS~g" \
    "$SCRIPT_DIR/assets/tonminer.service" >$UNIT_FILE
done

#-------------------------------------------------------------------------
# START MINERS
#-------------------------------------------------------------------------

echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
  echo "INFO: start tonminer-$KEY.service"
  systemctl start "tonminer-$KEY.service"
done

# do not exit
echo "INFO: ALL STARTED"
sleep infinity