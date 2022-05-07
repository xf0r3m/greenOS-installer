#!/bin/bash

oldPS3Prompt=$PS3;

diskList=$(fdisk -l | sed -nr 's/Disk\ (\/dev\/.d.[^:]*).+/\1/p' | awk '{printf $1" "}');
export PS3="Proszę wybrać docelowy dysk: ";
select disk in $diskList; do
diskSize=$(fdisk -l $disk | sed -nr "s/.+$(basename $disk):\ ([^, ]*).+/\1/p");
if [ $diskSize -lt 4 ]; then
  echo "Wybrany dysk ma mniej niż 4GB, reczywista wartość kart pamięci 4GB to";
  echo "3.8GB. Wybrany dysk nie spełnia minimalnych wymagań instalacji greenOS";
  continue;
else
  break;
fi
done

echo "disk=${disk}";
echo "diskSize=${diskSize}";

export PS3=$oldPS3Prompt;
