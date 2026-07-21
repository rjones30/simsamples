#!/usr/bin/env python3
#
# prescript.py - runs before a particle_gun simsample job
#                is submitted to the osg.
#
# author: richard.t.jones at uconn.edu
# version: march 13, 2021
# revised: june 30, 2026

import sys
import subprocess
import re
import os
import json
import time

with open("/tmp/prescript_debug.txt", "w") as f:
    f.write(f"PATH={os.environ.get('PATH','')}\n")
    f.write(f"cwd={os.getcwd()}\n")

xrdserver = "nod60.phys.uconn.edu"
outdir = "/Gluex/rawdata/simulation/simsamples/"
#xrdserver = "grinch.phys.uconn.edu:1095"
#outdir = "/Gluex/simulation/simsamples/"

vtoken = "/tmp/vt_u7896"
os.environ['XDG_RUNTIME_DIR'] = os.getcwd()

def usage():
   print("Usage: prescript.py [ particle_gun | particle_g31 | particle_g34 ] <simId>")
   sys.exit(1)

if len(sys.argv) != 3:
    usage()

simType = sys.argv[1]
simId = "{0:03d}".format(int(sys.argv[2]))

# check that there is sufficient lifetime left of the proxy certificate
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
    print("Error fetching bearer token from vault proxy, cannot continue")
    sys.exit(9)
os.environ['BEARER_TOKEN'] = bearer_token

# push a copy of the control.in for this job to the output directory on xrootd
# also verifies that xrootd is running and the output directory exists
inURI = os.getcwd() + "/sim_{0}/control.in".format(simId)
outURI = "roots://" + xrdserver + outdir + simType + "/control.in_{0}".format(simId)
pro = subprocess.Popen(["xrdcp", "-f", inURI, outURI],
                       text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
outlist = pro.communicate()[0]
if pro.wait() != 0:
   print("Output directory does not exist, or xrootd is not running!")
   sys.exit(8)
else:
   print(outlist)
