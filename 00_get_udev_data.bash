#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         00_get_udev_data.bash
#h Type:         Linux shell script
#h Purpose:      selects udev data of given serial device
#h               and constructs the new line for /etc/udev/rules.d/99-usb-serial.rules
#h Project:      
#h Usage:        ./00_get_udev_data.bash <device> <new link name>
#h Result:       
#h Examples:     ./00_get_udev_data.bash /dev/ttyUSB0 electric_meter
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2023-06-24/peb
#v History:      V1.0.0 2023-06-12/peb first version
#h Copyright:    (C) piet66 2023
#h License:      http://opensource.org/licenses/MIT
#h
#h-------------------------------------------------------------------------------

MODULE='00_get_udev_data.bash';
VERSION='V1.0.0'
WRITTEN='2023-06-24/peb'

#exit when any command fails
set -e

if [ $# -lt 2 ]
then
    echo 'usage: ./00_get_udev_data.bash <device> <new link name>'
    echo 'example: ./00_get_udev_data.bash /dev/ttyUSB0 electric_meter'
    echo ''
    exit 1
fi

echo +++ detecting the necessary data...
DEV=$1
echo DEV=$DEV
if [ ! -c "$DEV" ]
then
    echo device $DEV not found, break!
    exit 1
fi

function get_data() {
    dline=`udevadm info -a -n $DEV| grep "{$dtype}" | head -n1`
    #echo $dline
    a="${dline#*\"}"        #remove first part till '"'
    dvalue="${a%\"*}"       #remove last part from '"' on
    echo $dvalue
}

dtype=idVendor
idVendor=`get_data $dtype`
echo idVendor = $idVendor
idVendorP=ATTRS{idVendor}==\"$idVendor\"

dtype=idProduct
idProduct=`get_data $dtype`
echo idProduct = $idProduct
idProductP=ATTRS{idProduct}==\"$idProduct\"

dtype=serial
serial=`get_data $dtype`
echo serial = $serial
serialP=ATTRS{serial}==\"$serial\"

link=$2
linkP=SYMLINK+=\"$link\"

owner=$USER
ownerP=OWNER=\"$owner\"

target_file=/etc/udev/rules.d/99-usb-serial.rules

echo
echo +++ add this line to the file $target_file:
echo SUBSYSTEM==\"tty\", $idVendorP, $idProductP, $serialP, $linkP, $ownerP
echo
echo +++ and run these commands:
echo sudo udevadm control --reload-rules
echo sudo udevadm trigger
echo ls -l /dev/$link

