#!/bin/bash

rm -rf dist

mkdir -p dist/unlock/amonet/bin
cp bin/{boot0.gpt,preloader.hdr0,preloader.hdr1,preloader.bin,minisu.img,busybox,lk.bin,tz.img,twrp.img,microloader.bin} dist/unlock/amonet/bin/
echo -ne "boot-recovery\x00" > dist/unlock/amonet/bin/boot-recovery.bin

mkdir -p dist/unlock/amonet/lk-payload/build
cp lk-payload/build/payload.bin dist/unlock/amonet/lk-payload/build/

mkdir -p dist/unlock/amonet/modules
cp modules/{common.py,handshake.py,handshake2.py,load_payload.py,logger.py,main.py} dist/unlock/amonet/modules/

mkdir -p dist/unlock/amonet/brom-payload/build
cp brom-payload/build/payload.bin dist/unlock/amonet/brom-payload/build/

cp {functions.inc,fireos-step.sh,bootrom-step.sh,bootrom-step-minimal.sh,fastboot-step.sh,boot-fastboot.sh,boot-recovery.sh} dist/unlock/amonet/

mkdir -p dist/unlock/META-INF/com/google/android
cp META-INF/com/google/android/{update-binary,updater-script} dist/unlock/META-INF/com/google/android/

mkdir -p dist/stock/amonet/bin
cp bin/{boot.img,recovery.img} dist/stock/amonet/bin/
cp return-to-stock.sh dist/stock/amonet/

mkdir -p dist/full
cp -r dist/unlock/* dist/full/
cp -r dist/stock/* dist/full/
