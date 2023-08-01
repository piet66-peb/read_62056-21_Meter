#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         get_procid.bash
#h Type:         Linux shell script
#h Purpose:      gets the process, displays start/ stop command
#h Project:      
#h Usage:        ./get_procid.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2023-06-24/peb
#v History:      V1.0.0 2022-12-11/peb first version
#h Copyright:    (C) piet66 2022
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

MODULE='get_procid.bash';
VERSION='V1.0.0'
WRITTEN='2023-06-24/peb'

. `dirname $(readlink -f $0)`/00_constants >/dev/null

PROC=`pwd`/$BASH_NAME
ret=`ps -efj | egrep "$PROC" | grep -v grep | grep -v PGID`

echo ''
if [ "$ret" == "" ]
then    
    echo process $PROC is not started
else
    #echo ret=$ret
    user==`echo $ret | cut -f1 -d' '`
    procid=`echo $ret | cut -f2 -d' '`
    grpid=`echo $ret | cut -f4 -d' '`
    pstree -ahclp $procid
    echo ''
    echo kill all processes of $PROC, user$user with:
    echo "kill -- -$grpid"
fi

echo ''
echo 'start'
echo 'in foreground with:'
echo $PROC
echo 'in background with:'
echo $PROC '>/dev/null 2>&1 &'
echo ''

