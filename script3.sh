#!/bin/bash

##nextscript
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc --utc

echo $hostname > /etc/hostname


sed -i -e 's/MODULES=()/MODULES=(ext4)/g' /etc/mkinitcpio.conf
sed -i -e 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block keyboard keymap encrypt lvm2 filesystems fsck shutdown)/g' /etc/mkinitcpio.conf

sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

if ["$vgname" != ""]
then
	sed 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=$cryptdev:$vgname root=$rootpart"/g' /etc/default/grub
	pwd
fi

mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg
