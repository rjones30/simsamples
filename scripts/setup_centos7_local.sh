#!/bin/bash

#source /nfs/direct/packages/system_scripts/scl_enable_devtoolset-3.bash
#source /nfs/direct/packages/system_scripts/scl_enable_python27.bash

export DIRACXX_HOME=/home/halld/Diracxx
export DIRACXX_DIR=$DIRACXX_HOME/x86_64
if echo $LD_LIBRARY_PATH | grep -q $DIRACXX_DIR; then
    true
else
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DIRACXX_DIR/lib
    export ROOT_INCLUDE_PATH=/usr/local/root/include/root:$DIRACXX_DIR/include
    export PYTHONPATH=$PYTHONPATH:$DIRACXX_DIR/python
fi

export PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
export PYTHON_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
export PYTHON_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
if [[ $PYTHON_MAJOR_VERSION -ge 3 ]]; then
    export PYTHON_GE_3=true
else
    export PYTHON_GE_3=false
fi

#JANA_CALIB_CONTEXT=""
if [ -z "$JANA_CALIB_CONTEXT" ]; then
    export JANA_CALIB_CONTEXT="variation=mc"
fi
if [ -z "$JANA_CALIB_URL" ]; then
    #export JANA_CALIB_URL="sqlite:////home/halld/ccdb/sql/ccdb_2017-06-23.sqlite"
    export JANA_CALIB_URL="mysql://ccdb_user@hallddb.jlab.org/ccdb"
fi
if [ -z "$JANA_GEOMETRY_URL" ]; then
    #export JANA_GEOMETRY_URL="xmlfile:///home/halld/hdds/main_HDDS.xml"
    export JANA_GEOMETRY_URL="ccdb://GEOMETRY/main_HDDS.xml"
fi

# pointers to top-level packages
GLUEX_TOP=/home/halld
ONLINE=/home/halld/online
BUILD_SCRIPTS=/home/halld/build_scripts
HALLD_SIM_HOME=/home/halld/halld_sim/
HALLD_RECON_HOME=/home/halld/halld_recon/
HALLD_HOME=$HALLD_RECON_HOME
HD_UTILITIES_HOME=/home/halld/hd_utilities/
ROOT_ANALYSIS_HOME=/home/halld/gluex_root_analysis/
MCWRAPPER_CENTRAL=/home/halld/gluex_MCwrapper
HDDM_DIR=/home/halld/hddm/x86_64
HDDS_HOME=/home/halld/hdds
BMS_OSNAME=`$HALLD_RECON_HOME/src/BMS/osrelease.pl`
EVTGEN_VERSION=01.07.00
EVTGEN_HOME=/home/halld/evtgen/evtgen-$EVTGEN_VERSION
EVTGENDIR=$EVTGEN_HOME/x86_64
HEPMC_VERSION=2.06.10
HEPMC_HOME=/home/halld/hepmc/HepMC-$HEPMC_VERSION
HEPMCDIR=$HEPMC_HOME/x86_64
PHOTOS_VERSION=3.61
PHOTOS_HOME=/home/halld/photos/Photos-$PHOTOS_VERSION
PHOTOSDIR=$PHOTOS_HOME/x86_64
EVIO_HOME=/home/halld/evio/evio-4.3
EVIO_BUILD=$EVIO_HOME/$(uname)-$(uname -m)
EVIOROOT=$EVIO_BUILD
JANA_LEVEL=0.8.2
JANA_HOME=/home/halld/jana/jana_$JANA_LEVEL/$BMS_OSNAME
JANA_RESOURCE_DIR=/home/halld/jana/resources
JANA_PLUGIN_PATH=$JANA_HOME/plugins:$HALLD_RECON_HOME/$BMS_OSNAME/plugins:$HALLD_SIM_HOME/$BMS_OSNAME/plugins:$ONLINE/monitoring/$BMS_OSNAME/plugins
AMPTOOLS_DIR=/home/halld/amptools/centos7
AMPTOOLS_VERSION=0.12.1
AMPTOOLS=$AMPTOOLS_DIR/AmpTools
AMPPLOTTER=$AMPTOOLS_DIR/AmpPlotter
SQLITE_VERSION=3.13.0
SQLITE_YEAR=2016
SQLITE_HOME=/home/halld/sqlite/sqlite-$SQLITE_VERSION
SQLITECPP_HOME=/home/halld/SQLiteCpp
BATCH_MODE=0
export GLUEX_TOP
export BUILD_SCRIPTS
export ONLINE
export HALLD_HOME
export HALLD_SIM_HOME
export HALLD_RECON_HOME
export HD_UTILITIES_HOME
export ROOT_ANALYSIS_HOME
export MCWRAPPER_CENTRAL
export HDDM_DIR
export HDDS_HOME
export BMS_OSNAME
export EVTGEN_VERSION
export EVTGEN_HOME
export EVTGENDIR
export HEPMC_VERSION
export HEPMC_HOME
export HEPMCDIR
export PHOTOS_VERSION
export PHOTOS_HOME
export PHOTOSDIR
export EVIO_HOME
export EVIO_BUILD
export EVIOROOT
export JANA_HOME
export JANA_LEVEL
export JANA_RESOURCE_DIR
export JANA_PLUGIN_PATH
export AMPTOOLS_DIR
export AMPTOOLS_VERSION
export AMPTOOLS AMPPLOTTER
export SQLITE_YEAR
export SQLITE_VERSION
export SQLITE_HOME
export SQLITECPP_HOME
export BATCH_MODE

