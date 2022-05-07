#!/bin/bash

umount -R /mnt

echo -n "Instalacja została zakończona, czy chcesz zrestartować komputer [T/n]: "
read -n 1 rebootQuestion;
if [ "$rebootQuestion" ]; then
  rebootQuestion=$(echo $rebootQuestion | tr [A-Z] [a-z]);
  if [ "$rebootQuestion" = "t" ]; then
    echo "Restartowanie komputera...";
    sleep 1;
    reboot;
  else
    echo "Skrypt teraz zakończy działanie, zostanie zwrócona powłoka środowiska
    LiveCD. Jeśli chcemy zrestartować komputer, należy użyć polecenia reboot";
    export PS3=$oldPS3Prompt;
    exit;
else
  echo "Restartowanie komputera...";
  sleep 1;
  reboot;
fi
