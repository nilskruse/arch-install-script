#!/bin/bash
##nextscript


read -p 'If using LVM on LUKS enter volume group name): ' vgname
if [ "$vgname" != '' ]
then
	read -p 'And crypt device(e.g. /dev/sda2):' cryptdev
fi
read -p 'Hostname: ' hostname

timedatectl set-local-rtc 0
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc --utc

echo $hostname > /etc/hostname
sed -i -e 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen
sed -i -e 's/#en_DK.UTF-8 UTF-8/en_DK.UTF-8 UTF-8/g' /etc/locale.gen
sed -i -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
localectl --no-convert set-keymap de-latin1-nodeadkeys
localectl set-locale LANG=en_DK.UTF-8
echo KEYMAP=de-latin1-nodeadkeys > /etc/vconsole.conf

sed -i -e 's/MODULES=()/MODULES=(ext4)/g' /etc/mkinitcpio.conf
sed -i -e 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block keyboard keymap encrypt lvm2 filesystems fsck shutdown)/g' /etc/mkinitcpio.conf

sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

if [ "$vgname" != '' ]
then
	sed -i -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=$cryptdev:$vgname\"|g" /etc/default/grub
fi

mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Set root password'
passwd

read -p "Enter username: " name

groupadd $name
useradd -m -g $name -G wheel,storage,power,network,uucp -s /bin/zsh $name
passwd $name
echo "Set password for $name"
passwd $name

systemctl enable NetworkManager
