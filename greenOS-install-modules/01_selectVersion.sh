#!/bin/bash

latestRelease='1.2';
oldPS3Prompt=$PS3;

export PS3="Proszę wybrać wersję greenOS: ";
select version in Main Ratpoison greenServer; do
case $version in
  'Main') ARCHIVE="rootfs_${latestRelease}.tgz"; break;;
  'Ratpoison') ARCHIVE="rootfs_rp_${latestRelease}.tgz"; break;;
  'greenServer') ARCHIVE="rootfs_gs_${latestRelease}.tgz"; break;;
esac
done

echo "ARCHIVE=${ARCHIVE}";
export PS3=$oldPS3Prompt;
