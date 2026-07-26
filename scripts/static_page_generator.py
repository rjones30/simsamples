#!/usr/bin/env python
#
# static_page_generator.py - static page generator script 
#                            for simsamples output data.
#
# author: richard.t.jones at uconn.edu
# version: march 15, 2021

import os
import sys
import glob
import subprocess
from pathlib import Path
from datetime import datetime, timezone

def usage():
   print("Usage: static_page_generator.py")
   sys.exit(1)

if len(sys.argv) > 1:
   usage()

stores = {
  "uconn0": {
    "httpserver": "https://gryphn.phys.uconn.edu/rootbrowser/?file=root://nod26.phys.uconn.edu/",
    "xrootdserver": "nod26.phys.uconn.edu",
    "webdavserver": "https://grinch.phys.uconn.edu:2843",
    "pnfs4root": "/pnfs4/phys.uconn.edu/data",
    "sampledata": "/Gluex/simulation/simsamples/",
  },
  "uconn1": {
    "httpserver": "https://gryphn.phys.uconn.edu/rootbrowser/?file=root://nod65.phys.uconn.edu/",
    "xrootdserver": "nod65.phys.uconn.edu",
    "webdavserver": "https://nod60.phys.uconn.edu:2843",
    "pnfs4root": "/dcache",
    "sampledata": "/Gluex/rawdata/simulation/simsamples/",
  }
}

simsamples = "/home/www/docs/halld/simsamples/"
page1 = open(simsamples + "latest_draft.html", "w")

particle = ["unknown",
            "gamma", "gamma",
            "positron", "positron",
            "electron", "electron",
            "mu+", "mu+",
            "mu-", "mu-",
            "pi+", "pi+",
            "pi-", "pi-",
            "Klong", "Klong",
            "K+", "K+",
            "K-", "K-",
            "neutron", "neutron",
            "proton", "proton",
            "antiproton", "antiproton",
            "Kshort", "Kshort",
            "Lambda", "Lambda",
            "pi0", "pi0",
            "eta", "eta",
           ]

prange  = [ (0,0),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
            (0,1), (0,12),
          ]

