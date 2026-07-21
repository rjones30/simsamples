#!/bin/bash
condor_q -run -constraint "ClusterId > 1532" -format "%d." ClusterId -format "%d " ProcId -format "%f " RemoteWallCLockTime -format "%d\n" LastJobLeaseRenewal | awk -v now=$(date +%s) '{print "job", $1, "remote runtime", $2, now-$3, "seconds since last contact"}' | sort -k3 -rn
