#!/usr/bin/env python3
#
# stow.py - save any stashed output files to the output storage area.
#
# author: richard.t.jones at uconn.edu
# version: march 16, 2023

import subprocess
import sys
import re

def usage():
   print("Usage: stow.py")
   sys.exit(1)

if len(sys.argv) > 1:
   usage()

store = "root://nod62.phys.uconn.edu/Gluex/rawdata/simulation/simsamples"
#store = "root://grinch.phys.uconn.edu/Gluex/simulation/simsamples"
stash = "/home/www/docs/halld/simsamples/mergehists.d/"
templates = ["particle_gun{}_merged.root",
             "particle_g34{}_merged.root",
             "particle_g31{}_merged.root",
            ]
regexps = [re.compile(template.format("([0-9]*)")) for template in templates]

lsproc = subprocess.Popen(["ls", "-l", stash], stdout=subprocess.PIPE)
for line in lsproc.communicate()[0].split(b'\n'):
   sline = line.decode('utf-8').split()
   if len(sline) < 9:
      continue
   for i in range(len(regexps)):
      m = regexps[i].match(sline[8])
      if m:
         #print(f"gfal-copy -f --copy-mode streamed file://{stash}/{sline[8]} {store}/{sline[8][:12]}/{sline[8]} && /bin/rm {stash}/{sline[8]}")
         print(f"xrdcp -f {stash}/{sline[8]} {store}/{sline[8][:12]}/{sline[8]} && /bin/rm {stash}/{sline[8]}")

for sim in ("gun", "g34", "g31"):
   stash = f"/home/www/docs/halld/simsamples/particle_{sim}.d/"
   templates = [f"particle_{sim}{{}}_[0-9]*.hddm",
                f"particle_{sim}{{}}_[0-9]*_smeared.hddm",
                f"particle_{sim}{{}}_[0-9]*_rest.hddm",
                f"particle_{sim}{{}}_[0-9]*_rest.root",
               ]
   regexps = [re.compile(template.format("([0-9]*)")) for template in templates]
   lsproc = subprocess.Popen(["ls", "-l", stash], stdout=subprocess.PIPE)
   for line in lsproc.communicate()[0].split(b'\n'):
      sline = line.decode('utf-8').split()
      if len(sline) < 9:
         continue
      if sline[0] != "-rw-r--r--":
         continue
      for i in range(len(regexps)):
         m = regexps[i].match(sline[8])
         if m:
            #print(f"gfal-copy -f --copy-mode streamed file://{stash}/{sline[8]} {store}/{sline[8][:12]}/{sline[8]} && /bin/rm {stash}/{sline[8]}")
            print(f"xrdcp -f {stash}/{sline[8]} {store}/{sline[8][:12]}/{sline[8]} && /bin/rm {stash}/{sline[8]}")


