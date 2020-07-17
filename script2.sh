#!/bin/bash

#ask for partitions
read -p 'EFI partition( e.g. /dev/sda1): ' efipart
read -p 'swap partition( e.g. /dev/sda3 or /dev/mapper/vg0-swap): ' swappart
read -p 'root partition( e.g. /dev/sda2 or /dev/mapper/vg0-root): ' rootpart

mkfs.ext4 -L root $rootpart
mkswap $swappart
mkfs.vfat -F32 -n EFI $efipart

mount $rootpart /mnt
mkdir /mnt/boot
mount $efipart /mnt/boot
swapon $swappart


reflector --country Germany --protocol https --sort rate --save /etc/pacman.d/mirrorlist


pacstrap /mnt linux linux-firmware sudo zsh git base base-devel networkmanager vim grub lvm2 efibootmgr dosfstools intel-ucode --noconfirm

genfstab -pU /mnt | tee -a /mnt/etc/fstab

#run next
#arch-chroot /mnt