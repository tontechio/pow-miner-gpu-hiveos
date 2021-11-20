#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
LOGS_DIR="$SCRIPT_DIR/logs" # directory for pow-miner-gpu logs
MINER_KEYS="$( jq -r ".keys" $EXEC_CONF )"

#-------------------------------------------------------------------------
# stop old processes
#-------------------------------------------------------------------------

systemctl daemon-reload
systemctl list-units -t service --full | grep tonminer | awk '{print $1}' | xargs -i systemctl stop \{\}
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
# START MINERS
#-------------------------------------------------------------------------

echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
  echo "Start tonminer-$KEY.service"
  systemctl start "tonminer-$KEY.service"
done

# do not exit
echo "ALL STARTED"
sleep infinity