# install direct file access over xrootd
if [[ -d /usr/local/xrootd/lib64 ]]; then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/xrootd/lib64
    export LD_PRELOAD=/usr/local/xrootd/lib64/libXrdPosixPreload.so:/usr/local/xrootd/lib64/libXrdPosix.so:/usr/local/xrootd/lib64/libXrdClient.so:/usr/local/xrootd/lib64/libXrdUtils.so
fi

# access to python modules in sim_recon
if [[ -z "$PYTHONPATH" ]]; then
    PYTHONPATH=$HALLD_RECON_HOME/$BMS_OSNAME/python3:$HALLD_SIM_HOME/$BMS_OSNAME/python3
else
    PYTHONPATH=$HALLD_RECON_HOME/$BMS_OSNAME/python3:$HALLD_SIM_HOME/$BMS_OSNAME/python3:$PYTHONPATH
fi
PYTHONPATH=$PYTHONPATH:$HALLD_RECON_HOME/$BMS_OSNAME/python2:$HALLD_SIM_HOME/$BMS_OSNAME/python2
export PYTHONPATH

# this is needed to build evio, but not to use it
export CODA=$EVIO_HOME

# stuff related to the calibration constants db
CCDB_VERSION=1.01
CCDB_HOME=/home/halld/ccdb
source $CCDB_HOME/environment.bash
#CCDB_CONNECTION="mysql://jonesrt@hallddb.jlab.org/ccdb"
CCDB_CONNECTION=$JANA_CALIB_URL
export CCDB_HOME CCDB_CONNECTION

# stuff related to the run conditions database
RCDB_HOME=/home/halld/rcdb
source $RCDB_HOME/environment.bash
RCDB_CONNECTION="mysql://rcdb@hallddb.jlab.org/rcdb"
export RCDB_HOME RCDB_CONNECTION

# add hddm utilities to the path
if [[ -d $HDDM_DIR ]]; then
    export PATH=$PATH:$HDDM_DIR/bin
fi

# stuff related to the hdds geometry database
if ! echo $LD_LIBRARY_PATH | grep -q "$HDDS_HOME/$BMS_OSNAME/lib"; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HDDS_HOME/$BMS_OSNAME/lib
fi
export LD_LIBRARY_PATH

# stuff for nvidia gpu support library cuda
if false; then
    CUDA_INSTALL_PATH=/usr/local/cuda
    export CUDA_INSTALL_PATH
    if ! echo $PATH | grep -q "$CUDA_INSTALL_PATH/bin"; then
        PATH=$PATH:$CUDA_INSTALL_PATH/bin
    fi
    if ! echo $LD_LIBRARY_PATH | grep -q "$CUDA_INSTALL_PATH/lib"; then
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_INSTALL_PATH/lib:$CUDA_INSTALL_PATH/lib64
    fi
fi

# add the appropriate bin directories to path
if ! echo $PATH | grep -q "/home/halld/bin"; then
    PATH=/home/halld/bin:$PATH
fi
if ! echo $PATH | grep -q "$HALLD_RECON_HOME/$BMS_OSNAME/bin"; then
    PATH=$HALLD_RECON_HOME/$BMS_OSNAME/bin:$PATH
fi
if ! echo $PATH | grep -q "$HALLD_RECON_HOME/$BMS_OSNAME/bin"; then
    PATH=$HALLD_RECON_HOME/$BMS_OSNAME/bin:$PATH
