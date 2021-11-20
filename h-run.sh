#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
LOGS_DIR="$SCRIPT_DIR/logs" # directory for pow-miner-gpu logs

#-------------------------------------------------------------------------
# stop old processes
#-------------------------------------------------------------------------

/bin/systemctl daemon-reload
/bin/systemctl stop minertools* --all
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

/bin/systemctl start minertools* --all

# do not exit
sleep infinity