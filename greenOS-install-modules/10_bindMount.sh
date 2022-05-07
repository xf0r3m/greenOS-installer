#!/bin/bash

if [ "$uefiapproved" = "t" ]; then
  bindMountList="/dev /dev/pts /proc /run /sys /sys/firmware/efi/efivars";
else
  bindMountList="/dev /dev/pts /proc /run /sys";
fi

for i in $bindMountList; do
  mount -B $i /mnt$i; 
done
