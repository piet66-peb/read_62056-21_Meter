#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         store_rrd_remote.bash
#h Type:         Linux shell script
#h Purpose:      stores sensor value(s) to rrd database
#h Project:      
#h Usage:        ./store_rrd_remote.bash <timestamp> <colon separated value(s)> &
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    RRDTool_API
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V3.0.1 2023-05-27/peb
#v History:      V1.0.0 2022-12-09/peb first version
#h Copyright:    (C) piet66 2022
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

MODULE='store_rrd_remote.bash';
VERSION='V3.0.1'
WRITTEN='2023-05-27/peb'

TS=$1
VALUE=$2

LOG="$0".log
date >$LOG
echo $0 $* >>$LOG
echo "TS: $TS VALUE: $VALUE" >>$LOG

if [ "$IP_RRD" == "" ]
then    
    echo 'settings' >>$LOG
    . `dirname $0`/settings
fi

#send data to RRDTool_API:
function store_rrd_remote() {
    C="curl -sS -u ${USER_RRD} -X POST ${URL_RRD}/updatev?ts=$TS&values=$VALUE"
    echo ''
    echo $C
    response=`$C`
    echo $response | python -m json.tool
    [ $? -ne 0 ] && echo $response

}

#main function:
function main() {
    if [ "$URL_RRD" != "" ]
    then    
        store_rrd_remote
    else
        echo no rrd settings defined
    fi
}

main >>$LOG 2>&1

