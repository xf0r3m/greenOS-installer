#!/bin/bash

while [ true ]; do
  if [ -d /sys/firmware/efi/efivars ]; then
    echo "Uruchomiono obraz LiveCD w trybie UEFI.";
    echo -n "Czy chcesz kontynuować instalacje w tym trybie [T/n]:";
    read -n 1 uefiapproved;
    if [ ! "$uefiapproved" ]; then
      uefiapproved='t';
      break;
    else
      uefiapproved=$(echo $uefiapproved | tr [A-Z] [a-z]);
      if [ "$uefiapproved" = 't' ] || [ "$uefiapproved" = 'n' ]; then
        break;
      else
        continue;
      fi
    fi
  else
    uefiapproved='n'; 
    break;
  fi
done

