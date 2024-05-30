#!/bin/bash

echo -e "\nTransfer U-Boot & Linux to target device\n"

[ $# -lt 2 ] && echo "Please input target device, e.g. ./mksd-linux.sh /dev/mmcblk0 image_name" && exit 1
[ ! -e $1 ] && echo "Device $1 not found" && exit 1
[ ! -e $2 ] && echo "Image file $2 not found" && exit 1
[ "`cat /sys/block/${1##*/}/device/type`" == "SD" ] && echo "Device $1 is type of SD." && exit 1

echo "All data on "$1" now will be destroyed! Continue? [y/n]"
read ans
if [ $ans != 'y' ]; then exit 1; fi

echo 0 > /proc/sys/kernel/printk

check_node=`echo $1 | grep mmc`
if [ -n "$check_node" ];then
        part="p"
fi

echo "[Unmounting all existing partitions on the device ]"

umount $1* &> /dev/null

echo "[Partitioning $1...]"
DRIVE=$1

#cd ../image

#filename=`ls | grep 1.bin`
#
#if [ $filename ];then
#    echo "[Copy $filename image]"
#    #dd if=$filename of=$1 &>/dev/null
#    dd if=$filename of=$1 conv=fsync status=progress
#else
#    echo No such Image file
#    exit 1
#fi
filename=$2

if [ $filename ];then
    echo "[Copy $filename image]"
    #dd if=$2 of=$1 &>/dev/null
    dd if=$2 of=$1 conv=fsync status=progress
else
    echo No such Image file
    exit 1
fi


echo "[Resize filesystems...]"

rootfs_start=`fdisk -u -l ${DRIVE} | grep ${DRIVE}${part}2 | awk '{print $2}'`

# Create partition table for extend root file system (/dev/mmcblk1p2) partition
fdisk -u $DRIVE << EOF &>/dev/null
d
2
n
p
$rootfs_start

w
EOF

if [ -x /sbin/partprobe ]; then
    /sbin/partprobe ${DRIVE} &> /dev/null
else
    sleep 1
fi

e2fsck -f -y ${DRIVE}${part}2 &> /dev/null
resize2fs ${DRIVE}${part}2 &> /dev/null

if [ -x /sbin/partprobe ]; then
    /sbin/partprobe ${DRIVE} &> /dev/null
else
    sleep 1
fi

echo 7 > /proc/sys/kernel/printk
echo "[Done]"

