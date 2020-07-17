#!/bin/bash

#ask for partitions
read -p 'EFI partition( e.g. /dev/sda1): ' efipart
read -p 'swap partition( e.g. /dev/sda3 or /dev/mapper/vg0-swap): ' swappart
read -p 'root partition( e.g. /dev/sda2 or /dev/mapper/vg0-root): ' rootpart
read -p 'If using LVM on LUKS enter volume group name): ' vgname
if [ "$vgname" != '' ]
then
	read -p 'And crypt device(e.g. /dev/sda2):' cryptdev
fi
read -p 'Hostname: ' hostname


mkfs.ext4 $rootpart
mkswap $swappart
mkfs.fat -F32 $efipart

mount $rootpart /mnt
mkdir /mnt/boot
mount $efipart /mnt/boot
swapon $swappart


reflector --country Germany --protocol https --sort rate --save /etc/pacman.d/mirrorlist


pacstrap /mnt linux linux-firmware sudo zsh git base base-devel networkmanager vim grub lvm2 efibootmgr dosfstools intel-ucode --noconfirm

genfstab -pU /mnt | tee -a /mnt/etc/fstab

#run next
arch-chroot /mnt
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
