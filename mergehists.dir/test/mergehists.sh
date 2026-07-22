#!/bin/bash
#
# mergehists.sh - GlueX simulation samples script for production
#                 of benchmark Monte Carlo data on the osg.
#
# author: richard.t.jones at uconn.edu
# version: february 27, 2021
#
# usage: [ run within a GlueX singularity container ]
#        $ ./mergehists.sh <simType> <simId>

xrootdserver="nod27.phys.uconn.edu"
xrootdURL="root://$xrootdserver"
remotepath="/Gluex/simulation/simsamples"
gsiftpURL="gsiftp://nod28.phys.uconn.edu"
httpsURL="https://grinch.phys.uconn.edu:2843"
inputURL="https://gryphn.phys.uconn.edu/halld/simsamples"
wget="wget --ca-directory=/etc/grid-security/certificates"

function usage() {
    echo "Usage: mergehists.sh <simType> <simId>"
    echo "  where <simType> = simulation type name"
    echo "        <simId> = simulation id number, 1..Smax"
}

function clean_exit() {
    ls -l 
    rm -f *rest.root
    if [ "$1" = "" -o "$1" = "0" ]; then
        echo "Successful exit from mergehists."
        exit 0
    fi
    echo "Error $1 in mergehists, $2"
    while true; do
        msg=$(echo "Error $1 in mergehists, $2" | sed 's/ /_/g')
        eval $($wget -O- "$inputURL/scripts/onerror?msg=$msg" 2>/dev/null)
        sleep 10
    done
    exit $1
}

function save_output() {
    maxretry=5
    retry=0
    while [[ $retry -le $maxretry ]]; do
        gfal-copy -f --copy-mode streamed file://`pwd`/$1 $httpsURL/$remotepath/$2 2>gfal-copy.err
        retcode=$?
        if [[ -s gfal-copy.err ]]; then
            cat gfal-copy.err
            retcode=$(expr $retcode + 256)
        fi
        rm gfal-copy.err
        if [[ $retcode = 0 ]]; then
            rm $1
            break
        elif [[ $retry -lt $maxretry ]]; then
            retry=$(expr $retry + 1)
            echo "gfal-copy returned error code $retcode, waiting $retry minutes before retrying"
            sleep $(expr $retry \* 60)
        else
            retry=$(expr $retry + 1)
            echo "gfal-copy returned error code $retcode, giving up"
        fi
    done
    # fall through to allow job file transfer return results, failure not fatal
    mv $1 $(basename $2)
    return 0
}

if [ $# != 2 ]; then
    usage
    exit 
fi

simType=$1
simId=$(expr $2 + 0)
simId3=$(echo $simId | awk '{printf("%03d",$1)}')
echo "job mergehists $simType $simId running on" $(hostname)

unset LD_PRELOAD

inputs=""
for infile in $(xrdfs $xrootdserver ls $remotepath/$simType | grep "/${simType}${simId3}_.*_rest.root"); do
    local_infile=$(basename $infile)
    echo "fetching $xrootdURL/$infile"
    xrdcp $xrootdURL/$infile $local_infile || clean_exit $? "failed to fetch remote file $infile"
    inputs="$inputs $local_infile"
done
if [ "$inputs" = "" ]; then
    clean_exit 1 "nothing to merge!"
fi

hadd merged.root $inputs || clean_exit $? "hadd failed"
save_output merged.root $simType/$simType${simId3}_merged.root || clean_exit $? "save of merged.hddm failed"
clean_exit