fi
if ! echo $PATH | grep -q "$HALLD_SIM_HOME/$BMS_OSNAME/bin"; then
    PATH=$HALLD_SIM_HOME/$BMS_OSNAME/bin:$PATH
fi
if ! echo $PATH | grep -q "$MCWRAPPER_CENTRAL/bin"; then
    PATH=$MCWRAPPER_CENTRAL/bin:$PATH
fi
if ! echo $PATH | grep -q "$HDDS_HOME/$BMS_OSNAME/bin"; then
    PATH=$HDDS_HOME/$BMS_OSNAME/bin:$PATH
fi
if ! echo $PATH | grep -q "$EVIO_BUILD/bin"; then
    PATH=$EVIO_BUILD/bin:$PATH
fi
export PATH

# add the appropriate lib directories to LD_LIBRARY_PATH
if ! echo $LD_LIBRARY | grep -q "$EVIO_BUILD/lib"; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EVIO_BUILD/lib
fi
if ! echo $LD_LIBRARY_PATH | grep -q "$HALLD_RECON_HOME/$BMS_OSNAME/lib"; then
    LD_LIBRARY_PATH=$HALLD_RECON_HOME/$BMS_OSNAME/lib:$LD_LIBRARY_PATH
fi
if ! echo $LD_LIBRARY_PATH | grep -q "$HALLD_SIM_HOME/$BMS_OSNAME/lib"; then
    LD_LIBRARY_PATH=$HALLD_SIM_HOME/$BMS_OSNAME/lib:$LD_LIBRARY_PATH
fi
if ! echo $LD_LIBRARY_PATH | grep -q "$HALLD_RECON_HOME/$BMS_OSNAME/lib"; then
    LD_LIBRARY_PATH=$HALLD_RECON_HOME/$BMS_OSNAME/lib:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

# select the cernlib installation
if [ -z $CERN ]; then
    CERN=/usr/local/cern
    CERN_LEVEL=pro
    CERN_ROOT=$CERN/$CERN_LEVEL
    export CERN CERN_ROOT CERN_LEVEL
    . /etc/profile.d/cern.sh
fi
if [ -z $CERN_LEVEL ]; then
    CERN_LEVEL=pro
    export CERN_LEVEL
fi
if ! echo $PATH | grep -q "$CERN_ROOT/$CERN_LEVEL/bin"; then
    PATH=$PATH:$CERN_ROOT/$CERN_LEVEL/bin
fi

# add support for the hdf5 library
HDF5ROOT=/nfs/direct/packages/hdf5/hdf5-1.12.0-linux-centos7-x86_64-shared
export HDF5ROOT
if ! echo $LD_LIBRARY_PATH | grep -q $HDF5ROOT; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HDF5ROOT/lib
    export LD_LIBRARY_PATH
fi
if ! echo $PATH | grep -q $HDF5ROOT; then
    PATH=$PATH:$HDF5ROOT/bin
    export PATH
fi

# chose the java vm
JAVAROOT=/usr/java/jdk
export JAVAROOT

# very old stuff, mostly obsolete
CERN_DIR=$CERN_ROOT
export CERN_DIR

# pointers to the Intel compiler
INTELCOMPILER=/usr/local/intel/compiler80
export INTELCOMPILER

# update the LD_LIBRARY_PATH
if ! echo ${LD_LIBRARY_PATH} | grep -q "$XERCESCROOT/lib"; then
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH:="/usr/lib:/usr/local/lib"}:$XERCESCROOT/lib:$XALANCROOT/lib
fi
export LD_LIBRARY_PATH

# put root into the path, if not already there
if [[ "$ROOTSYS" = "" ]]; then
    export ROOTSYS=/usr/local/root
fi
if ! echo $PATH | grep -q "$ROOTSYS/bin"; then
    PATH=$PATH:$ROOTSYS/bin
fi
if ! echo $PYTHONPATH | grep -q "$ROOTSYS/lib/root"; then
    PYTHONPATH=$PYTHONPATH:$ROOTSYS/lib
fi

# put root into the library path, if not already there
if ! echo $LD_LIBRARY_PATH | grep -q "$ROOTSYS/lib"; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`root-config --libdir`
fi

