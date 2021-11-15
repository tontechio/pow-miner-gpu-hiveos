# pow-miner-gpu-hiveos

### 1. Setup HiveOS

* Download __hiveos*.img.gz__ file.
https://download.hiveos.farm/latest/
* Install some tool to write a __hiveos*.img.gz__ file to __USB flash drive__ os __SSD__ or another type of storage drive.
* __Windows write image tools__<br />
https://www.balena.io/etcher/<br />
https://sourceforge.net/projects/win32diskimager/<br />
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
Wallet | YOUR TON WALLET
Pool | Configure in miner
Name | TON flight sheet
Miner Name | pow_miner_gpu_universal_hiveos_amd64 | This name is __defined automatically__ when you past the __Miner Installation URL__
Miner Installation URL | https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_universal_hiveos_amd64.tar.gz
Miner Hash algorithm | | No value (empty)
Miner Wallet and worker template | %WAL% | Only wallet number for easy script mechanics
Miner Pool URL | stratum+tcp://p2p.antpool.com:3333" | Default value, we will not use it. HiveOS forces the existence of the value in this parameter.
Miner Extra config arguments | "giver_0": "kf8S\*\*\*\*\*\*\*\*\*\*716lN-",<br />"giver_1": "kf8S\*\*\*\*\*\*\*\*\*\*716lN-",<br />"giver_2": "kf8S\*\*\*\*\*\*\*\*\*\*716lN-",<br />"giver_3": "kf8S\*\*\*\*\*\*\*\*\*\*716lN-",<br />"gpu_0": ["cuda",0,32,0,2],<br />"gpu_1": ["cuda",0,32,0,2],<br />"gpu_2": ["ocl",0,32,0,2],<br />"gpu_3": ["ocl",0,32,0,2],<br />"tmpfs_logs_en": "yes"
* Also you can change __universal plugin__ to __cuda__ or __opencl__ only plugins, __links below__:<br />
https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_cuda_hiveos_amd64.tar.gz<br />
https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_opencl_hiveos_amd64.tar.gz<br />
* Miner Extra config arguments format:<br />"giver_#__GPU_NUM__": "#__GIVER_HASH__",<br />"gpu_#__CONFIG_GPU_NUM__": [ "#__TYPE (cuda/ocl)__", #__GPU-ID__,#__BOOST-FACTOR__, #__PLATFORM-ID__, #__LOG_VERBOSITY_LEVEL__],<br />"tmpfs_logs_en": "yes/no" (you can en/disable logs save process (logs stored in custom miner tmpfs (ram) directory "logs")
* __Apply changes in miner options__.
* Udate __flight sheet__.
* Push the __rocket button__ near __flight sheet__ to start the execution of the sheet and miner as follows.
  
### Update miner tools and blockchain config
* By executing the script __update.sh__ you can update __[pow-miner-cuda, pow-miner-opencl, tonlib-cuda-cli, tonlib-opencl-cli, global.config.json]__
* All __URLs__ are stored in update.config.json
  
### 3. How to download and install this plugin manually
* Download by link:<br />
https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_universal_hiveos_amd64.tar.gz<br />
https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_cuda_hiveos_amd64.tar.gz<br />
https://github.com/hardman-rd/pow-miner-gpu-hiveos/releases/latest/download/pow_miner_gpu_opencl_hiveos_amd64.tar.gz
* __Copy__ downloaded archive to the system directory __/hive/miners/custom/downloads/pow_miner_gpu_*_hiveos_amd64.tar.gz__
* Open in HiveOS Account terminal shell and type this commands:<br />
cd /hive/miners/custom/downloads/<br />
tar -xf pow_miner_gpu_*_hiveos_amd64.tar.gz -C ../
* Start the flight sheet and enjoy

  
  
  

