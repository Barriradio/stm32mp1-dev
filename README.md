# stm32mp1-dev
Docker Dev Image for STM32MP15-Ecosystem-v1.0.0 release

## Included 
* STM32MP1 SDK in /home/dev/.stm32mp1-sdk 
* TF-A & U-Boot sources to build in /home/dev/src

## Build TF A
* Example for dk2 trusted:
```
cd /home/dev/src/arm-openstlinux_weston-linux-gnueabi/tf-a-stm32mp-2.0-r0/tf-a-stm32mp-src \
&& make -f $PWD/../Makefile.sdk TFA_DEVICETREE=stm32mp157c-dk2 TF_A_CONFIG=trusted all
```

## Build U Boot
* Example for dk2 trusted:
```
cd /home/dev/src/arm-openstlinux_weston-linux-gnueabi/u-boot-stm32mp-2018.11-r0/u-boot-stm32mp-src \
&& make stm32mp15_trusted_defconfig \
&& make DEVICE_TREE=stm32mp157c-dk2 all -j8
```
