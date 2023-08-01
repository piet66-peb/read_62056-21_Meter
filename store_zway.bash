#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         store_zway.bash
#h Type:         Linux shell script
#h Purpose:      sends sensor value to Z-Way
#h Project:      
#h Usage:        ./store_zway.bash <target ZWay device> <value> &
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    Z-Way
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V3.0.0 2023-05-26/peb
#v History:      V1.0.0 2022-12-09/peb first version
#h Copyright:    (C) piet66 2022
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

MODULE='store_zway.bash';
VERSION='V3.0.0'
WRITTEN='2023-05-26/peb'

TARGET_DEVICE=$1
VALUE=$2

if [ "$STEP" == "" ]
then    
    cd `dirname $0`
    . ./settings
fi

#send data via curl to Z-Way virtual device:
function send_zway() {
    C="curl -sS -u  ${USER_ZWAY} ${URL_ZWAY}${TARGET_DEVICE}/command/exact?level=${VALUE}"
    echo ''
    echo ''
    echo "$C"
    $C
}

#main function:
function main() {
    send_zway
}

LOG="$0".log
date >$LOG
echo $0 $* >>$LOG
echo "TARGET_DEVICE: $TARGET_DEVICE VALUE: $VALUE" >>$LOG

main >>$LOG 2>&1

