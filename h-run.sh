#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
LOGS_DIR="$SCRIPT_DIR/logs" # directory for miner logs
MINER_KEYS=$(jq -r ".keys" $EXEC_CONF)
TYPE=$(jq -r ".type" $EXEC_CONF)
RELEASE_VERSION=$(jq -r ".version" $SCRIPT_DIR/config/release.json)
WALLET_ADR=$(jq -r ".wallet" $EXEC_CONF)
TMPFS_LOGS_ENEBLED=$(jq -r ".config.tmpfs_logs_enable" $EXEC_CONF)
UNITS_DIR="/etc/systemd/system"

#debug
#UNITS_DIR="$SCRIPT_DIR/config"

#-------------------------------------------------------------------------
# STOP AND REMOVE SYSTEMD UNITS
#-------------------------------------------------------------------------

systemctl list-units -t service --full | grep tonminer-$TYPE | awk '{print $1}' | xargs -i systemctl stop \{\}
rm $UNITS_DIR/tonminer-$TYPE-*.service 2> /dev/null
# legacy clean up
if [ -f "$UNITS_DIR/tonminer-miner_0.service" ]; then
  rm $UNITS_DIR/tonminer-*.service
fi
systemctl daemon-reload
rm -f $SCRIPT_DIR/*blkstate* 2> /dev/null

# handle ctrl-c (miner stop)
trap ctrl_c INT

function ctrl_c() {
  systemctl list-units -t service --full | grep tonminer-$TYPE | awk '{print $1}' | xargs -i systemctl stop \{\}
  rm $UNITS_DIR/tonminer-$TYPE-*.service 2> /dev/null
}

#-------------------------------------------------------------------------
# 1. CHECK THE EXISTENCE OF DIRECTORY FOR POW-MINER-LOGS
# 2. CHECK THE THAT DIRECTORY IS A TMPFS MOUNT POINT
#-------------------------------------------------------------------------

if [ ! -d $LOGS_DIR ]; then
  mkdir $LOGS_DIR
fi

LOGS_DIR_MNT_CHECK="$(mount | grep $LOGS_DIR)"

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
  VARS=$(jq ".config | with_entries(select(.key==\"$KEY\")) | .[]" $EXEC_CONF)
  GIVER=$(echo $VARS | jq -r '.[0]')
  GPU_ID=$(echo $VARS | jq -r '.[1]')
  BOOST_FACTOR=$(echo $VARS | jq -r '.[2]')
  PLATFORM_ID=$(echo $VARS | jq -r '.[3]')
  VERBOSITY=$(echo $VARS | jq -r '.[4]')
  PARAMETERS=" -s $SCRIPT_DIR/logs/status-tonminer-$KEY.json"
  if [[ "$TMPFS_LOGS_ENEBLED" == "yes" ]]; then
    PARAMETERS+=" -l $SCRIPT_DIR/logs/log-tonminer-$KEY"
  fi
  UNIT_FILE="$UNITS_DIR/tonminer-$TYPE-$KEY.service"
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

$SCRIPT_DIR/assets/tonlib-$TYPE-cli -V
TONMINER_VERSION=$($SCRIPT_DIR/assets/tonlib-$TYPE-cli -V)
#TONMINER_VERSION="tonlib-cli build information: [ Commit: e624a4b82cab7e3a85817caa39e07691bcf4235f, Date: 2021-11-19 11:40:06 +0300]"
TONMINER_COMMIT=$(echo $TONMINER_VERSION | cut -d " " -f 6 )

echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
  echo "INFO: start tonminer-$TYPE-$KEY.service"
  systemctl start "tonminer-$TYPE-$KEY.service"
done

echo "INFO: ALL STARTED"

# do not exit
while true; do
  sleep 5.0
  echo "===[ "$(date +"%D %T")" ]===[ $TYPE ]===[ $RELEASE_VERSION ]===[ ${TONMINER_COMMIT:0:7} ]===="
  echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
    STATUS=$(systemctl show -p SubState --value tonminer-$KEY.service)
    STATUS_FILE="$SCRIPT_DIR/logs/status-tonminer-$KEY.json"
    STATUS_STATE=""
    if test -f "$STATUS_FILE"; then
      STATUS_GIVER=$(jq -r ".giver" $STATUS_FILE)
      STATUS_SEED=$(jq -r ".seed" $STATUS_FILE)
      STATUS_COMPLEXITY=$(jq -r ".complexity" $STATUS_FILE)
      STATUS_PASSED=$(jq -r ".passed" $STATUS_FILE)
      STATUS_HASHES_COMPUTED=$(jq -r ".hashes_computed" $STATUS_FILE)
      STATUS_SPEED=$(jq -r ".speed" $STATUS_FILE)
      STATUS_INSTANT_SPEED=$(jq -r ".instant_speed" $STATUS_FILE)
      STATUS_STATE="giver=$STATUS_GIVER, seed=${STATUS_SEED:0:4}...${STATUS_SEED: -4}, passed: $STATUS_PASSED, hashes computed: $STATUS_HASHES_COMPUTED, speed: $STATUS_INSTANT_SPEED Mhash/s, avg speed: $STATUS_SPEED Mhash/s"
    else
      STATUS_STATE+="ERROR: file not exists $STATUS_FILE"
    fi
    echo "[$KEY] status=$STATUS, $STATUS_STATE"
  done

  # force rotate logs
  #ps aux | grep -i [t]onlib-$TYPE | awk '{print $2}' | xargs -r sudo kill -1
done
