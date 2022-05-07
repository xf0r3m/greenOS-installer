#!/bin/bash

oldPS3Prompt=$PS3;

export PS3="Proszę wybrać lokalizację serwera z danymi dystrybucji: ";
select mirror in Global Poland; do 
case $mirror in
  'Global') ARCHIVE_LINK="https://sourceforge.net/projects/greenos/files/rootfs/${ARCHIVE}/download"; break;;
  'Poland') ARCHIVE_LINK="http://ftp.morketsmerke.net/greenOS/${ARCHIVE}"; break;;
esac
done

echo "ARCHIVE_LINK=${ARCHIVE_LINK}";
export PS3=$oldPS3Prompt;
