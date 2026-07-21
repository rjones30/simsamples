#!/bin/bash
#
# two_container_workscript.sh - GlueX simulation samples script
#                 featuring simulation in the alma9 container,
#                 but reconstruction in the centos7 container.
#
# author: richard.t.jones at uconn.edu
# version: april 8, 2024
#
# usage: [ run within a GlueX singularity container ]
#        $ ./two_container_workscript.sh <simType> <simId> <seqNo>

runNo=71000
nthreads=1
nevents=100

alma9_container="/cvmfs/singularity.opensciencegrid.org/rjones30/gluextest:latest"
centos7_container="/cvmfs/singularity.opensciencegrid.org/rjones30/gluex:latest"
oasismount="/cvmfs"
oasisprefix="oasis.opensciencegrid.org/gluex"
oasisroot="$oasismount/$oasisprefix"
remotepath="/Gluex/rawdata/simulation/simsamples"
httpsURL="https://nod60.storrs.hpc.uconn.edu:2843"
#remotepath="/Gluex/simulation/simsamples"
#httpsURL="https://grinch.phys.uconn.edu:2843"
inputURL="https://gryphn.phys.uconn.edu/halld/simsamples"
userproxy="x509_user_proxy"

function usage() {
    echo "Usage: two_container_workscript.sh <simType> <simId> <seqNo>"
    echo "  where <simType> = simulation type name, eg. particle_gun, particle_g34, ..."
    echo "        <simId> = simulation id number, 1..Smax"
    echo "        <seqNo> = job sequence number, 1..Jmax"
}

function clean_exit() {
    ls -l 
    rm -f setup sim.sh control.in randoms worklist smear.root sample*.hddm dana_rest.hddm hd_root.root tree*.root *.hbook *.rz *.dat tmp.* *.astate
    if [ "$1" = "" -o "$1" = "0" ]; then
        echo "Successful exit from two_container_workscript."
        exit 0
    fi
    echo "Error $1 in two_container_workscript, $2"
    while true; do
        msg=$(echo "Error $1 in two_container_workscript, $2" | sed 's/ /_/g')
        sleep 120
        break
    done
    exit $1
}

function centos7() {
    echo "#!/bin/bash" >.centos7_container_step
    echo 'bs=/group/halld/Software/build_scripts' >>.centos7_container_step
    echo 'dist=/group/halld/www/halldweb/html/dist' >>.centos7_container_step
    echo 'halld_versions=/group/halld/www/halldweb/html/halld_versions' >>.centos7_container_step
    echo 'halld_version=5.2.0' >>.centos7_container_step
    echo 'context="variation=default"' >>.centos7_container_step
    echo 'source $bs/gluex_env_jlab.sh $halld_versions/version_$halld_version.xml' >>.centos7_container_step
    echo 'export RCDB_CONNECTION=sqlite:///$dist/rcdb.sqlite' >>.centos7_container_step
    echo 'export CCDB_CONNECTION=sqlite:///$dist/ccdb.sqlite' >>.centos7_container_step
    echo 'export JANA_GEOMETRY_URL=ccdb://GEOMETRY/main_HDDS.xml' >>.centos7_container_step
    echo 'export JANA_CALIB_URL=sqlite:///$dist/ccdb.sqlite' >>.centos7_container_step
    echo 'export JANA_CALIB_CONTEXT=$context' >>.centos7_container_step
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HDGEANT4_HOME/tmp/Linux-g++/hdgeant4' >>.centos7_container_step
    echo 'export OSG_CONTAINER_HELPER=""' >>.centos7_container_step
    echo "export x509userproxy=$userproxy" >>.centos7_container_step
    echo "$*" >>.centos7_container_step
    if [[ ! -x /usr/bin/singularity ]]; then
        source /etc/profile.d/modules.sh
        module load singularity
    fi
    singularity exec --containall --bind ${oasismount}:/cvmfs \
        --home `pwd`:/srv --pwd /srv ${centos7_container} bash .centos7_container_step
}

function alma9() {
    echo "#!/bin/bash" >.alma9_container_step
    echo 'bs=/group/halld/Software/build_scripts' >>.alma9_container_step
    echo 'dist=/group/halld/www/halldweb/html/dist' >>.alma9_container_step
    echo 'halld_versions=/group/halld/www/halldweb/html/halld_versions' >>.alma9_container_step
    echo 'halld_version=5.14.2' >>.alma9_container_step
    echo 'context="variation=default"' >>.alma9_container_step
    echo 'source $bs/gluex_env_jlab.sh $halld_versions/version_$halld_version.xml' >>.alma9_container_step
    echo 'export RCDB_CONNECTION=sqlite:///$dist/rcdb.sqlite' >>.alma9_container_step
    echo 'export CCDB_CONNECTION=sqlite:///$dist/ccdb.sqlite' >>.alma9_container_step
    echo 'export JANA_GEOMETRY_URL=ccdb://GEOMETRY/main_HDDS.xml' >>.alma9_container_step
    echo 'export JANA_CALIB_URL=sqlite:///$dist/ccdb.sqlite' >>.alma9_container_step
    echo 'export JANA_CALIB_CONTEXT=$context' >>.alma9_container_step
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HDGEANT4_HOME/tmp/Linux-g++/hdgeant4' >>.alma9_container_step
    echo 'export OSG_CONTAINER_HELPER=""' >>.alma9_container_step
    echo "export x509userproxy=$userproxy" >>.alma9_container_step
    echo "$*" >>.alma9_container_step
    if [[ ! -x /usr/bin/singularity ]]; then
        source /etc/profile.d/modules.sh
        module load singularity
    fi
    singularity exec --containall --bind ${oasismount}:/cvmfs \
         --home `pwd`:/srv --pwd /srv ${alma9_container} bash .alma9_container_step
}

