#!/bin/bash
#
# mergehists.sh - GlueX simulation samples script for production
#                 of benchmark Monte Carlo data on the osg.
#
# author: richard.t.jones at uconn.edu
# version: february 27, 2021
# revised: june 30, 2026
#
# usage: [ run within a GlueX singularity container ]
#        $ ./mergehists.sh <simType> <simId>

#xrootdserver="grinch.phys.uconn.edu"
xrootdserver="nod60.phys.uconn.edu"
xrootdURL="root://$xrootdserver"
#xrootdURL="/cvmfs/gluex.osgstorage.org"
remotepath="/gluex/uconn1/rawdata/simulation/simsamples"
#remotepath="/gluex/uconn0/simulation/simsamples"
#httpsURL="https://grinch.phys.uconn.edu:2843"
httpsURL="https://nod60.phys.uconn.edu:2843"
inputURL="https://gryphn.phys.uconn.edu/halld/simsamples"
wget="wget --ca-directory=/etc/grid-security/certificates"

vtoken="$(pwd)/vt_u7896"
export XDG_RUNTIME_DIR=$(pwd)

function usage() {
    echo "Usage: mergehists.sh <simType> <simId>"
    echo "  where <simType> = simulation type name"
    echo "        <simId> = simulation id number, 1..Smax"
}

function clean_exit() {
    ls -l 
    rm -f *rest.root setup
    if [ "$1" = "" -o "$1" = "0" ]; then
        echo "Successful exit from mergehists."
        exit 0
    fi
    echo "Error $1 in mergehists, $2"
    while true; do
        msg=$(echo "Error $1 in mergehists, $2" | sed 's/ /_/g')
        eval $($wget -O- "$inputURL/scripts/onerror?msg=$msg" 2>/dev/null)
        sleep 10 || break
    done
    exit $1
}

function save_output() {
    maxretry=5
    retry=0
    while [[ $retry -le $maxretry ]]; do
        gfal-copy -f --copy-mode streamed \
           -D "BEARER:TOKEN=$BEARER_TOKEN" \
           file://`pwd`/$1 $httpsURL/$remotepath/$2 2>gfal-copy.err
        retcode=$?
        if [[ -s gfal-copy.err ]]; then
            cat gfal-copy.err
            retcode=$(expr $retcode + 256)
        fi
        rm gfal-copy.err
        if [[ $retcode = 0 ]]; then
            rm $1
            return 0
        elif [[ $retry -lt $maxretry ]]; then
            retry=$(expr $retry + 1)
            echo "gfal-copy returned error code $retcode, waiting $retry minutes before retrying"
            sleep $(expr $retry \* 60)
        else
            retry=$(expr $retry + 1)
            echo "gfal-copy returned error code $retcode, giving up"
        fi
    done
    if [[ -r $1 ]]; then
        mv $1 $(basename $2)
    fi
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

$wget -O setup $inputURL/scripts/setup_alma9_container.sh 2>/dev/null || clean_exit $? "cannot fetch setup.sh from web server"
source ./setup

bearer_token=$(curl -s -X POST https://gryphn.phys.uconn.edu/halld/token \
            --data-urlencode "vault_token=$(cat $vtoken)" \
            --data-urlencode "min_lifetime=1200" \
            | python3 -c "import sys,json; print(json.load(sys.stdin)['bearer_token'])")
[[ -n $bearer_token ]] || clean_exit 1 "error fetching bearer token from vault proxy"
export BEARER_TOKEN=$bearer_token

inputs=""
for infile in $(xrdfs $xrootdserver ls $remotepath/$simType | grep "/${simType}${simId3}_.*_rest.root"); do
    local_infile=$(basename $infile)
    echo "reading from $xrootdURL/$infile"
    #xrdcp $xrootdURL/$infile $local_infile || clean_exit $? "failed to fetch remote file $infile"
    inputs="$inputs $xrootdURL/$infile"
done
if [ "$inputs" = "" ]; then
    clean_exit 1 "nothing to merge!"
fi

hadd merged.root $inputs || clean_exit $? "hadd failed"
save_output merged.root $simType/$simType${simId3}_merged.root || clean_exit $? "save of merged.hddm failed"
clean_exit
