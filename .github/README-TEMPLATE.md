# TON miner for HiveOS

This is a HiveOS' *custom miner* build for TON miner (tontechio/pow-miner-gpu) - https://github.com/tontechio/pow-miner-gpu

NB: this is an early version of HiveOS custom miner, so don't hesitate to report an issues - https://github.com/tontechio/pow-miner-gpu-hiveos/issues

## Limitations

- HiveOS auto-update not supported
- HiveOS detailed stats not supported

## 1. Setup HiveOS

Based on an official HiveOS guides. In case of missunderstanding, stuck, etc please refer to the original guides - https://hiveos.farm/getting_started-quick_install/

* Skip this step if your HiveOS account and rig are already configured
* [Download](https://download.hiveos.farm/latest/) `hiveos*.img.gz` file
* Prepare external storage device (min 8Gb) which will be used to flash a `hiveos*.img.gz` file - USB flash drive, external SSD or another type of external storage drive
* HiveOS recommendations: 
  > [Etcher](https://www.balena.io/etcher/) is a recommended tool to write Hive images on the drives. It supports Windows, Mac, Linux. It can write unpacked ZIP archive as well.
  > 
  > Alternatively you can use [Rufus](https://rufus.akeo.ie/) as an image writing tool.
  > 
  > ...
  > 
  > Advanced Unix (Linux or Mac) users can use dd to write RAW image to disk. Something like `dd if=hiveos-XXX.img of=/dev/sdX bs=10M status=progress`. But be careful finding out output disk "of", use `fdisk -l` to list your partitions.
  > 
  > ...
  > 
  > Check full notes at https://hiveos.farm/install/
* Flash the `hiveos*.img.gz` to chosen external drive in binary mode
* Create an account on HiveOS - https://hiveos.farm/
* Create HiveOS rig. Remember the `RigID` and `RigPassword`
* Boot your PC/server/computer for mining using flashed external drive. **NB:** your PC/server/computer must have an internet connection
* After boot use your `RigID` and `RigPassword` to proceed
* Open *web configuration* of your HiveOS Rig
* Check the *<online>* state of your HiveOS Rig in your HiveOS account.

## 2. Configure TON miner

* Create a "TON wallet" in HiveOS account with custom "toncoin" coin
* *Source* for coin is optional, so you can ginore it or check the original docs (https://hiveos.farm/guides-how_to_start_mine_in_Hive_OS/)
* Fill and double check your personal wallet address in the *Address* field
* Now you must create HiveOS *flight sheet* for your Rig with custom Miner. Example below:

  | OPTION | VALUE | COMMENT |
  |:----------|:------|:--------| 
  Coin | toncoin
  Wallet | {YOUR TON WALLET ADDRESS}
  Pool | Configure in miner | 
  Name | TON flight sheet
  Miner Name | `tonminer_cuda_hiveos_x86_64` or `tonminer_opencl_hiveos_x86_64` | Generated automatically based on *Miner Installation URL* below
  Miner Installation URL | `https://github.com/tontechio/pow-miner-gpu-hiveos/releases/download/{{RELEASE_VERSION}}/tonminer_cuda_hiveos_x86_64-{{RELEASE_VERSION}}.tar.gz` or `https://github.com/tontechio/pow-miner-gpu-hiveos/releases/download/{{RELEASE_VERSION}}/tonminer_opencl_hiveos_x86_64-{{RELEASE_VERSION}}.tar.gz` | Depends on your GPU device. Choose *cuda* version for Nvidia GPU and *opencl* version for AMD GPU
  Miner Hash algorithm | | No value (empty)
  Miner Wallet and worker template | `%WAL%` | Only wallet number for easy script mechanics
  Miner Pool URL | `stratum+tcp://p2p.antpool.com:3333` | Keep the default value, this value is not used by TON miner
  Miner Extra config arguments | | *see below*
  >  Miner Extra config arguments
  > ```
  > "miner_0": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",0,32,0,2],
  > "miner_1": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",1,32,0,2],
  > "miner_2": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",2,32,0,2],
  > "miner_3": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",3,32,0,2],
  > "tmpfs_logs_enable": "yes"
  > ```
  > 
  > Format (please refer to [miner documentation](https://github.com/tontechio/pow-miner-gpu) for details):
  > ```
  > "miner_{ID}": [ "{GIVER_ADDR}",{GPU_ID},{BOOST_FACTOR},{PLATFORM_ID},{LOG_LEVEL}],
  > "miner_{ID}": [ "{GIVER_ADDR}",{GPU_ID},{BOOST_FACTOR},{PLATFORM_ID},{LOG_LEVEL}],
  > ...,
  > "tmpfs_logs_enable": {yes/no}
  > ```

* Apply changes in miner options
* Update flight sheet
* Push the *rocket button* near flight sheet to start the configured miner
* That's it

# Notes

## How to download and install this plugin manually

* Download latest miner:
  - CUDA: https://github.com/tontechio/pow-miner-gpu-hiveos/releases/download/{{RELEASE_VERSION}}/tonminer_cuda_hiveos_x86_64-{{RELEASE_VERSION}}.tar.gz
  - OpenCL: https://github.com/tontechio/pow-miner-gpu-hiveos/releases/download/{{RELEASE_VERSION}}/tonminer_opencl_hiveos_x86_64-{{RELEASE_VERSION}}.tar.gz
* Copy downloaded archive to the system directory `/hive/miners/custom/downloads/`
* Open HiveOS terminal shell (console) and execute commands:
  - `cd /hive/miners/custom/downloads/`
  - `tar -xf tonminer_*.tar.gz -C ../`
* Start the flight sheet

## Updating miner tools and blockchain config

Currently TON miner doesn't support HiveOS miner updates system. To update to the recent miner version just follow instructions for manual installation.
  
  
  

