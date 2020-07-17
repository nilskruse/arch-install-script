#!/bin/bash

# testing script that sets up encrypted volumes
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $1
  g # clear the in memory partition table
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 100 MB boot parttion
  t # change type
  1 # 1=EFI
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  p # print the in-memory partition table
  w # write the partition table
EOF


cryptsetup luksFormat "${1}2"
cryptsetup open "${1}2" luks

vgcreate vg0 /dev/mapper/luks
lvcreate -L 2G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root