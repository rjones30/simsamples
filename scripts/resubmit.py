#!/bin/bash
#
# resubmit.sh - takes in the output from particle_g*/postscript.py and
#               generates lines for a new condor submit file to rerun
#               any jobs whose output is missing on the xrootd server.
#
# author: richard.t.jones at uconn.edu
# version: april 4, 2024

echo 'executable = scripts/alma9-container.sh
output = log.d/stdout.$(CLUSTER).$(PROCESS)
error = log.d/stderr.$(CLUSTER).$(PROCESS)
log = resubmit.log
notification = never
universe = vanilla
should_transfer_files = yes
transfer_input_files = scripts/workscript.sh,config/hd_recon.config,config/ccdb_fixed_CarbonFiberEpoxy-6-30-2026.sqlite,/tmp/vt_u7896
WhenToTransferOutput = ON_EXIT
on_exit_hold = (ExitBySignal==False)&&(ExitCode!=0)
on_exit_remove = (ExitBySignal==False)&&(ExitCode==0)
Requirements = (HAS_SINGULARITY==true)&&(HAS_CVMFS_oasis_opensciencegrid_org==true)&&(HAS_CVMFS_singularity_opensciencegrid_org==true)
RequestMemory = 3800
RequestDisk = 8000000
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/rjones30/gluex:latest"
+MaxWallTimeMins = 720
'

awk -F '[_. ]*' 'BEGIN{last = ""}
/missing particle_g/{
  type = substr($4,1,3);
  sim = substr($4,4);
  job = $5;
  if (last != type sim job) {
    print "arguments = ./workscript.sh particle_"type, sim, job;
    print "queue 1";
  }
  last = type sim job;
}'

