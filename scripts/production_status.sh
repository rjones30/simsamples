#!/bin/bash
condor_q
grep "job proc.*completed successfully" simsamples.dag.dagman.out | grep -o "Node [^ ]*" | sort | uniq -c | sort -rn | head -10
echo
echo Total running: $(condor_q -run | grep simsamples | awk "{print $5}")
echo Transferring input: $(condor_q -constraint "JobStatus==2 && TransferringInput==true" -format "%d\n" ClusterId | wc -l)
echo Actually executing: $(condor_q -constraint "JobStatus==2 && TransferringInput=!=true" -format "%d\n" ClusterId | wc -l)
echo
grep -A2 "Done.*Pre.*Queued" simsamples.dag.dagman.out | tail -3
