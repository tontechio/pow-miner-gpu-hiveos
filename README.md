# pow-miner-gpu-hiveos

### 1. Setup HiveOS

* Download __hiveos*.img.gz__ file.
https://download.hiveos.farm/latest/
* Install some tool to write a __hiveos*.img.gz__ file to __USB flash drive__ os __SSD__ or another type of storage drive.
* __Windows write image tools__<br />
https://www.balena.io/etcher/<br />
https://sourceforge.net/projects/win32diskimager/ <br />
https://rufus.ie/ru/
* Be careful. Destination __storage drive__ must have __at least 8Gb capacity__.
* Write the __hiveos*.img.gz__ to __storage drive__ in binary mode.
* __Create an account on HiveOS__
https://hiveos.farm/
* __Create HiveOS rig__. Remember the __RigID__ and __RigPassword__
* __Boot__ some machine (__PC__) with __NVIDIA__ or __AMD__ __GPU__ from the writed __HiveOS bootable storage drive__. You __must connect LAN with Internet__ to this machine.
* __Input__ on prompt __RigID__ and __RigPassword__. You can save __RigPassword__ as __system password__ also. 
* Open __web configuration__ of your __HiveOS Rig__.
* Check that you see __<online>__ state of the the __HiveOS Rig__ in __HiveOS account__.

### 2. Configure pow-miner-gpu in HiveOS

* __Create a TON wallet__ in HiveOS account with custom __TON coin__. If during this operation you will be asked to type __Source__ you can check __Exmo__ or something else, it does not matter. Be careful only with __Address__ field. __Do not mismatch__.
* Now you must __create HiveOS flight sheet__ for your Rig with custom Miner. Example below:

| PARAMETER | VALUE | COMMENT |
|:----------|:------|:--------| 
Coin | TON
Wallet | YOUR TON WALLET ADDRESS
Pool | Configure in miner
Name | TON flight sheet
Miner Name | tonminer_cuda_hiveos_0.6<br />or <br />tonminer_opencl_hiveos_0.6 | This name is __defined automatically__ when you past the __Miner Installation URL__
Miner Installation URL | [https://github.com/tontechio/pow-miner-gpu-hiveos/releases/latest/download/tonminer_cuda_hiveos_0.6.tar.gz](../../releases/latest/download/tonminer_cuda_hiveos_0.6.tar.gz)<br />or<br />[https://github.com/tontechio/pow-miner-gpu-hiveos/releases/latest/download/tonminer_opencl_hiveos_0.6.tar.gz](../../releases/latest/download/tonminer_opencl_hiveos_0.6.tar.gz) | Depends on your GPU device CUDA/OpenCL
Miner Hash algorithm | | No value (empty)
Miner Wallet and worker template | %WAL% | Only wallet number for easy script mechanics
Miner Pool URL | stratum+tcp://p2p.antpool.com:3333 | Default value, we will not use it. HiveOS forces the existence of the value in this parameter.
Miner Extra config arguments | <nobr>"miner_0": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",0,32,0,2],<br /><nobr>"miner_1": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",1,32,0,2],<br /><nobr>"miner_2": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",2,32,0,2],<br /><nobr>"miner_3": ["kf-P_TOdwcCh0AXHhBpICDMxStxHenWdLCDLNH5QcNpwMHJ8",3,32,0,2],<br />"tmpfs_logs_enable": "yes" | 
* Miner Extra config arguments format:<br />"miner_#__ID__": [ "#__GIVER-ADDRESS__", #__GPU-ID__,#__BOOST-FACTOR__, #__PLATFORM-ID__, #__LOG_VERBOSITY_LEVEL__],<br />"tmpfs_logs_enable": "yes/no" (you can en/disable logs save process (logs stored in custom miner tmpfs (ram) directory "logs")
* __Apply changes in miner options__.
* Udate __flight sheet__.
* Push the __rocket button__ near __flight sheet__ to start the execution of the sheet and miner as follows.

### Update miner tools and blockchain config

* By installing latest version of TON MINER plugin.
  
### 3. How to download and install this plugin manually

* Download by link:<br />
  [https://github.com/tontechio/pow-miner-gpu-hiveos/releases/latest/download/tonminer_cuda_hiveos_0.6.tar.gz](../../releases/latest/download/tonminer_cuda_hiveos_0.6.tar.gz)<br />
  [https://github.com/tontechio/pow-miner-gpu-hiveos/releases/latest/download/tonminer_opencl_hiveos_0.6.tar.gz](../../releases/latest/download/tonminer_opencl_hiveos_0.6.tar.gz)
* __Copy__ downloaded archive to the system directory __/hive/miners/custom/downloads/__
* Open in HiveOS Account terminal shell and type this commands:

        cd /hive/miners/custom/downloads/
        tar -xf tonminer_*_hiveos_0.6.tar.gz -C ../

* Start the flight sheet and enjoy

  
  
  

