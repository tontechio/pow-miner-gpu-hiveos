#!/bin/bash

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

USER_DIR="$(pwd)"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
UPDATE_CONF="$SCRIPT_DIR/update.config.json"
GL_CONF="$SCRIPT_DIR/global.config.json"
CUDA_M="$SCRIPT_DIR/../assets/tonlib-cuda-cli"
OCL_M="$SCRIPT_DIR/../assets/tonlib-opencl-cli"
ASSETS_DIR="$SCRIPT_DIR/../assets/"

BLOCK_CHAIN_GC_URL="$( jq -r ".block_chain_global_config_url" $UPDATE_CONF )"
PMG_OPENCL_URL="$( jq -r ".pow_miner_gpu_opencl_url" $UPDATE_CONF )"
PMG_CUDA_URL="$( jq -r ".pow_miner_gpu_cuda_url" $UPDATE_CONF )"

#-------------------------------------------------------------------------
# ENVIRONMENT (DETERMINED BY SCRIPT)
#-------------------------------------------------------------------------

cd $SCRIPT_DIR

echo "INFO: updating blockchain global.config.json"
sleep 1
wget -O global.config.json $BLOCK_CHAIN_GC_URL

if [ -f "$OCL_M" ]; then
    echo "INFO: updating pow-miner-gpu opencl"
    sleep 1
    wget -O minertools-opencl-ubuntu-18.04-x86-64.tar.gz $PMG_OPENCL_URL
    tar -xf minertools-opencl-ubuntu-18.04-x86-64.tar.gz -C $ASSETS_DIR
    rm -f minertools-opencl-ubuntu-18.04-x86-64.tar.gz 
fi

if [ -f "$CUDA_M" ]; then
    echo "INFO: updating pow-miner-gpu cuda"
    sleep 1
    wget -O minertools-cuda-ubuntu-18.04-x86-64.tar.gz $PMG_CUDA_URL
    tar -xf minertools-cuda-ubuntu-18.04-x86-64.tar.gz -C $ASSETS_DIR
    rm -f minertools-cuda-ubuntu-18.04-x86-64.tar.gz
fi

cd $USER_DIR