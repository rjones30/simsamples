#!/usr/bin/env python3
#
# postscript.py - runs after a particle_g34 simsample job
#                 has finished on the osg.
#
# author: richard.t.jones at uconn.edu
# version: march 13, 2021
# revised: june 30, 2026

import sys
import subprocess
import re
import os
import stat
import json
import time

xrdserver = "nod60.phys.uconn.edu"
outdir = "/Gluex/rawdata/simulation/simsamples/"
#xrdsever = "grinch.phys.uconn.edu:1095"
#outdir = "/Gluex/simulation/simsamples/"
stagedir = "/nfs/direct/jonesrt/simsamples/"

vtoken = "/tmp/vt_u7896"
os.environ['XDG_RUNTIME_DIR'] = os.getcwd()

def usage():
   print("Usage: postscript.sh [ particle_gun | particle_g31 | particle_g34 ] <simId> <jobId> <returnCode> <retry>")
   sys.exit(1)

if len(sys.argv) != 6:
   usage()

simType = sys.argv[1]
simId = "{0:03d}".format(int(sys.argv[2]))
jobId = sys.argv[3]
retcode = int(sys.argv[4])
retry = int(sys.argv[5])
if retcode != 0:
   sys.exit(retcode)

pats = [ re.compile(r"{0}{1}_([0-9]+).hddm$".format(simType, simId)),
         re.compile(r"{0}{1}_([0-9]+)_smeared.hddm$".format(simType, simId)),
         re.compile(r"{0}{1}_([0-9]+)_rest.hddm$".format(simType, simId)),
         re.compile(r"{0}{1}_([0-9]+)_rest.root$".format(simType, simId)),
       ]

def stageout(fpath):
   with open(vtoken) as f:
      vt = f.read().strip()
   for attempt in range(25):
      res = subprocess.run(["curl", "-s", "-X", "POST",
                            "https://gryphn.phys.uconn.edu/halld/token",
                            "--data-urlencode", f"vault_token={vt}",
                            "--data-urlencode", "min_lifetime=1200"],
                           capture_output=True, text=True)
      try:
         bearer_token = json.loads(res.stdout).get("bearer_token", "")
         if bearer_token:
            break
      except json.JSONDecodeError:
         bearer_token = ""
      time.sleep(2 ** attempt)
   if not bearer_token:
      print("Error fetching bearer token from vault proxy")
      sys.exit(8)
   os.environ['BEARER_TOKEN'] = bearer_token
   print("pushing " + fpath + " to xrootd from staging area")
   pro = subprocess.Popen(["xrdcp", "-f",
                           stagedir + simType + ".d/" + fpath,
                           "root://" + xrdserver + outdir + simType + "/" + fpath],
                          stdout=subprocess.PIPE, text=True)
   proresp = pro.communicate()[0]
   if pro.wait() != 0:
      print("Error pushing staged file to xrootd")
      sys.exit(8)
   else:
      os.unlink(stagedir + simType + ".d/" + fpath)

# stash any output files left behind on the stage dir
pro = subprocess.Popen(["ls", stagedir + simType + ".d"], text=True,
                       stdout=subprocess.PIPE) #, stderr=subprocess.PIPE)
stagelist = pro.communicate()[0]
if pro.wait() != 0:
   print("Stage directory does not exist, or local disk error!")
   sys.exit(8)
for line in stagelist.split('\n'):
   straggler = line.rstrip()
   if not straggler:
       continue
   for i, pat in enumerate(pats):
      if pat.search(straggler):
         filemode = stat.filemode(os.stat(stagedir + simType + ".d/" + straggler).st_mode)
         if filemode == "-rw-r--r--":
            stageout(straggler)
         break

# verify that the output data are present on xrootd

nexpect = 1
pat = re.compile(r"^queue ([1-9][0-9]*)$")
for line in open(stagedir + simType + ".d/sim_" + simId + "/{0}.sub".format(simType)):
   m = pat.match(line.rstrip())
   if m:
      nexpect = int(m.group(1))
jobids = [dict.fromkeys(range(nexpect)) for pat in pats]

pro = subprocess.Popen(["xrdfs", xrdserver, "ls", outdir + simType], text=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
outlist = pro.communicate()[0]
if pro.wait() != 0:
   print("Output directory does not exist, or xrootd is not running!")
   sys.exit(8)
for line in outlist.split('\n'):
   for i in range(len(pats)):
      m = pats[i].search(line.rstrip())
      if m:
         del jobids[i][int(m.group(1)) - 1]

if sum(len(jobids[i]) for i in range(len(pats))) != 0:
   print("Output data not all found in the expected place!")
   print("  {0:4d} : {1}{2}_*.hddm".format(len(jobids[0]), simType, simId))
   print("  {0:4d} : {1}{2}_*_smeared.hddm".format(len(jobids[1]), simType, simId))
   print("  {0:4d} : {1}{2}_*_rest.hddm".format(len(jobids[2]), simType, simId))
   print("  {0:4d} : {1}{2}_*_rest.root".format(len(jobids[3]), simType, simId))
   for i in jobids[0]:
      print("  missing {0}{1}_{2}.hddm".format(simType, simId, i))
   for i in jobids[1]:
      print("  missing {0}{1}_{2}_smeared.hddm".format(simType, simId, i))
   for i in jobids[2]:
      print("  missing {0}{1}_{2}_rest.hddm".format(simType, simId, i))
   for i in jobids[3]:
      print("  missing {0}{1}_{2}_rest.root".format(simType, simId, i))
   sys.exit(7)
