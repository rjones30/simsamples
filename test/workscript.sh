#!/bin/bash
#
# workscript.sh - GlueX simulation samples script for production
#                 of benchmark Monte Carlo data on the osg.
#
# author: richard.t.jones at uconn.edu
# version: february 27, 2021
# revision: jun 30, 2026
#
# usage: [ run within a GlueX singularity container ]
#        $ ./workscript.sh <simType> <simId> <seqNo>

runNo=150000
nthreads=1
nevents=100
ticker=0

remotepath="/Gluex/rawdata/simulation/simsamples"
httpsURL="https://nod60.phys.uconn.edu:2843"
#remotepath="/Gluex/simulation/simsamples"
#httpsURL="https://grinch.phys.uconn.edu:2843"
inputURL="https://gryphn.phys.uconn.edu/halld/simsamples"
wget="wget --ca-directory=/etc/grid-security/certificates"

vtoken="$(pwd)/vt_u7896"
export XDG_RUNTIME_DIR=$(pwd)

function usage() {
    echo "Usage: workscript.sh <simType> <simId> <seqNo>"
    echo "  where <simType> = simulation type name"
    echo "        <simId> = simulation id number, 1..Smax"
    echo "        <seqNo> = job sequence number, 1..Jmax"
}

function clean_exit() {
    ls -l 
    #rm -f setup sim.sh control.in randoms worklist smear.root sample*.hddm dana_rest.hddm hd_root.root tree*.root *.hbook *.rz *.dat tmp.* *.astate
    if [ "$1" = "" -o "$1" = "0" ]; then
        echo "Successful exit from workscript."
        exit 0
    fi
    echo "Error $1 in workscript, $2"
    while true; do
        msg=$(echo "Error $1 in workscript, $2" | sed 's/ /_/g')
        eval $($wget -O- "$inputURL/scripts/onerror?msg=$msg" 2>/dev/null)
        sleep 10 || break
    done
    exit $1
}

function save_output() {
    maxretry=5
    retry=0
    while [[ $retry -le $maxretry ]]; do
        bearer_token=$(curl -s -X POST https://gryphn.phys.uconn.edu/halld/token \
            --data-urlencode "vault_token=$(cat $vtoken)" \
            --data-urlencode "min_lifetime=1200" \
            | python3 -c "import sys,json; print(json.load(sys.stdin)['bearer_token'])")
        [[ -n $bearer_token ]] || clean_exit 1 "error fetching bearer token from vault proxy"
        gfal-copy -f --copy-mode streamed \
           -D "BEARER:TOKEN=$bearer_token" \
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

if [ $# != 3 ]; then
    usage
    exit 
fi

simType=$1
simId=$(expr $2 + 0)
seqNo=$(expr $3 + 1)
simId3=$(echo $simId | awk '{printf("%03d",$1)}')
seqNo3=$(echo $seqNo | awk '{printf("%03d",$1)}')
echo "job $simType $simId $seqNo running on" $(hostname)

$wget -O setup $inputURL/scripts/setup_alma9_container.sh 2>/dev/null || clean_exit $? "cannot fetch setup.sh from web server"
$wget -O worklist $inputURL/config/worklist.in 2>/dev/null || clean_exit $? "cannot fetch worklist.in from web server"
$wget -O control.in $inputURL/$simType.d/sim_$simId3/control.in 2>/dev/null || clean_exit $? "cannot fetch control.in from web server"
$wget -O randoms $inputURL/config/randoms.in 2>/dev/null || clean_exit $? "cannot fetch randoms.in from web server"
rseeds=$(head -n $seqNo randoms | tail -n1)
jmax=$(awk "/^$simType/{if(\$2+0==$simId+0){print \$3}}" worklist)
echo $jmax | grep -q '[0-9][0-9]*' || clean_exit $? "cannot find simsample $simId in worklist"
[ $seqNo -ge 0 -a $seqNo -le $jmax ] || clean_exit $? "simulation seqNo $seqNo is out of range"
sed -i "s/^RNDM.*/RNDM $rseeds/" control.in || clean_exit $? "RNDM card not found in control.in"
sed -i "s/^RUN[NG].*/RUNNO $runNo/" control.in || clean_exit $? "RUN card not found in control.in"
sed -i "s/^OUTF.*/OUTFILE 'sample.hddm'/" control.in || clean_exit $? "OUTF card not found in control.in"
sed -i "s/^TRIG.*/TRIG $nevents/" control.in || clean_exit $? "TRIG card not found in control.in"

export CCDB_CONNECTION="sqlite:////srv/config/ccdb_fixed_CarbonFiberEpoxy-7-1-2026.sqlite"
export JANA_CALIB_URL=$CCDB_CONNECTION
export JANA_GEOMETRY_URL="ccdb://GEOMETRY/main_HDDS.xml"
export JANA_CALIB_CONTEXT="variation=mc"
#export JANA_CALIB_CONTEXT="variation=mc_no_mergehits"
#export JANA_CALIB_CONTEXT="variation=fdcwires_test"

if [ "$simType" = "particle_gun" ]; then
    simApp=hdgeant4
    cat setup > sim.sh
    echo "which $simApp" >> sim.sh
    echo "$simApp" >> sim.sh
else
    simApp=/cvmfs/oasis.opensciencegrid.org/gluex/halld_sim/Linux_Alma9-x86_64-gcc11.5.0/bin/hdgeant
    cat setup > sim.sh
    echo "export LD_PRELOAD=/cvmfs/oasis.opensciencegrid.org/gluex/JANA2/x86_64-alma9/lib/libJANA.so" >> sim.sh
    echo export PATH=$(echo $PATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}') >> sim.sh
    echo export PYTHONPATH=$(echo $PYTHONPATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}') >> sim.sh
    echo export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}') >> sim.sh
    echo export ROOTSYS=/usr >> sim.sh
    echo "export TMPDIR=$(pwd)" >> sim.sh
    echo "which $simApp" >> sim.sh
    echo "$simApp -xml=ccdb://GEOMETRY/main_HDDS.xml,run=$runNo" >> sim.sh
fi
simId=$simId3 seqNo=$seqNo bash sim.sh || clean_exit $? "$simApp crashed"

source ./setup
which mcsmear
mcsmear -Pprint \
        --nthreads=$nthreads \
        -Pnthreads=$nthreads \
        -Pjana:nevents=$nevents \
        -Pjana:show_ticker=$ticker \
        -Pjana:timeout=300 \
        -Pjana:warmup_timeout=1200 \
        sample.hddm || clean_exit $? "mcsmear crashed"

which hd_root
hd_root --loadconfigs hd_recon.config \
        --nthreads=$nthreads \
        -Pnthreads=$nthreads \
        -Pjana:nevents=$nevents \
        -Pjana:show_ticker=$ticker \
        -Pjana:timeout=300 \
        -Pjana:warmup_timeout=1200 \
        -PTRK:SAVE_TRUNCATED_DEDX=1 \
        sample_smeared.hddm || clean_exit $? "hd_root crashed"

save_output sample.hddm ${simType}/${simType}${simId3}_${seqNo3}.hddm || clean_exit $? "save of sample.hddm failed"
save_output sample_smeared.hddm ${simType}/${simType}${simId3}_${seqNo3}_smeared.hddm || clean_exit $? "save of sample_smeared.hddm failed"
save_output dana_rest.hddm ${simType}/${simType}${simId3}_${seqNo3}_rest.hddm || clean_exit $? "save of dana_rest.hddm failed"
save_output hd_root.root ${simType}/${simType}${simId3}_${seqNo3}_rest.root || clean_exit $? "save of hd_root.hddm failed"
clean_exit
