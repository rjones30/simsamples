#!/usr/bin/env python3
#
# logminer.py - methods to mine information from sim samples
#               job logs from running on the osg.
#
# author: richard.t.jones at uconn.edu
# version: march 26, 2021

import re
import sys
import glob
import numpy as np

running_re = re.compile(r"^job particle_g.. ([0-9]+) ([0-9]+) running on (.*)")
uconnhtc_re = re.compile(r"cn4[1-4][0-9]")
g4rate_re = re.compile(r" *per event average: +([.0-9]+) +([.0-9]+) +([.0-9]+)")
g3rate_re = re.compile(r" * .... TIME TO PROCESS ONE EVENT IS = +([.0-9]+) SECONDS")
jarate_re = re.compile(r".* Average rate: +([.0-9]+)([kMG]*Hz)")

ratedata = {}
for sim in range(1, 35):
   ratedata[sim] = {}
   for tool in ("gun", "g31", "g34"):
      ratedata[sim][tool] = {"sim":[], "smear":[], "recon":[]}
      logpat = "particle_{0}.d/sim_{1:03d}/log.d/stdout.4*".format(tool, sim)
      for logf in glob.glob(logpat):
         smeared = False
         for line in open(logf):
            m = running_re.match(line)
            if m:
               if not uconnhtc_re.match(m.group(3)):
                  break
            g4rate = g4rate_re.match(line)
            if g4rate:
               ratedata[sim][tool]["sim"].append(float(g4rate.group(3)))
               continue
            g3rate = g3rate_re.match(line)
            if g3rate:
               ratedata[sim][tool]["sim"].append(float(g3rate.group(1)))
               continue
            jarate = jarate_re.match(line)
            if jarate:
               mult = 1
               if "kHz" in jarate.group(2):
                  mult = 1e3
               elif "MHz" in jarate.group(2):
                  mult = 1e6
               elif "GHz" in jarate.group(2):
                  mult = 1e9
               if not smeared:
                  ratedata[sim][tool]["smear"].append(float(jarate.group(1))*mult)
                  smeared = True
               else:
                  ratedata[sim][tool]["recon"].append(float(jarate.group(1))*mult)
                  break
         if len(ratedata[sim][tool]["recon"]) == 10:
            break

output = ""
for sim in range(1, 35):
   g3 = np.array(ratedata[sim]["g31"]["sim"] + ratedata[sim]["g34"]["sim"])
   if len(g3) < 3:
      print("warning: low count of G3 measurements for sim", sim, len(g3))
   elif g3.std() > g3.mean() * 0.50:
      print("warning: excessive spread on G3 measurements for sim", sim, g3.std()/g3.mean())
   g4 = np.array(ratedata[sim]["gun"]["sim"])
   if len(g4) < 3:
      print("warning: low count of G4 measurements for sim", sim, len(g4))
   elif g4.std() > g4.mean() * 0.50:
      print("warning: excessive spread on G4 measurements for sim", sim, g4.std()/g4.mean())
   smear = np.array(ratedata[sim]["gun"]["smear"] + ratedata[sim]["g31"]["smear"] + ratedata[sim]["g34"]["smear"])
   if len(smear) < 3:
      print("warning: low count of smear measurements for sim", sim, len(smear))
   elif smear.std() > smear.mean() * 0.50:
      print("warning: excessive spread on smear measurements for sim", sim, smear.std()/smear.mean())
   recon = np.array(ratedata[sim]["gun"]["recon"] + ratedata[sim]["g31"]["recon"] + ratedata[sim]["g34"]["recon"])
   if len(recon) < 3:
      print("warning: low count of recon measurements for sim", sim, len(g3))
   elif recon.std() > recon.mean() * 0.50:
      print("warning: excessive spread on recon measurements for sim", sim, recon.std()/recon.mean())
   output += "{0:03d}\t{1:8.1f}\t{2:8.1f}\t{3:8.1f}\t{4:8.1f}\n".format(sim, 1/g3.mean(), 1/g4.mean(), smear.mean(), recon.mean())
print(output)
