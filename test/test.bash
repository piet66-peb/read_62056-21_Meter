#!/bin/bash

# Linux name of the serial input device:
DEV=/dev/ttyUSB0
DEV=/dev/electric_meter

# baud rate for the serial interface (change for mode D):
BAUD=300

# settings of the serial interface:
stty -F $DEV sane
stty -F $DEV $BAUD -parodd cs7 -cstopb parenb -ixoff -crtscts -hupcl -ixon -opost -onlcr -isig -icanon -iexten -echo -echoe -echoctl -echoke

# request data from meter (not necessary for mode D):
echo -n -e '/?!\r\n' > $DEV

# endless listening for meter data, break with Ctrl+c:
cat $DEV


