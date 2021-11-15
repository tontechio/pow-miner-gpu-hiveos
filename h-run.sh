#!/bin/bash

#-------------------------------------------------------------------------
# SCRIPT VARIABLES
#-------------------------------------------------------------------------

GPUS_MAX_QNT=16     # maximum number of gpu configs in user config (determined by user)
GPUS_QNT=0          # number of gpu configs in user config (determined by script)

LOG_MAX_LINES=1000  # maximum size of logs

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXEC_CONF="$SCRIPT_DIR/config/execution.config.json"
GL_CONF="$SCRIPT_DIR/config/global.config.json"
CUDA_M="$SCRIPT_DIR/assets/tonlib-cuda-cli"
OCL_M="$SCRIPT_DIR/assets/tonlib-opencl-cli"
LOGS_DIR="$SCRIPT_DIR/logs" # directory for pow-miner-gpu logs
LOG_PIPE_FMT="/dev/pow-miner-gpu-logpipe-"

#-------------------------------------------------------------------------
# kill old processes
#-------------------------------------------------------------------------

killall tonlib-cuda-cli
killall tonlib-opencl-cli

rm -f $SCRIPT_DIR/*blkstate*

sleep 1

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
# CHECK THE WALLET ADDRESS EXISTENCE
# IN WALLET CONFIGURATION
# (wallet cinfiguration is provided by HiveOS from flight sheet miner)
#-------------------------------------------------------------------------

WALLET_ADR="$( jq -r ".wallet" $EXEC_CONF )"

if [[ -z "$WALLET_ADR" ]]; then
  exit 1
fi

echo "WALLET_ADR:$WALLET_ADR"

#-------------------------------------------------------------------------
# START MINERS
#-------------------------------------------------------------------------

TMPFS_LOGS_EN="$( jq -r ".tmpfs_logs_en" $EXEC_CONF )"

let "GPUS_MAX_QNT_SF = $GPUS_MAX_QNT - 1"

for i in $( seq 0 $GPUS_MAX_QNT_SF );
do

  GIVER_ADR="$( jq -r ".giver_$i" $EXEC_CONF )"

  if [[ "$GIVER_ADR" == "null" ]]; then
    GPUS_QNT=$i
    break
  fi

  echo "GIVER_ADR_$i:$GIVER_ADR"

  GPU_TYPE="$( jq -r ".gpu_$i[0]" $EXEC_CONF )" # gpu type (cuda/ocl)
  GPU_ID="$( jq -r ".gpu_$i[1]" $EXEC_CONF )"   # gpu id
  GPU_BF="$( jq -r ".gpu_$i[2]" $EXEC_CONF )"   # boost factor
  GPU_PID="$( jq -r ".gpu_$i[3]" $EXEC_CONF )"  # platform id
  GPU_LVL="$( jq -r ".gpu_$i[4]" $EXEC_CONF )"  # logs verbosity level

  echo "GPU_$i:[$GPU_TYPE,$GPU_ID,$GPU_BF,$GPU_PID,$GPU_LVL]"

  # eval "rm $LOG_PIPE_FMT$i"
  # eval "mkfifo $LOG_PIPE_FMT$i && chmod +w $LOG_PIPE_FMT$i"

  if [[ "$TMPFS_LOGS_EN" == "yes" ]]; then 
    
    if [[ "$GPU_TYPE" == "cuda" ]]; then
      eval "$CUDA_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &>> $LOGS_DIR/gpu_log_$i &"
    else
      eval "$OCL_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &>> $LOGS_DIR/gpu_log_$i &"
    fi
     
    log_pll[${i}]="$( wc -l $LOGS_DIR/gpu_log_$i | awk '{print $1}' )"
    
  else
  
    if [[ "$GPU_TYPE" == "cuda" ]]; then
      eval "$CUDA_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &"
    else 
      eval "$OCL_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &"
    fi
    
  fi
  
  pid=$!
  pids[${i}]=$pid

  echo "GPU_$i:pid:$pid"

done

echo "GPUS_QNT=$GPUS_QNT"

#-------------------------------------------------------------------------
# MONITOR THE EXISTENCE OF MINERS BY PID AND RESTART THE COMPLETED ONES
#-------------------------------------------------------------------------

let "GPUS_QNT_SF = $GPUS_QNT - 1"

while true
do

  sleep 5.0

  for i in $( seq 0 $GPUS_QNT_SF );
  do
  
    if [[ "$TMPFS_LOGS_EN" == "yes" ]]; then 
      
      log_ll="$( wc -l $LOGS_DIR/gpu_log_$i | awk '{print $1}' )"
    
      let "log_nl = $log_ll - log_pll[i]"
        
      eval "tail -n-$log_nl "$LOGS_DIR/gpu_log_$i" | sed -e 's/^/gpu_log_$i: /'"
      
      log_pll[${i}]=$log_ll
    
      # LOG ROTATION
      if [ $log_ll -ge $LOG_MAX_LINES ]; then
        let "log_dlq = $log_ll - $LOG_MAX_LINES"
        sed -i '$log_dlqd' "$LOGS_DIR/gpu_log_$i"
        log_pll[${i}]=$LOG_MAX_LINES
      fi
    
    fi  

    pid="${pids[i]}"

    if ps -p $pid > /dev/null 
    then
      continue
    fi

    echo "GPU_$i:restarting"

    GIVER_ADR="$( jq -r ".giver_$i" $EXEC_CONF )"

    if [[ "$GIVER_ADR" == "null" ]]; then
      GPUS_QNT=$i
      break
    fi

    echo "GIVER_ADR_$i:$GIVER_ADR"

    GPU_TYPE="$( jq -r ".gpu_$i[0]" $EXEC_CONF )" # gpu type (cuda/ocl)
    GPU_ID="$( jq -r ".gpu_$i[1]" $EXEC_CONF )"   # gpu id
    GPU_BF="$( jq -r ".gpu_$i[2]" $EXEC_CONF )"   # boost factor
    GPU_PID="$( jq -r ".gpu_$i[3]" $EXEC_CONF )"  # platform id
    GPU_LVL="$( jq -r ".gpu_$i[4]" $EXEC_CONF )"  # logs verbosity level

    echo "GPU_$i:[$GPU_TYPE,$GPU_ID,$GPU_BF,$GPU_PID,$GPU_LVL]"

    # eval "rm $LOG_PIPE_FMT$i"
    # eval "mkfifo $LOG_PIPE_FMT$i && chmod +w $LOG_PIPE_FMT$i"

    if [[ "$TMPFS_LOGS_EN" == "yes" ]]; then 
      
      if [[ "$GPU_TYPE" == "cuda" ]]; then
        eval "$CUDA_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &>> $LOGS_DIR/gpu_log_$i &"
      else
        eval "$OCL_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &>> $LOGS_DIR/gpu_log_$i &"
      fi
    
    else
    
      if [[ "$GPU_TYPE" == "cuda" ]]; then
        eval "$CUDA_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &"
      else 
        eval "$OCL_M -v $GPU_LVL -C $GL_CONF -e 'pminer start $GIVER_ADR $WALLET_ADR $GPU_ID $GPU_BF $GPU_PID' &"
      fi
      
    fi
    
    pid=$!
    pids[${i}]=$pid

    echo "GPU_$i:pid:$pid"

  done

done
