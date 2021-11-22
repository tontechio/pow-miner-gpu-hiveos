#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
MINER_KEYS=$(jq -r ".keys" $EXEC_CONF)
TYPE=$(jq -r ".type" $EXEC_CONF)

# debug
#GPU_STATS_JSON="$SCRIPT_DIR/config/gpu_stats.json"

#-------------------------------------------------------------------------
# READ GPU STATS FROM HIVE OS
#-------------------------------------------------------------------------
GPU_STATS_JSON=`cat $GPU_STATS_JSON`

# fill some arrays from gpu-stats
temps=(`echo "$GPU_STATS_JSON" | jq -r ".temp[]"`)
fans=(`echo "$GPU_STATS_JSON" | jq -r ".fan[]"`)
powers=(`echo "$GPU_STATS_JSON" | jq -r ".power[]"`)
busids=(`echo "$GPU_STATS_JSON" | jq -r ".busids[]"`)
brands=(`echo "$GPU_STATS_JSON" | jq -r ".brand[]"`)
indexes=()

# filter arrays by $TYPE
cnt=${#busids[@]}
for (( i=0; i < $cnt; i++)); do
	if [[ "${brands[$i]}" == "nvidia" && "$TYPE" == "cuda" ]]; then
	  indexes+=($i)
	  continue
	elif [[ "${brands[$i]}" == "amd" &&  "$TYPE" == "opencl" ]]; then
	  indexes+=($i)
	  continue
	else # remove arrays data
		unset temps[$i]
		unset fans[$i]
		unset powers[$i]
		unset busids[$i]
		unset brands[$i]
	fi
done

#-------------------------------------------------------------------------
# READ MINER STAT
#-------------------------------------------------------------------------

STATUS_UPTIME=0
STATUS_HS=()
STATUS_TEMP=()
STATUS_FAN=()
STATUS_BUS_NUMBERS=()
khs=0

KEYS=($((echo $MINER_KEYS | jq -c -r '.[] | @sh') | tr -d \'))
for (( i=0; i < ${#KEYS[@]}; i++)); do
  KEY=${KEYS[$i]}
  STATUS_FILE="$SCRIPT_DIR/logs/status-tonminer-$KEY.json"

  if test -f "$STATUS_FILE"; then
    STATUS_TIMESTAMP=$(jq -r ".timestamp" $STATUS_FILE)
    STATUS_PASSED=$(jq -r ".passed" $STATUS_FILE)
    STATUS_INSTANT_SPEED=$(jq -r ".instant_speed" $STATUS_FILE)
    if [[ $STATUS_UPTIME < $STATUS_PASSED ]]; then
      STATUS_UPTIME=$STATUS_PASSED
    fi

    VARS=$(jq ".config | with_entries(select([.key] | inside([\"$KEY\"]))) | .[]" $EXEC_CONF)
    GPU_ID=$(echo $VARS | jq -r '.[1]')

    STATUS_BUS_NUMBERS+=($GPU_ID)
    STATUS_HS+=($STATUS_INSTANT_SPEED)
    khs=`echo $khs + $STATUS_INSTANT_SPEED | bc`
  fi
done

# cuda only, need to manage busid
for (( i=0; i < ${#STATUS_BUS_NUMBERS[@]}; i++)); do
    if [[ "$TYPE" == "cuda" ]]; then
      STATUS_TEMP+=(${temps[${indexes[${STATUS_BUS_NUMBERS[$i]}]}]})
      STATUS_FAN+=(${fans[${indexes[${STATUS_BUS_NUMBERS[$i]}]}]})
    fi
done

#-------------------------------------------------------------------------
# COLLECT
#-------------------------------------------------------------------------

khs=`echo $khs*1000 | bc`
hs=$(echo "${STATUS_HS[@]}" | jq -s '.')
temp=$(echo "${STATUS_TEMP[@]}" | jq -s '.')
fan=$(echo "${STATUS_FAN[@]}" | jq -s '.')
bus_numbers=$(echo "${STATUS_BUS_NUMBERS[@]}" | jq -s '.')

echo $hs $temp $fan $bus_numbers
stats=$(
  jq -n \
    --argjson hs "$hs" \
    --argjson temp "$temp" \
    --argjson fan "$fan" \
    --arg uptime "$STATUS_UPTIME" \
    --argjson bus_numbers "$bus_numbers" \
    '{"hs": $hs, "hs_units": "mhs", "temp": $temp, "fan": $fan, "uptime": $uptime, "ver": "", "bus_numbers":$bus_numbers}' <<<"$stats_raw"
)

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