def get_samples():
   samples = []
   for storename,store in stores.items():
      pro = subprocess.Popen(["ls", store["pnfs4root"] + store["sampledata"]],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      samplelist = pro.communicate()[0].decode('utf-8')
      if pro.wait() != 0:
         print("Error - listing of simsamples data directory over pnfs4 failed!")
         print("Cannot continue.")
         sys.exit(9)
      for sample in samplelist.split('\n'):
         if "particle_g" in sample:
            nfs_dir = Path(store["pnfs4root"] + store["sampledata"] + sample)
            mtime_timestamp = nfs_dir.stat().st_mtime
            mtime_string = datetime.fromtimestamp(mtime_timestamp).strftime("%Y.%m.%d")
            samples.append(f"{storename}::{mtime_string}::{sample.split('/')[-1]}")
   return samples

def gen_header():
   page1.write("<html>" + """
<head>
 <title>Latest GlueX particle gun simulation samples</title>
 <style>
  table {
    border-collapse: collapse;
  }
  tr.headline { 
    border: solid;
    border-width: 1px 0 2px 0;
  }
  tr.newparticle { 
    border: solid;
    border-color: blue;
    border-width: 1px 0 0 0;
  }
  tr.newsimset { 
    border: solid;
    border-color: red;
    border-width: 2px 0 0 0;
  }
  td {
    padding-left: 2%;
    passing-right: 2%;
  }
  a.deadlink {
    color: gray
  }
 </style>
</head>
""")
   page1.write("<body>\n")

def gen_table():
   page1.write(" <table width=\"100%\">" + """
  <tr class="headline">
   <th align=\"center\">set</th>
   <th align=\"center\">particle</th>
   <th align=\"center\"><i>p</i>-range</th>
   <th align=\"center\">simulation</th>
   <th align=\"center\">control</th>
   <th align=\"center\">job logs</th>
   <th align=\"center\">output data</th>
   <th align=\"center\">plots</th>
  </tr>
""")
   sortable = {}
   for sample in samples:
      datestring = sample.split('::')[1]
      if "-" in sample:
         prefix, suffix = sample.split('-', 1)
         prefix = prefix.split('::')[2]
         key = f"{datestring} {suffix}"
      else:
         prefix = sample.split('::')[2]
         suffix = "latest"
         key = f"{datestring} {suffix}"
      for s in range(1, len(particle)):
         seq = "{0:03d}".format(s)
         sortable[key + ":{0:03d}:".format(999-s) + prefix] = (sample,
                                                               seq,
                                                               prefix,
                                                               suffix)
   lastset = ""
   lastpart = ""
   lastprange = ""
   for samplekey in sorted(sortable, reverse=True):
      sample = sortable[samplekey]
      storename = sample[0].split('::')[0]
      sampledate = sample[0].split('::')[1]
      samplename = sample[0].split('::')[2]
      s = int(sample[1])
      if sample[2] == "particle_gun":
         sim = "G4"
      elif sample[2] == "particle_g31":
         sim = "G3(HADR=1)"
      elif sample[2] == "particle_g34":
         sim = "G3(HADR=4)"
      else:
         sim = "<i>unknown</i>"
      if sample[3] != lastset:
         page1.write("  <tr class=\"newsimset\">\n")
      elif lastpart != particle[s]:
         page1.write("  <tr class=\"newparticle\">\n")
      else:
         page1.write("  <tr>\n")
      if sample[3] != lastset:
         page1.write("   <td valign=\"top\">" + sample[3] + " (" + sampledate + ")" + "</td>\n")
         lastset = sample[3]
      else:
         page1.write("   <td valign=\"top\"></td>\n")
      if lastpart != particle[s]:
         page1.write("   <td align=\"center\" valign=\"top\">" + particle[s] +
                     "</td>\n")
         lastpart = particle[s]
      else:
         page1.write("   <td></td>\n")
      prange_GeV = "{0}-{1}GeV".format(prange[s][0], prange[s][1])
      if lastprange != prange_GeV:
         page1.write("   <td align=\"center\" valign=\"top\" width=\"10%\">" +
                     prange_GeV + "</td>\n")
         lastprange = prange_GeV
      else:
         page1.write("   <td></td>\n")
      page1.write("   <td align=\"center\" valign=\"top\">" + sim + "</td>\n")
      datadir = stores[storename]["pnfs4root"] + stores[storename]["sampledata"] + samplename + "/"
      controlin = "sim_" + sample[1] + "/control.in"
      if os.path.isfile(os.path.join(simsamples, sample[2] + ".d", controlin)):
         css = "livelink"
      else:
         css = "deadlink"
      page1.write("   <td align=\"center\" valign=\"top\"><a href=\"" +
                  sample[2] + ".d/" + controlin + "\" " +
                  "class=\"" + css + "\">control.in</a></td>\n")
      logdir = sample[2] + ".d/sim_" + sample[1] + "/log.d"
      if os.path.isdir(os.path.join(simsamples, logdir)):
         css = "livelink"
      else:
         css = "deadlink"
      page1.write("   <td align=\"center\" valign=\"top\"><a href=\"" +
                   logdir + "\" class=\"" + css + "\">stdout,stderr</a></td>\n")
      css = "deadlink"
      for ending in ("_0001.hddm", "_001.hddm"):
         simhddm = sample[2] + sample[1] + ending
         if os.path.isfile(os.path.join(datadir, simhddm)):
            css = "livelink"
            break
      page1.write("   <td align=\"center\" valign=\"top\"><a href=\"" + 
                  stores[storename]["webdavserver"] + stores[storename]["sampledata"] + samplename + "/" + simhddm +
                  "\" class=\"" + css + "\">sim.hddm</a>, ")
      css = "deadlink"
      for ending in ("_0001_smeared.hddm", "_001_smeared.hddm"):
         smearedhddm = sample[2] + sample[1] + ending
         if os.path.isfile(os.path.join(datadir, smearedhddm)):
            css = "livelink"
            break
      page1.write("<a href=\"" +
                  stores[storename]["webdavserver"] + stores[storename]["sampledata"] + samplename + "/" +
                  smearedhddm + "\" class=\"" + css + "\">smeared.hddm</a>, ")
      css = "deadlink"
      for ending in ("_0001_rest.hddm", "_001_rest.hddm"):
         resthddm = sample[2] + sample[1] + ending
         if os.path.isfile(os.path.join(datadir, resthddm)):
            css = "livelink"
            break
      page1.write("<a href=\"" +
                  stores[storename]["webdavserver"] + stores[storename]["sampledata"] + samplename + "/" +
                  resthddm + "\" class=\"" + css + "\">rest.hddm</a>, ")
      css = "deadlink"
      for ending in ("_0001_rest.root", "_001_rest.root"):
         restroot = sample[2] + sample[1] + ending
         if os.path.isfile(os.path.join(datadir, restroot)):
            css = "livelink"
            break
      page1.write("<a href=\"" +
                  stores[storename]["webdavserver"] + stores[storename]["sampledata"] + samplename + "/" +
                  restroot + "\" class=\"" + css + "\">rest.root</a></td>\n")
      mergedroot = sample[2] + sample[1] + "_merged.root"
      if os.path.isfile(os.path.join(datadir, mergedroot)):
         css = "livelink"
      else:
         css = "deadlink"
      page1.write("   <td align=\"center\" valign=\"top\"><a href=\"" + 
                  stores[storename]["httpserver"] + stores[storename]["sampledata"] + samplename + "/" + mergedroot +
                  "\" class=\"" + css + "\" target=\"_blank\">plot browser</a>" +
                  ", <a href=\"" + stores[storename]["webdavserver"] + stores[storename]["sampledata"] + samplename + "/" +
                  mergedroot + "\" class=\"" + css + "\">merged.root</a></td>\n")
      page1.write("  </tr>\n")
   page1.write("</table>\n")

def gen_trailer():
   page1.write("</body>\n")
   page1.write("</html>\n")

samples = get_samples()
gen_header()
gen_table()
gen_trailer()
