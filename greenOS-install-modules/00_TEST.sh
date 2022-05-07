#!/bin/bash

if [ "$1" ]; then
    case $1 in
      1) bash -x 01_selectVersion.sh 2>&1 | tee 01_selectVersion.sh_testLog.txt;;
      2) export ARCHIVE=$(bash 01_selectVersion.sh | cut -d "=" -f 2); 
         bash -x 02_selectMirror.sh 2>&1 | tee 02_selectMirror.sh_testLog.txt;;
      3) bash -x 03_uefiApproved.sh 2>&1 | tee 03_uefiApproved.sh_testLog.txt;;
      4) bash -x 04_selectDisk.sh 2>&1 | tee 04_selectDisk.sh_testlog.txt;;
      5) export uefiapproved=$(bash 03_uefiApproved.sh | cut -d "=" -f 2); 
         export disk=$(bash 04_selectDisk.sh | grep "^disk\=" | cut -d "=" -f 2);
         bash -x 05_partitioning.sh 2>&1 | tee 05_partitioning.sh_testLog.txt;;
      6) export uefiapproved=$(bash 03_uefiApproved.sh | cut -d "=" -f 2); 
         bash -x 06_makeFilesystem.sh 2>&1 | tee 06_makeFilesystem.sh_testLog.txt;;
      7) bash -x 07_mountFilesystem.sh 2>&1 | tee 07_mountFilesystem.sh_testLog.txt;;
      8) export ARCHIVE=$(bash 01_selectVersion.sh | cut -d "=" -f 2);
         export ARCHIVE_LINK=$(bash 02_selectMirror.sh | cut -d "=" -f 2);
         bash -x 08_archive.sh 2>&1 | tee 08_archive.sh_testLog.txt;;
      9) export uefiapproved=$(bash 03_uefiApproved.sh | cut -d "=" -f 2);
         export rootDevice=$(grep "\/$" /tmp/partitionMappings.txt | awk '{printf $1}');
         export swapDevice=$(grep "swap" /tmp/partitionMappings.txt | awk '{printf $1}');
         bash -x 09_fstab.sh 2>&1 | tee 09_fstab.sh_testLog.txt;; 
      10) export uefiapproved=$(bash 03_uefiApproved.sh | cut  -d "=" -f 2);
          bash -x 10_bindMount.sh 2>&1 | tee 10_bindMount.sh_testLog.txt;;
      11) bash -x 11_runChrootCommand.sh | tee 11_runChrootCommand.sh_testLog.txt;;
      12) bash -x 12_eoi.sh 2>&1 | tee 12_eoi.sh_testLog.txt;;
    esac
fi 
