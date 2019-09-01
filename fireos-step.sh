#!/bin/bash

set -e

. functions.inc

adb wait-for-device

PAYLOAD_BLOCK=1024

PART_PREFIX=/dev/block/platform/mtk-msdc.0/11230000.MSDC0

max_tee=258
max_lk=1
max_pl=5

check_device "karnak" " - Amazon Fire HD 8 (2018 / 8th gen) - "

get_root

tee_version=$((`adb shell getprop ro.boot.tee_version | dos2unix`))
lk_version=$((`adb shell getprop ro.boot.lk_version | dos2unix`))
pl_version=$((`adb shell getprop ro.boot.pl_version | dos2unix`))

echo "PL version: ${pl_version} (${max_pl})"
echo "LK version: ${lk_version} (${max_lk})"
echo "TZ version: ${tee_version} (${max_tee})"
echo ""

flash_exploit() {
    echo "Flashing PL"
    adb push bin/preloader.bin /data/local/tmp/
    adb shell su -c \"echo 0 \> /sys/block/mmcblk0boot0/force_ro\"
    adb shell su -c \"dd if=/data/local/tmp/preloader.bin of=/dev/block/mmcblk0boot0 bs=512 seek=8\"
    adb shell su -c \"dd if=/data/local/tmp/preloader.bin of=/dev/block/mmcblk0boot0 bs=512 seek=520\"
    echo ""

    echo "Flashing LK-payload"
    adb push lk-payload/build/payload.bin /data/local/tmp/
    adb shell su -c \"dd if=/data/local/tmp/payload.bin of=/dev/block/mmcblk0boot0 bs=512 seek=${PAYLOAD_BLOCK}\"
    echo ""

    echo "Flashing LK"
    adb push bin/lk.bin /data/local/tmp/
    adb shell su -c \"dd if=/data/local/tmp/lk.bin of=/${PART_PREFIX}/by-name/lk bs=512\"
    echo ""

    echo "Flashing TZ"
    adb push bin/tz.img /data/local/tmp/
    adb shell su -c \"dd if=/data/local/tmp/tz.img of=/${PART_PREFIX}/by-name/tee1 bs=512\"
    adb shell su -c \"dd if=/data/local/tmp/tz.img of=/${PART_PREFIX}/by-name/tee2 bs=512\"
    echo ""

    echo "Flashing TWRP"
    adb push bin/twrp.img /data/local/tmp/
    adb shell su -c \"dd if=/data/local/tmp/twrp.img of=/${PART_PREFIX}/by-name/recovery bs=512\"
    echo ""
}

if [ "$1" = "brick" ] || [ $tee_version -gt $max_tee ] || [ $lk_version -gt $max_lk ] || [ $pl_version -gt $max_pl ] ; then
  echo "TZ, Preloader or LK are too new, RPMB downgrade necessary (or brick option used)"
  echo "Brick preloader to continue via bootrom-exploit? (Type \"YES\" to continue)"
  read YES
  if [ "$YES" = "YES" ]; then
    echo "Bricking preloader"
    adb shell su -c \"echo 0 \> /sys/block/mmcblk0boot0/force_ro\"
    adb shell su -c \"dd if=/dev/zero of=/dev/block/mmcblk0boot0 bs=512 count=8\"
    adb shell su -c \"echo -n EMMC_BOOT \> /dev/block/mmcblk0boot0\"

    flash_exploit

    echo "Powering off..."
    adb shell reboot -p
    echo "Unplug device, start bootrom-step-minimal.sh and plug it back in."
    exit 0
  fi
  exit 1
fi

flash_exploit

echo "Flashing PL header"
adb push  bin/preloader.hdr0 /data/local/tmp/
adb push  bin/preloader.hdr1 /data/local/tmp/
adb shell su -c \"echo 0 \> /sys/block/mmcblk0boot0/force_ro\"
adb shell su -c \"dd if=/data/local/tmp/preloader.hdr0 of=/dev/block/mmcblk0boot0 bs=512 count=4\"
adb shell su -c \"dd if=/data/local/tmp/preloader.hdr1 of=/dev/block/mmcblk0boot0 bs=512 count=4 seek=4\"
echo ""

echo "Rebooting to TWRP"
adb reboot recovery