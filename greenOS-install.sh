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

export PS3="Proszę wybrać lokalizację serwera z danymi dystrybucji: ";
select mirror in Global Poland; do 
case $mirror in
  'Global') ARCHIVE_LINK="https://sourceforge.net/projects/greenos/files/rootfs/${ARCHIVE}/download";;
  'Poland') ARCHIVE_LINK="http://ftp.morketsmerke.net/greenOS/${ARCHIVE}";;
esac
done

if [ -d /sys/firmware/efi/efivars; ]; then
  echo "Uruchomiono obraz LiveCD w trybie UEFI.";
  echo -n "Czy chcesz kontynuować instalacje w tym trybie [T/n]:";
  read -n 1 uefiapproved;
  if [ ! "$uefiapproved" ]; then
    uefiapproved='t';
  else
    uefiapproved=$(echo $uefiapproved | tr [A-Z] [a-z]);
  fi 
fi

diskList=$(fdisk -l | sed -nr 's/Disk\ (\/[^:]*).+/\1/p' | awk '{printf $1}');
export PS3="Proszę wybrać docelowy dysk: ";
select disk in $diskList; do
diskSize=$(fdisk -l $disk | sed "s/.+$(basename $disk):\ ([^,]*).+/\1/p");
if [ $diskSize -lt 4 ]; then
  echo "Wybrany dysk ma mniej niż 4GB, reczywista wartość kart pamięci 4GB to";
  echo "3.8GB. Wybrany dysk nie spełnia minimalnych wymagań instalacji greenOS";
  continue;
fi
done

export PS3="Proszę wybrać sposób partycjonowania: ";
select partsch in Automated Manual; do
  case $PATHSCH; in
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
                    echo ",,L,*" | sfdisk -a -N 2 $DISK >> /dev/null 2>&1;
                    echo "${disk}2 -> /" >> /tmp/partitionMappings.txt 
                fi
                fdisk -l $DISK;
                echo -n "Czy powyższe rozmiesczenie partycji jest akceptowalne? [T/n]: "
                read -n 1 diskaccept;
                if [ "$diskaccept" ]; then
                  diskaccept=$(echo $diskaccept | tr [A-Z] [a-z]);
                  if [ "$diskaccept" = "n" ]; then echo; continue;
                  else break;
                  fi
                fi;;
    'Manual') echo "Partycjonując ręcznie dysk pamiętaj o przestrzeni wymiany!";
              sleep 1; 
              dd if=/dev/zero bs=1M of=$DISK count=1;
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
                    if [ "$otherdisk" = "t" ]; then
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
                    elif [ "$otherdisk" = "n" ]; then 
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
  mkfs.ext4 $i > /tmp/mkfs_ext4_$(basename $1).txt 2>&1;
done

#for i in $devicesList; do
#  mountPoint=$(grep "$i" /tmp/manualPartitionMappings.txt | awk '{printf $3}');
#  export PS3="Wybierz system plików dla $mountPoint: ";
#  select fs in ext4 btrfs xfs; do 
#   mkfs.$fs $i; break;
#  done
#done

rootDevice=$(grep "\/$" /tmp/partitionMappings.txt | awk '{printf $1}');
mount $rootDevice /mnt;

devicesList=$(echo $devicesList | sed "s@$rootDevice@@g");
for i in $devicesList; do
  mountPoint=$(grep "$i" /tmp/partitionMappings.txt | awk '{printf $3}');
  mount $i /mnt$mountPoint;
done


wget $ARCHIVE_LINK -O /mnt/$ARCHIVE;
tar -xzvf /mnt/$ARCHIVE -C /mnt

echo > /mnt/etc/fstab;

if [ "$uefiapproved" = "t" ]; then
  efiDeviceUUID=$(blkid | grep "$efiDevice" | awk '{printf $2}');
  echo -e "$efiDeviceUUID\t/efi\tvfat\tumask=0077\t0\t0" > /mnt/etc/fstab;  
fi

rootDeviceUUID=$(blkid | grep "$rootDevice" | awk '{printf $2}');
echo -e "$rootDeviceUUID\t/\text4\tdefaults\t0\t1" >> /mnt/etc/fstab;

swapDeviceUUID=$(blkid | grep "$swapDevice" | awk '{printf $2}');
echo -e "$swapDeviceUUID\tnone\tswap\tsw\t0\t1" >> /mnt/etc/fstab

for i in $devicesList; do
  mountPoint=$(grep "$i" /tmp/partitionMappings.txt | awk '{printf $3}');
  deviceUUID=$(blkid | grep "$i" | awk '{printf $2}');
  echo -e "$deviceUUID\t$mountPoint\text4\tdefaults\t0\t2" >> /mnt/etc/fstab;
done

if [ "$uefiapproved" = "t" ]; then
  bindMountList="/dev /dev/pts /proc /run /sys /sys/firmware/efi/efivars";
else
  bindMountList="/dev /dev/pts /proc /run /sys";
fi

for i in $bindMountList; do
  mount -B $i /mnt$i; 
done

cat << EOF > /mnt/chrootCommand.sh
while [ true ]; do
  echo -n "Hasło dla użytkownika root: ";
  read rootPasswd;
  if [ "$rootPasswd" ]; then
    break;
  fi
done
chpasswd < echo "root:$rootPasswd";

while [ true ]; do
  echo -n "Nazwa dla nowego użytkownika: ";
  read userName;
  if [ "$userName" ]; then 
    break;
  fi
done

echo -n "Domyślna powłoka dla nowego użytkownika [/bin/bash]: ";
read defaultShell;
if [ ! "$defaultShell" ]; then 
  defaultShell='/bin/bash'; 
fi;

while [ true ]; do
  echo -n "Hasło dla nowego użytkownika: ";
  read -s userPasswd;
  if [ "$userPasswd"; ]; then
    break;
  fi
done

useradd -m -s $defaultShell $userName;
chpasswd < echo "${userName}:${userPasswd}";

echo "$userName ALL=(ALL:ALL) ALL" >> /etc/sudoers;

if [ -d /sys/firmware/efi/efivars ]; then
  apt update;
  apt install grub-efi;
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=debian;
else
  disk=$(mount | grep '\ \/\ ' | awk '{printf $1}' | sed -r 's/[0-9]//g');
  grub-install $disk; 
fi

update-grub

EOF

chmod +x /mnt/chrootCommand.sh;
chroot /mnt /chrootCommand.sh;

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

