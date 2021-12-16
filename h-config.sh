#!/bin/bash

TYPE="cuda"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"

# READ ENVS FROM FILE
set -o allexport
source $WALLET_CONF
set +o allexport

# CHECK NOT EMPTY
WALLET_ADR=$CUSTOM_TEMPLATE
if [[ -z "$WALLET_ADR" ]]; then
  exit 1
fi

# READ MINER KEYS
MINER_KEYS=$(echo "{$CUSTOM_USER_CONFIG}" | jq '[. | keys[] | select(contains("miner"))]')
MINER_NUM=$(echo "$MINER_KEYS" | jq 'length')

# MINER EXECUTION CONFIG
EXEC_CONF_JSON=$(jq -n \
  --arg type "$TYPE" \
  --arg wallet "$WALLET_ADR" \
  --arg num "$MINER_NUM" \
  --argjson keys "$MINER_KEYS" \
  --argjson config "{$CUSTOM_USER_CONFIG}" \
  '{"type":$type, "wallet":$wallet, "keys":$keys, "num":$num, $config}')

if [ $? -ne 0 ]; then
    echo "Invalid JSON string in Extra config arguments."
    exit 1
fi

echo $EXEC_CONF_JSON | jq > $EXEC_CONF

exit 0
