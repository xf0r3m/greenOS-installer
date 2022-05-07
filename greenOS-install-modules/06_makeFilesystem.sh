#!/bin/bash

swapDevice=$(grep 'swap' /tmp/partitionMappings.txt | awk '{printf $1}');
mkswap $swapDevice;

devicesList=$(awk '{printf $1" "}' /tmp/partitionMappings.txt | sed "s@$swapDevice@@g");

if [ "$uefiapproved" = "t" ]; then
  efiDevice=$(grep 'efi' /tmp/partitionMappings.txt | awk '{printf $1}');
  mkfs.vfat $efiDevice;
  devicesList=$(echo $devicesList | sed "s@$efiDevice@@g"); 
fi

echo "Wynik działania polecenia mkfs, zawierający adresy kopii superbloki znajduje się w katalogu /tmp. Kolejno dla poszczeólnych partycji."; 
sleep 1;

for i in $devicesList; do
  mkfs.ext4 $i 2>&1 | tee /tmp/mkfs_ext4_$(basename $i).txt;
done
