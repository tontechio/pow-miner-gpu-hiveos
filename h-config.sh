#!/bin/bash

TYPE="cuda"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
UNITS_DIR="/etc/systemd/system"
#UNITS_DIR="$SCRIPT_DIR/config"

# READ ENVS FROM FILE
set -o allexport
source $WALLET_CONF
set +o allexport

# CHECK NOT EMPTY
WALLET_ADR=$CUSTOM_TEMPLATE
if [[ -z "$WALLET_ADR" ]]; then
  exit 1
fi

# READ CONFIG
TMPFS_LOGS_ENEBLED=$(echo "{$CUSTOM_USER_CONFIG}" | jq -r '.tmpfs_logs_enable')
MINER_KEYS=$(echo "{$CUSTOM_USER_CONFIG}" | jq '[. | keys[] | select(contains("miner"))]')
MINER_NUM=$(echo "$MINER_KEYS" | jq 'length')

# MINER EXECUTION CONFIG
jq -n \
  --arg type "$TYPE" \
  --arg wallet "$WALLET_ADR" \
  --arg num "$MINER_NUM" \
  --argjson keys "$MINER_KEYS" \
  --argjson config "{$CUSTOM_USER_CONFIG}" \
  '{"type":$type, "wallet":$wallet, "keys":$keys, "num":$num, $config}' \
  >$EXEC_CONF

# STOP AND REMOVE SYSTEMD UNITS
/bin/systemctl stop minertools.service
rm $UNITS_DIR/minertools*.service
/bin/systemctl daemon-reload

# CREATE SYSTEMD UNITS
cp "$SCRIPT_DIR/assets/minertools.service" "$UNITS_DIR/minertools.service"
echo $MINER_KEYS | jq -c -r '.[]' | while read KEY; do
  VARS=$(echo "{$CUSTOM_USER_CONFIG}" | jq "with_entries(select([.key] | inside([\"$KEY\"]))) | .[]")
  GIVER=$(echo $VARS | jq -r '.[0]')
  GPU_ID=$(echo $VARS | jq -r '.[1]')
  BOOST_FACTOR=$(echo $VARS | jq -r '.[2]')
  PLATFORM_ID=$(echo $VARS | jq -r '.[3]')
  VERBOSITY=$(echo $VARS | jq -r '.[4]')
  PARAMETERS=" -s $SCRIPT_DIR/logs/status-minertools-$KEY.json"
  if [[ "$TMPFS_LOGS_ENEBLED" == "yes" ]]; then
    PARAMETERS="$PARAMETERS -l $SCRIPT_DIR/logs/log-minertools-$KEY"
  fi
  UNIT_FILE="$UNITS_DIR/minertools-$KEY.service"
  echo "$KEY: $UNIT_FILE"
  sed -e "s/{{KEY}}/$KEY/g" \
    -e "s/{{TYPE}}/$TYPE/g" \
    -e "s/{{GIVER}}/$GIVER/g" \
    -e "s/{{WALLET}}/$WALLET_ADR/g" \
    -e "s/{{GPU_ID}}/$GPU_ID/g" \
    -e "s/{{BOOST_FACTOR}}/$BOOST_FACTOR/g" \
    -e "s/{{PLATFORM_ID}}/$PLATFORM_ID/g" \
    -e "s/{{VERBOSITY}}/$VERBOSITY/g" \
    -e "s~{{PARAMETERS}}~$PARAMETERS~g" \
    "$SCRIPT_DIR/assets/minertools_miner.service" >$UNIT_FILE
done

exit 0
