#!/bin/bash

cat << EOF > /mnt/chrootCommand.sh

normalSTTYState=\$(stty -g);

while [ true ]; do
  echo -n "Hasło dla użytkownika root: ";
  stty -echo;
  read rootPasswd;
  stty \$normalSTTYState;
  echo;
  if [ "\$rootPasswd" ]; then
    break;
  fi
done
echo "root:\$rootPasswd" | chpasswd;

while [ true ]; do
  echo -n "Nazwa dla nowego użytkownika: ";
  read userName;
  if [ "\$userName" ]; then 
    break;
  fi
done

echo -n "Domyślna powłoka dla nowego użytkownika [/bin/bash]: ";
read defaultShell;
if [ ! "\$defaultShell" ]; then 
  defaultShell='/bin/bash'; 
fi;

while [ true ]; do
  echo -n "Hasło dla nowego użytkownika: ";
  stty -echo;
  read userPasswd;
  echo;
  stty \$normalSTTYState;
  if [ "\$userPasswd" ]; then
    break;
  fi
done

useradd -m -s \$defaultShell \$userName;
echo "\${userName}:\${userPasswd}" | chpasswd;

echo "\$userName ALL=(ALL:ALL) ALL" >> /etc/sudoers;

if [ -d /sys/firmware/efi/efivars ]; then
  apt update;
  apt install grub-efi;
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=debian;
else
  disk=\$(mount | grep '\ \/\ ' | awk '{printf \$1}' | sed -r 's/[0-9]//g');
  grub-install \$disk; 
fi

update-grub

EOF

chmod +x /mnt/chrootCommand.sh;
chroot /mnt /chrootCommand.sh;
