#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         read_meter_RRDtool.bash
#h Type:         Linux shell script
#h Purpose:      in an infinite loop:
#h                   reads value(s) from electric meter via infrared interface (optical
#h                   interface) and forwards them for processing.
#h               This version of script read_meter.bash stores the data to a round 
#h               robin database.
#h               At startup, the script reads the STEP and NEXT parameters from the database
#h               to always use the correct timestamp that the database expects.
#h Installation: 
#h Project:      
#h Usage:        1. start manually:
#h                 <path>/<script> >/dev/null 2>&1 &
#h               2. run with cron:
#h                 crontab -e
#h                 and enter:
#h                   @reboot  <path>/<script> >/dev/null 2>&1
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    stty, curl
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V3.1.0 2024-04-06/peb
#v History:      V1.0.0 2022-05-31/peb first version
#h Copyright:    (C) piet66 2022
#h License:      MIT
#h
#h-------------------------------------------------------------------------------

MODULE='read_meter_RRDtool.bash';
VERSION='V3.1.0'
WRITTEN='2024-04-06/peb'

DIR=`dirname $0`
cd $DIR
PWD=`pwd`
SN=`basename $0`
[ "$DIR" != "$PWD" ] && exec $PWD/$SN   #restart with full path

LOG=$SN.log
date >$LOG

LOG_SLEEP=${SN}_SLEEP.log
LOG_READ=${SN}_READ.log

#b write start message to syslog
#-------------------------------
logger -i "$PWD $SN $VERSION $WRITTEN started."

#b kill all child processes at end
#---------------------------------
trap "pkill -SIGTERM -P $$; exit" SIGINT SIGTERM

#b take settings
#---------------
DISABLE_BAUD_RATE_CHANGEOVER = false
. ./settings >>$LOG 2>&1
NEXT=

if [ ! -c "$DEV" ]
then
    mess="serial input IR device $DEV not found, waiting..."
    logger -is "$SN $mess" >>$LOG 2>&1

    #wait 1 minute after boot till device is ready
    sleep 1m
    if [ ! -c "$DEV" ]
    then
        mess="serial input IR device $DEV not found, exit!"
        logger -is "$SN $mess" >>$LOG 2>&1
        exit 1
    fi
fi

#b read rrb parameters
#---------------------
if [ "$STORE_LOCAL_RRD" == true ] || [ "$STORE_REMOTE_RRD" == true ]
then
    . ./rrd_info.bash >>$LOG 2>&1
fi

#b functions
#-----------
# -------------------------------------------------------------------------------
#  Name:         delay
#  Purpose:      computes sleep time for next request ($sleep_secs)
# -------------------------------------------------------------------------------
function delay() {
    currtime=$(date +%s)             #current time in seconds
    [ "$next_run" == "" ] && next_run=currtime
    (( sleep_secs=next_run-currtime ));       # delay time in seconds
}

# -------------------------------------------------------------------------------
#  Name:         compute_rrd_time
#  Purpose:      computes correct timestamp for rrdtool database
# -------------------------------------------------------------------------------
function compute_rrd_time() {
    step=$STEP
    currtime=$(date +%s)             #current time in seconds
    (( rrd_time=(currtime/step)*step ));
    echo "currtime=$currtime"
    echo "rrd_time=$rrd_time"
}

# -------------------------------------------------------------------------------
#  Name:         create_pull_loop
#  Purpose:      trigger request 6.3.1 in infinite loop
#                synchronized with $NEXT and $STEP
# -------------------------------------------------------------------------------
function create_pull_loop() {
    echo invoke pull loop
    next_run=$NEXT
    echo next_run=$next_run
    while true
    do
        delay

        echo ''
        echo --- next request in $sleep_secs seconds...
        [ $sleep_secs -gt 0 ] && sleep $sleep_secs

        #in case of wrong baud rate, caused by communication issue:
        BAUD=`stty -F $DEV speed`
        if [ $BAUD -ne $BAUD_INI ]
        then
            date >>$LOG_SLEEP
            cat $LOG_READ >>$LOG_SLEEP
            echo --- current baud rate: $BAUD | tee -a $LOG_SLEEP
            BAUD=$BAUD_INI
            stty -F $DEV $BAUD
            echo --- baud rate set to $BAUD | tee -a $LOG_SLEEP
            [ -x "sendEmail.bash" ] && ./sendEmail.bash "baud rate set to $BAUD" &
        fi

        echo -n -e '/?!\r\n' > $DEV
        last_run=$next_run
        (( next_run=last_run+STEP ));
    done
}

