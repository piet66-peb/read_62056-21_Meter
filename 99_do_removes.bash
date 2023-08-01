#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         do_removes.bash
#h Type:         Linux shell script
#h Purpose:      do some removes:
#h               removes cron task for read_62056-21.bash
#h Project:      
#h Usage:        ./do_removes.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Debian Linux (Raspberry Pi OS, Ubuntu)
#h Authors:      peb piet66
#h Version:      V1.0.0 2023-06-22/peb
#v History:      V1.0.0 2022-12-09/peb first version
#h Copyright:    (C) piet66 2022
#h License:      http://opensource.org/licenses/MIT
#h
#h-------------------------------------------------------------------------------

MODULE='do_removes.bash';
VERSION='V1.0.0'
WRITTEN='2023-06-22/peb'

#exit when any command fails
set -e

#set path constants
. `dirname $(readlink -f $0)`/00_constants

#remove cron
function cron_remove_line {
    l="$1"
    crontab -l
    if [ $? -eq 0 ]
    then
        echo remove line if existing:
        X=`crontab -l | sed "\:$l:d"`
        crontab -r 
        echo "$X" | crontab -
    fi
}

echo removing cron-job for user $USER...
set +e
cron_remove_line "@reboot $PACKET_PATH/$BASH_NAME >/dev/null 2>&1"  >/dev/null 2>&1