# add pointers to Geant4 libraries
G4ROOT=/nfs/cern.ch/asis/geant4.10.04.p02/x86_64
GEANT4PY=$G4ROOT/src/environments/g4py
G4WORKDIR=/home/halld/HDGeant4/jlab
G4BUILD=debug
if [[ "$G4BUILD" = "debug" ]]; then
    G4ROOT=/${G4ROOT}-noMT-debug
    G4WORKDIR=/home/halld/HDGeant4/dev
fi
if uname -m | grep -q x86_64; then
    CLHEP=/nfs/cern.ch/asis/clhep-2.4.1.0/x86_64
else
    CLHEP=/nfs/cern.ch/asis/clhep-2.1.1.0/i686
fi
export G4ROOT G4WORKDIR CLHEP
if [[ -x $G4ROOT/bin/geant4-site.sh ]]; then
    . $G4ROOT/bin/geant4-site.sh >/dev/null
else
    . $G4ROOT/bin/geant4.sh >/dev/null
fi
if [[ -x $G4ROOT/share/Geant4*/geant4make/geant4make-site.sh ]]; then
    . $G4ROOT/share/Geant4*/geant4make/geant4make-site.sh
else
    . $G4ROOT/share/Geant4*/geant4make/geant4make.sh
fi
if [[ "$G4BUILD" = "debug" ]]; then
    unset G4MULTITHREADED
fi
CLHEP_DIR=$CLHEP
CLHEP_LIB_DIR=$CLHEP/lib
CLHEP_INCLUDE_DIR=$CLHEP/include
export CLHEP_DIR CLHEP_LIB_DIR CLHEP_INCLUDE_DIR

# pointers for geant4py interface
XERCESC3ROOT=/nfs/direct/packages/xerces/xerces-c-3.2.3/x86_64
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$XERCESC3ROOT/lib
if [[ -d $GEANT4PY/lib64 ]]; then
    PYTHONPATH=$PYTHONPATH:$GEANT4PY/lib64:$G4WORKDIR/g4py
else
    PYTHONPATH=$PYTHONPATH:$GEANT4PY/lib:$G4WORKDIR/g4py
fi

# pointers to xerces and xalan libraries
XERCESCROOT=/usr/local/xerces
XALANCROOT=/nfs/direct/packages/xerces/xml-xalan/c
XALANJROOT=/nfs/direct/packages/xerces/xalan-j_2_5_1
if ! echo $CLASSPATH | grep -q "$XALANJROOT/bin/xalan.jar"; then
    CLASSPATH=$CLASSPATH:$XALANJROOT/bin/xalan.jar:/nfs/direct/packages/xsdvalid/xsdvalid-24/xsdvalid.jar
fi
export XERCESCROOT XALANCROOT CLASSPATH

if uname -m | grep -q x86_64; then
    lib=lib64
else
    lib=lib
fi
QTMOC="/usr/$lib/qt4/bin/moc"
QTFLAGS="-I/usr/include/QtCore -I/usr/include/QtGui -I/usr/include/QtOpenGL"
QTLIBS="-lQtCore -lQtGui"
GLQTLIBS="-lQtCore -lQtGui -lQtOpenGL"
export QTMOC QTFLAGS QTLIBS GLQTLIBS

function path_fixup()
{
	symbol=$1
	oldstring=$2
	newstring=$3
	newsymbol=""
	for clause in `echo ${!symbol} |\
		       awk -F: '{for(i=1;i<=NF;i++){print $i}}'`
	do
		newsymbol=$newsymbol:`echo $clause |\
			              sed "s&$oldstring&$newstring&"`
	done
	newsymbol=`echo $newsymbol | sed 's/^://'`
	export $symbol=$newsymbol
}

if uname -a | grep -q x86_64
then
	path_fixup JANA_HOME /i686 /x86_64
	path_fixup AMPTOOLS /i686 /x86_64
	path_fixup CLHEP /i686 /x86_64
	path_fixup CLHEP_LIB /i686 /x86_64
	path_fixup CLHEP_LIB_DIR /i686 /x86_64
	path_fixup CLHEP_INCLUDE_DIR /i686 /x86_64
fi

if ! echo ${LD_LIBRARY_PATH} | grep -q "$CLHEP_LIB_DIR"; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$G4LIB/$G4SYSTEM:$CLHEP_LIB_DIR
fi
unset DYLD_LIBRARY_PATH

# exec scl enable devtoolset-3 bash
# put devtoolset-3 include dir ahead of /usr/include in include path search list
unset CPLUS_INCLUDE_PATH

# remove this variable because it interferes with building HDGeant4
unset CLHEP_INCLUDE_DIR
