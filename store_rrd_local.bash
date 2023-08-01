#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         store_rrd_local.bash
#h Type:         Linux shell script
#h Purpose:      stores sensor value(s) to rrd database
#h Project:      
#h Usage:        ./store_rrd_local.bash <timestamp> <colon separated value(s)> &
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    rrdtool
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.1 2023-05-27/peb
#v History:      V1.0.0 2022-12-09/peb first version
#h Copyright:    (C) piet66 2022
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

MODULE='store_rrd_local.bash';
VERSION='V1.0.1'
WRITTEN='2023-05-27/peb'

TS=$1
VALUE=$2

if [ "$RRD_FILE" == "" ]
then    
    cd `dirname $0`
    . ./settings
fi

#store data to local RRDtool database:
function store_rrb_local() {
    pushd $RRD_DIR >/dev/null
        echo ''
        C="rrdtool updatev $RRD_FILE $TS:$VALUE"
        echo $C
        $C
    popd >/dev/null
}

#main function:
function main() {
    if [ -d "$RRD_DIR" ] && [ -e "$RRD_DIR/$RRD_FILE" ]
    then
        store_rrb_local
    else
        echo no rrd settings defined
    fi
}

LOG="$0".log
date >$LOG
echo $0 $* >>$LOG
echo "TS: $TS VALUE: $VALUE" >>$LOG

main >>$LOG 2>&1

