#!/bin/bash
#
# mergehists.sh - script to merge together the monitoring histograms
#                 that are produced during reconstruction of single
#                 particle gun simulations in GlueX.
#
# author: richard.t.jones at uconn.edu
# version: march 9, 2021
#
# usage: [ run within a GlueX singularity container ]
#        $ ./mergehists.sh <simDir> <simType> <simId>

simdataroot=root://nod29.phys.uconn.edu/Gluex/simulation/simsamples
outputURL=srm://grinch.phys.uconn.edu:8443/Gluex/simulation/simsamples
inputURL=https://gryphn.phys.uconn.edu/halld/simsamples

function usage() {
    echo "Usage: mergehists.sh <simDir> <simType> <simId>"
    echo "  where <simDir> = simulation data directory"
    echo "        <simType> = simulation type name"
    echo "        <simNo> = simulation id number, 0..Smax-1"
}

function clean_exit() {
    ls -l 
    rm -f setup *.root
    if [ "$1" = "" -o "$1" = "0" ]; then
        echo "Successful exit from mergehists."
        exit 0
    fi
    while true; do
        $($wget -O- $inputURL/onerror 2>/dev/null)
        sleep 10
    done
    echo "Error $1 in mergehists, $2"
    exit $1
}

if [ $# != 3 ]; then
    usage
    exit 
fi

simDir=$1
simType=$2
simId=$(echo $3 | awk '{printf("%03d", $1+1)}')
echo "job $simDir ($simType $simId) running on" $(hostname)

wget="wget --ca-directory=/usr/grid-security/certificates"
$wget -O setup $inputURL/setup.sh 2>/dev/null || clean_exit $? "cannot fetch setup.sh from web server"
jobType=mergehists source ./setup
mergedfile=$simType${simId}_merged.root
inputlist=$(ls $simdataroot/$simDir | awk "/$simType${simId}_.*.root"/'{print "'$simdataroot'/'$simDir'/"$1}')
hadd $mergedfile $inputlist || clean_exit $? "hadd crashed"
srmcp -overwrite_mode=ALWAYS file://`pwd`/$mergedfile $outputURL/$simDir/$mergedfile || clean_exit $? "save of sample.hddm failed"
clean_exit
