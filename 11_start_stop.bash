#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         start_stop.bash
#h Type:         Linux shell script
#h Purpose:      gets the process, displays start/ stop command
#h Project:      
#h Usage:        ./start_stop.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2023-06-24/peb
#v History:      V1.0.0 2023-06-12/peb first version
#h Copyright:    (C) piet66 2023
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

#b constants
#-----------
MODULE='start_stop.bash';
VERSION='V1.0.0'
WRITTEN='2023-06-24/peb'

#b read constants
#----------------
. `dirname $(readlink -f $0)`/00_constants >/dev/null

#b variables
#-----------
_self="${0##*/}"
WD=`pwd`
cd `dirname $0`

#b functions
#-----------
print_status () {
   if [ "$ret" == "" ]
   then    
       echo process $PROC is not started
   else
       #echo ret=$ret
       user==`echo $ret | cut -f1 -d' '`
       procid=`echo $ret | cut -f2 -d' '`
       #echo PI=$procid
       pstree -ahclp $procid
   fi
}

do_start () {
    echo $PROC '>/dev/null 2>&1 &'
    $PROC >/dev/null 2>&1 &
    sleep 1
    ret=`ps -efj | egrep "$PROC" | grep -v grep | grep -v PGID`
    print_status
}

do_stop () {
    while [ "$ret" != "" ]
    do
        grpid=`echo $ret | cut -f4 -d' '`
        echo "kill -- -$grpid"
        kill -- -$grpid
        sleep 1
        ret=`ps -efj | egrep "$PROC" | grep -v grep | grep -v PGID`
    done
    print_status
}

print_commands () {
    ./11_get_procid.bash
}

#b check if started
#------------------
PROC=`pwd`/$BASH_NAME
ret=`ps -efj | egrep "$PROC" | grep -v grep | grep -v PGID`

#b display menu
#--------------
if [ "$ret" == "" ]
then
    option=`./bashmenu.bash $BASH_NAME start "start in foreground" status`
else
    option=`./bashmenu.bash $BASH_NAME stop status`
fi

#b execute
#---------
case $option in
    "status") 
        print_status
        ;;
    "start in foreground") 
        echo $PROC
        $PROC
        ;;
    "start") 
        do_start
        ;;
    "stop")
        do_stop
        ;;
    "break")
        ;;
    "")
        print_commands
        ;;
esac
