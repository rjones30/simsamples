#!/bin/bash
#
# hold_stickers.sh - script to look for stuck jobs running on the osg
#                    and place them on hold if they have been running
#                    for longer than a certain number of hours.
#
# author: richard.t.jones at uconn.edu
# version: march 27, 2024

function usage {
    echo "usage: hold_stickers.sh <hours>"
    exit 1
}

if [ $# != 1 ]; then
    usage
elif ! echo $1 | grep -q '[1-9][0-9]*'; then 
    usage
else
    maxminutes=$(expr $1 \* 60)
fi

condor_q -run -current | awk -F'[+: ]+' '/^[1-9].*@/{
    runminutes = $8 + 60 * ($7 + 24 * $6);
    if (runminutes > '$maxminutes') {
       print "condor_hold", $1
    }
}'