function save_output() {
    maxretry=5
    retry=0
    while [[ $retry -le $maxretry ]]; do
        centos7 gfal-copy -f --copy-mode streamed file://`pwd`/$1 $httpsURL/$remotepath/$2 2>gfal-copy.err
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
    # fall through to allow job file transfer return results, failure not fatal
    mv $1 $(basename $2)
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

wget="centos7 /usr/bin/wget --ca-directory=/etc/grid-security/certificates"
$wget -O setup_alma9 $inputURL/scripts/setup_alma9_container.sh 2>/dev/null || clean_exit $? "cannot fetch setup_alma9_container.sh from web server"
$wget -O setup_centos7 $inputURL/scripts/setup_centos7_container.sh 2>/dev/null || clean_exit $? "cannot fetch setup_centos7_container.sh from web server"
$wget -O worklist $inputURL/config/worklist.in 2>/dev/null || clean_exit $? "cannot fetch worklist.in from web server"
$wget -O control.in $inputURL/$simType.d/sim_$simId3/control.in 2>/dev/null || clean_exit $? "cannot fetch control.in from web server"
$wget -O randoms $inputURL/config/randoms.in 2>/dev/null || clean_exit $? "cannot fetch randoms.in from web server"
$wget -O hd_recon.config $inputURL/config/hd_recon.config 2>/dev/null || clean_exit $? "cannot fetch randoms.in from web server"
rseeds=$(head -n $seqNo randoms | tail -n1)
jmax=$(awk "/^$simType/{if(\$2+0==$simId+0){print \$3}}" worklist)
echo $jmax | grep -q '[0-9][0-9]*' || clean_exit $? "cannot find simsample $simId in worklist"
[ $seqNo -ge 0 -o $seqNo -ge $jmax ] || clean_exit $? "simulation seqNo $seqNo is out of range"
sed -i "s/^RNDM.*/RNDM $rseeds/" control.in || clean_exit $? "RNDM card not found in control.in"
sed -i "s/^RUN[NG].*/RUNNO $runNo/" control.in || clean_exit $? "RUN card not found in control.in"
sed -i "s/^OUTF.*/OUTFILE 'sample.hddm'/" control.in || clean_exit $? "OUTF card not found in control.in"
sed -i "s/^TRIG.*/TRIG $nevents/" control.in || clean_exit $? "TRIG card not found in control.in"

#export CCDB_CONNECTION="sqlite:////cvmfs/oasis.opensciencegrid.org/gluex/group/halld/www/halldweb/html/dist/ccdb.sqlite"
export CCDB_CONNECTION="sqlite:////cvmfs/gluex.osgstorage.org/gluex/uconn1/rawdata/simulation/simsamples/config/ccdb_mc_no_mergehits.sqlite"
export JANA_CALIB_URL=$CCDB_CONNECTION
export JANA_GEOMETRY_URL="ccdb://GEOMETRY/main_HDDS.xml"
#export JANA_CALIB_CONTEXT="variation=mc"
export JANA_CALIB_CONTEXT="variation=mc_no_mergehits"
#export JANA_CALIB_CONTEXT="variation=fdcwires_test"

echo simType=$simType >sim.sh
echo simId=$simId3 >>sim.sh
echo seqNo=$seqNo >>sim.sh
cat setup_alma9 >> sim.sh
if [ "$simType" = "particle_gun" ]; then
    simApp=hdgeant4
    echo "hdgeant4" >> sim.sh
else
    simApp=hdgeant
    echo "export TMPDIR=$(pwd)" >> sim.sh
    echo "hdgeant -xml=ccdb://GEOMETRY/main_HDDS.xml,run=$runNo" >> sim.sh
fi
alma9 bash sim.sh || clean_exit $? "$simApp crashed"

echo simType=$simType >smear.sh
cat setup_alma9 >>smear.sh
echo mcsmear -Pprint -PJANA:BATCH_MODE=1 \
             -PNTHREADS=$nthreads \
             -PTHREAD_TIMEOUT_FIRST_EVENT=3600 \
             -PTHREAD_TIMEOUT=600 \
             sample.hddm >>smear.sh
alma9 bash ./smear.sh || clean_exit $? "mcsmear crashed"

echo simType=$simType >recon.sh
cat setup_centos7 >>recon.sh
echo hd_root --config=hd_recon.config \
             --nthreads=$nthreads \
             -PJANA:BATCH_MODE=1 \
             -PNTHREADS=$nthreads \
             -PTHREAD_TIMEOUT_FIRST_EVENT=3600 \
             -PTHREAD_TIMEOUT=600 \
             -PTRK:SAVE_TRUNCATED_DEDX=1 \
             sample_smeared.hddm >>recon.sh
centos7 bash ./recon.sh || clean_exit $? "hd_root crashed"

save_output sample.hddm ${simType}/${simType}${simId3}_${seqNo3}.hddm || clean_exit $? "save of sample.hddm failed"
save_output sample_smeared.hddm ${simType}/${simType}${simId3}_${seqNo3}_smeared.hddm || clean_exit $? "save of sample_smeared.hddm failed"
save_output dana_rest.hddm ${simType}/${simType}${simId3}_${seqNo3}_rest.hddm || clean_exit $? "save of dana_rest.hddm failed"
save_output hd_root.root ${simType}/${simType}${simId3}_${seqNo3}_rest.root || clean_exit $? "save of hd_root.hddm failed"
clean_exit