#b commands
#----------
    #b set serial interface parameters
    #---------------------------------
    [ "$IEC_62056_21_MODE" != "D" ] && BAUD_INI=300 #default, except for mode D
    #7E1, no flow control, no handshake:
    stty -F $DEV $BAUD_INI -parodd cs7 -cstopb parenb -ixoff -crtscts -hupcl -ixon -opost -onlcr -isig -icanon -iexten -echo -echoe -echoctl -echoke
    BAUD=$BAUD_INI
  
    #b if no push mode: trigger request 6.3.1 in infinite loop
    #---------------------------------------------------------
    [ "$IEC_62056_21_MODE" != "D" ] && create_pull_loop $NEXT $STEP &

    #b in infinite loop
    #------------------
    rm -f $LOG_READ
    while true
    do
        #b listening with target baud rate
        #---------------------------------
        BAUD_curr=`stty -F $DEV speed`
        [ $BAUD_curr -ne  $BAUD ] && stty -F $DEV $BAUD
        echo listening to $DEV with `stty -F $DEV speed` baud... | tee -a $LOG_READ
        count_secs=-1   #for push mode
        while read line
        do
            [ "$line" == "" ] && continue
            echo "$line" | tee $LOG_READ

            case "$line" in 
                #b ident message 6.3.2 
                #---------------------
                /*)
                    val180=

                    if [ "$IEC_62056_21_MODE" == "D" ]
                    then
                        count_secs=$(($count_secs+1))
                        [ $count_secs -gt $STEP ] && count_secs=0
                    fi

                    V=0    # Protocol control character (see 6.4.5.2), 0=normal protocol
                    Z=0    # Baud rate identification, 0=300, 4=4800, 5=9600
                    Y=0    # Mode control character (see 6.4.5.3), 0=data readout
                    # /xxxZ: Z=possible baud rate
                    Z=${line:4:1}  #take 5th character from line
                    if [ "$IEC_62056_21_MODE" == "B" ]
                    then
                        Z=`printf '%d' "'$Z"`; Z=$(($Z-65)) #character to number
                    fi

                    if [ "$IEC_62056_21_MODE" == "C" ]  #send ack 6.3.3 with baud switchover
                    then
                        [ "$DISABLE_BAUD_RATE_CHANGEOVER" == true ] && Z=0
                        ACK='\x06'$V$Z$Y
                        echo $ACK | tee -a $LOG_READ
                        echo -n -e $ACK'\r\n' > $DEV
                    fi

                    (( BAUD_NEW=300*2**Z ))
                    if [ $BAUD -ne $BAUD_NEW ]
                    then
                        # remark: timing problem between ACK and stty -F $DEV $BAUD:
                        # - switching too fast >> meter doesn't get ACK
                        # - switching too slow >> response of meter is lost
                        BAUD=$BAUD_NEW
                        echo switching to baud rate $BAUD
                        break
                    fi
                    ;;
    
                #b OBIS 1.8.0: strip value
                #-------------------------
                *1.8.0*)
                    if [ "$IEC_62056_21_MODE" == "D" ]
                    then
                        [ $count_secs -ne 0 ] && continue
                    fi

                    #parameter expansion:
                    a="${line#*\(}"         #remove first part till '('
                    val180="${a%\**}"       #remove last part from '*' on
                    ;;

                #b end of datablock 6.3.4: 
                #b store data, break listening and reset baud rate for next request
                #------------------------------------------------------------------
                !)
                    if [ "$val180" != "" ] && [ "$STORE_LOCAL_RRD" == true ]
                    then
                        compute_rrd_time
                        val180Wh=${val180/./}   #real >>> integer, kWh >>> Wh
                        values=${val180}:${val180Wh}
                        echo ">> ./store_rrd_local.bash $rrd_time $values"
                        ./store_rrd_local.bash $rrd_time $values &
                    fi
    
                    if [ "$val180" != "" ] && [ "$STORE_REMOTE_RRD" == true ]
                    then
                        compute_rrd_time
                        val180Wh=${val180/./}   #real >>> integer, kWh >>> Wh
                        values=${val180}:${val180Wh}
                        echo ">> ./store_rrd_remote.bash $rrd_time $values"
                        ./store_rrd_remote.bash $rrd_time $values &
                    fi
    
                    if [ $BAUD -ne $BAUD_INI ]
                    then
                        BAUD=$BAUD_INI
                        break
                    fi
                    ;;
            esac
        done <"$DEV"
        echo ''
    done
