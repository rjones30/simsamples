#!/usr/bin/env python3
#
# diagnose_holds.py - diagnostic script to examine job logs from simsamples
#                     jobs that failed over to hold, and print the worker
#                     node and the exit code for each.
#
# author: richard.t.jones at uconn.edu
# version: january 8, 2023

import subprocess
import re
import sys
import glob

def usage():
   print("usage: diagnose_holds.py")
   sys.exit(1)

jobs = []
req = subprocess.Popen(["condor_q", "-hold"], stdout=subprocess.PIPE)
for line in req.communicate()[0].decode().split('\n'):
   m = re.match("([1-9][.0-9]*) ", line)
   if m:
      jobs.append(m.group(1))

for job in jobs:
   firstline = "(empty log)"
   lastline = ""
   for log in glob.glob(f"*.d/*/log.d/stdout.{job}"):
      first = 1
      for line in open(log):
         if first:
            firstline = line.rstrip()
            first = 0
         else:
            lastline = line.rstrip()
   print(job + ';', firstline + ';', lastline)
