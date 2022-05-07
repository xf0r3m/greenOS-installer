#!/bin/bash

oldPS3Prompt=$PS3;

export PS3="Proszę wybrać sposób partycjonowania: ";
select partsch in Automated Manual; do
  case $partsch in
    'Automated') if [ "$uefiapproved" ]; then 
                  if [ $uefiapproved = 't' ]; then
                    echo "label: gpt" | sfdisk $disk >> /dev/null 2>&1;
                    echo ",300M,U," | sfdisk -a $disk >> /dev/null 2>&1;
                    echo "${disk}1 -> /efi" > /tmp/partitionsMappings.txt 
                    echo ",1G,S," | sfdisk -a -N 2 $disk >> /dev/null 2>&1;
                    echo "${disk}2 -> swap" >> /tmp/partitionMappings.txt
                    echo ",,L," | sfdisk -a -N 3 $disk >> /dev/null 2>&1;
                    echo "${disk}3 -> /" >> /tmp/partitionMappings.txt
                  fi
                fi
                if [ ! "$uefiapproved" ] || [ "$uefiapproved" = "n" ]; then
                    echo "label: dos" | sfdisk $disk >> /dev/null 2>&1;
                    echo ",1G,S," | sfdisk -a $disk >> /dev/null 2&>1;
                    echo "${disk}1 -> swap" > /tmp/partitionMappings.txt
                    echo ",,L,*" | sfdisk -a -N 2 $disk >> /dev/null 2>&1;
                    echo "${disk}2 -> /" >> /tmp/partitionMappings.txt 
                fi
                fdisk -l $disk;
                echo -n "Czy powyższe rozmiesczenie partycji jest akceptowalne? [T/n]: "
                read -n 1 diskaccept;
                if [ "$diskaccept" ]; then
                  diskaccept=$(echo $diskaccept | tr [A-Z] [a-z]);
                  if [ "$diskaccept" = "n" ]; then 
                    echo;
                    echo "1) Automated";
                    echo "2) Manual";
                    continue;
                  else break;
                  fi
                fi; break;;
    'Manual') echo "Partycjonując ręcznie dysk pamiętaj o przestrzeni wymiany!";
              sleep 1; 
              dd if=/dev/zero bs=1M of=$disk count=1;
              fdisk $disk;

              echo -n "Podaj nazwę urządzenia dla partycji zawierającej katalog główny: ";
              read rootpartition;
              echo "${rootpartition} -> /" | tee /tmp/partitionMappings.txt;

              echo -n "Podaj nazwę urządzenia dla partycji z przestrzenią wymiany: ";
              read swappartition;
              echo "${swappartition} -> swap" | tee -a /tmp/partitionMappings.txt;

              while [ true ]; do
                echo -n "Czy chcesz użyć innych dysków do instalacji greenOS. ";
                echo -n "Pamiętaj, że jest równoznaczne z utratą danych na podanych dyskach [T/n]: ";
                read -n 1 otherdisks;
                  if [ "$otherdisks" ]; then
                    otherdisks=$(echo $otherdisks | tr [A-Z] [a-z]);
                    if [ "$otherdisks" = "t" ]; then
                      echo -n "Podaj nazwę urządzenia dyskowego: ";
                      read otherdisk;
                      fdisk  $otherdisk;
                      partitionList=$(fdisk -l $otherdisk | sed -nr "s@/^(${otherdisk}[0-9]).+@\1@p" | awk '{printf $1}');
                      echo "Wykryto $(echo $partitionList | wc -w) partycję.";
                      i=1;
                      echo 'Instalator zapyta teraz o punkty montowania dla poszczególnych partycji, jeśli nie chcesz aby partycja brała udział w instalacji greenOS w punkcie montowania wpisz "none"';
                      sleep 1;
                      for part in $partitionList; do
                        echo -n "Podaj punkt motowania dla ${part}: ";
                        read mount_point;
                        if [ "$mount_point" ]; then
                          if [ "$mount_point" != "none" ]; then
                            echo "${part} -> ${mount_point}" | tee -a /tmp/partitionMappings.txt
                          fi
                        else continue;
                        fi 
                      done
                    elif [ "$otherdisks" = "n" ]; then 
                      echo; break; 
                    else echo; continue;
                    fi
                  else echo; break;
                  fi
              done;

              echo;
              break;
               
  esac
done

export PS3=$oldPS3Prompt;
