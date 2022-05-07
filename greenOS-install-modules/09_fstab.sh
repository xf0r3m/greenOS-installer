#!/bin/bash

if [ "$uefiapproved" = "t" ]; then
  efiDeviceUUID=$(blkid | grep "$efiDevice" | awk '{printf $2}');
  echo -e "$efiDeviceUUID\t/efi\tvfat\tumask=0077\t0\t0" > /mnt/etc/fstab;  
fi

rootDeviceUUID=$(blkid | grep "$rootDevice" | awk '{printf $2}');
echo -e "$rootDeviceUUID\t/\text4\tdefaults\t0\t1" >> /mnt/etc/fstab;

swapDeviceUUID=$(blkid | grep "$swapDevice" | awk '{printf $2}');
echo -e "$swapDeviceUUID\tnone\tswap\tsw\t0\t0" >> /mnt/etc/fstab

for i in $devicesList; do
  mountPoint=$(grep "$i" /tmp/partitionMappings.txt | awk '{printf $3}');
  deviceUUID=$(blkid | grep "$i" | awk '{printf $2}');
  echo -e "$deviceUUID\t$mountPoint\text4\tdefaults\t0\t2" >> /mnt/etc/fstab;
done

cat /mnt/etc/fstab;
