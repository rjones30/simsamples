#!/usr/bin/env python3
#
# rescale_samples.py : go through the simsample collections and scale up or down
#                      the total number of jobs to be processed for each type of
#                      particle by some fixed scale factor.
#
# author: richard.t.jones at uconn.edu
# version: march 23, 2024

import os
import sys
import glob
import re
import math

def usage():
   print("usage: rescale_samples.py <directory> <factor>")
   print(" where <directory> may either be a relative or absolute path,")
   print(" and <factor> may be any real number greater than 0. Any file")
   print(" within the directory tree under <directory> with a filename")
   print(" that ends with .sub is potentially updated by this command.")

try:
   assert len(sys.argv) == 3
   assert os.path.isdir(sys.argv[1])
   sfactor = float(sys.argv[2])
   assert sfactor > 0
except:
   usage()
   sys.exit(1)

def update_sub(subname):
   print("working on", subname)
   tmpfile = subname + ".mod"
   with open(tmpfile, "w") as out:
      for line in open(subname):
         mq = re.match(r"^queue ([0-9]*)$", line)
         if mq:
            out.write("#" + line[:-1] + f" --rescaled by factor {sfactor}" + line[-1])
            njobs = math.ceil(int(mq.group(1)) * sfactor)
            out.write(f"queue {njobs}\n")
         else:
            out.write(line)
   os.rename(tmpfile, subname)

def scan_dir(dirname):
   for item in glob.glob(f"{dirname}/*"):
      if os.path.isdir(item):
         scan_dir(item)
   for item in glob.glob(f"{dirname}/*.sub"):
      if os.path.isfile(item):
         update_sub(item)

scan_dir(sys.argv[1])

