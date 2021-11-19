#!/bin/bash 

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"

WALLET_ADR="$( cat $WALLET_CONF | grep CUSTOM_TEMPLATE | cut -d= -f2 )"

if [[ -z "$WALLET_ADR" ]]; then
  exit 1
fi

# MINER EXECUTION CONFIG
echo "{" > "$EXEC_CONF"
echo "\"type\": \"cuda\"," >> "$EXEC_CONF"
echo "\"wallet\": $WALLET_ADR," >> "$EXEC_CONF"
echo ${CUSTOM_USER_CONFIG} >> "$EXEC_CONF"
echo "}" >> "$EXEC_CONF"

exit 0