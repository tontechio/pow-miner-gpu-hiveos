#!/bin/bash 

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"

# MINER EXECUTION CONFIG

echo "{" > "$EXEC_CONF"

WALLET_ADR="$( cat $WALLET_CONF | grep CUSTOM_TEMPLATE | cut -d= -f2 )"
# WALLET_ADR="${WALLET_ADR:1:-1}"

if [[ -z "$WALLET_ADR" ]]; then
  exit 1
fi

echo "\"wallet\": $WALLET_ADR," >> "$EXEC_CONF"

echo ${CUSTOM_USER_CONFIG} >> "$EXEC_CONF"

echo "}" >> "$EXEC_CONF"

exit 0