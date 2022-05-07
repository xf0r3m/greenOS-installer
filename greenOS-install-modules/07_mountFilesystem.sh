#!/bin/bash

rootDevice=$(grep "\/$" /tmp/partitionMappings.txt | awk '{printf $1}');
mount $rootDevice /mnt;

devicesList=$(echo $devicesList | sed "s@$rootDevice@@g");
for i in $devicesList; do
  mountPoint=$(grep "$i" /tmp/partitionMappings.txt | awk '{printf $3}');
  mount $i /mnt$mountPoint;
done
