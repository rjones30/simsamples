debug=1
if [ -n "$debug" ]; then
    echo ">>>entry to setup_alma9_container.sh"
    env
    echo "pwd returns:" $(pwd)
    echo "ls -l returns"
    ls -l
    echo "which hdgeant4 returns" $(which hdgeant4)
    echo "which hdgeant returns" $(which hdgeant)
    echo "ls -l /srv returns"
    ls -l /srv
fi

# add pointers to Geant4 libraries
if [[ -z "$G4ROOT" ]]; then
    export G4ROOT=/cvmfs/oasis.opensciencegrid.org/gluex/geant4-v10.7.4/alma9-MT
    export GEANT4PY=$G4ROOT/src/environments/g4py
    export G4WORKDIR=/cvmfs/oasis.opensciencegrid.org/gluex/HDGeant4/alma9-MT
    if [[ -x $G4ROOT/bin/geant4-site.sh ]]; then
        . $G4ROOT/bin/geant4-site.sh >/dev/null
    else
        . $G4ROOT/bin/geant4.sh >/dev/null
    fi
    if [[ -x $G4ROOT/share/geant4make/geant4make-site.sh ]]; then
        . $G4ROOT/share/geant4make/geant4make-site.sh
    else
        . $G4ROOT/share/geant4make/geant4make.sh
    fi
    if [[ -d $GEANT4PY/lib64 ]]; then
        PYTHONPATH=$PYTHONPATH:$GEANT4PY/lib64:$G4WORKDIR/g4py
    else
        PYTHONPATH=$PYTHONPATH:$GEANT4PY/lib:$G4WORKDIR/g4py
    fi
    export LD_LIBRARY_PATH=$G4ROOT/lib64:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$G4WORKDIR/tmp/Linux-g++/hdgeant4:$LD_LIBRARY_PATH
    export PATH=$G4WORKDIR/bin/Linux-g++:$PATH
fi
export CLHEP_DIR=/cvmfs/oasis.opensciencegrid.org/gluex/CLHEP
export CLHEP_BASE_DIR=$CLHEP_DIR/x86_64-alma9
export CLHEP_INCLUDE_DIR=$CLHEP_DIR/x86_64-alma9/include
export CLHEP_LIB_DIR=$CLHEP_BASE_DIR/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CLHEP_LIB_DIR
unset CLHEP
export DIRACXX=/cvmfs/oasis.opensciencegrid.org/gluex/Diracxx/x86_64-alma9
export LD_LIBRARY_PATH=$DIRACXX/lib:$LD_LIBRARY_PATH

export OSNAME=Linux_Alma9-x86_64-gcc11.5.0-cntr

# add pointers to halld_sim
#export HALLD_SIM_HOME=/cvmfs/oasis.opensciencegrid.org/gluex/halld_sim
export JANA_PLUGIN_PATH=$HALLD_SIM_HOME/$OSNAME/plugins:$JANA_PLUGIN_PATH
export LD_LIBRARY_PATH=$HALLD_SIM_HOME/$OSNAME/lib:$LD_LIBRARY_PATH
export PATH=$HALLD_SIM_HOME/$OSNAME/bin:$PATH

# add pointers to halld_recon
#export HALLD_RECON_HOME=/cvmfs/oasis.opensciencegrid.org/gluex/halld_recon
export JANA_PLUGIN_PATH=$HALLD_RECON_HOME/$OSNAME/plugins:$JANA_PLUGIN_PATH
export LD_LIBRARY_PATH=$HALLD_RECON_HOME/$OSNAME/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$HALLD_RECON_HOME/$OSNAME/python3:$HALLD_RECON_HOME/$OSNAME/python2:$PYTHONPATH
export PATH=$HALLD_RECON_HOME/$OSNAME/bin:$PATH

# override the sqlite file if needed
if [ -z "$RCDB_CONNECTION" ]; then
    export RCDB_CONNECTION=sqlite:////cvmfs/oasis.opensciencegrid.org/gluex/group/halld/www/halldweb/html/dist/rcdb.sqlite
fi
if [ -z "$CCDB_CONNECTION" ]; then
    export CCDB_CONNECTION=sqlite:////cvmfs/oasis.opensciencegrid.org/gluex/group/halld/www/halldweb/html/dist/ccdb.sqlite
fi
if [ -z "$JANA_CALIB_URL" ]; then
    export JANA_CALIB_URL=$CCDB_CONNECTION
fi

# remove any prior installations of root on oasis, let if fall through to /usr
#export PATH=$(echo $PATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}')
#export PYTHONPATH=$(echo $PYTHONPATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}')
#export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | awk -F: '{for(i=1;i<=NF;i++){print $i}}' | awk '{if($0 ~ /\/root\//){i=0}else{printf("%s:",$0)}}')
#export ROOTSYS=/usr

if [ -n "$debug" ]; then
    env
    echo "pwd returns:" $(pwd)
    echo "ls -l returns"
    ls -l
    echo "which hdgeant4 returns" $(which hdgeant4)
    echo "ldd \`which hdgeant4\` returns" $(ldd `which hdgeant4`)
    echo "which hdgeant returns" $(which hdgeant)
    echo "ldd \`which hdgeant\` returns" $(ldd `which hdgeant`)
    echo "ls -l /srv returns" $(ls -l /srv)
fi
