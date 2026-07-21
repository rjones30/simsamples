#!/usr/bin/env

import hddm_s
import ROOT
import os
import re

datadir = "/pnfs4/phys.uconn.edu/data/Gluex/simulation/simsamples/particle_gun-no-mergehits"
hddmpat = re.compile("particle_gun007_([0-9]*).hddm")

clight = 30 # cm/ns
dEthreshold = 1e-5

hmult = ROOT.TH1D("hmult", "hit multiplicity (left or right)", 100, 0, 100)
htfirst = ROOT.TH1D("htfirst", "earliest tof=(tleft+tright)/2-t0", 1000, 0, 50)
htlast = ROOT.TH1D("htlast", "latest tof=(tleft+tright)/2-t0", 1000, 0, 50)
htmean = ROOT.TH1D("htmean", "mean tof=(tleft+tright)/2-t0", 1000, 0, 50)
htall = ROOT.TH1D("htall", "all tof=(tleft+tright)/2-t0", 1000, 0, 50)

for ifile in os.listdir(datadir):
   for ihddm in hddmpat.finditer(ifile):
      for rec in hddm_s.istream(f"{datadir}/{ihddm.group(0)}"):
         mom = rec.getMomenta()[0]
         ori = rec.getOrigins()[0]
         t0 = ori.t - ori.vz * mom.E / (mom.pz * clight)
         for ctr in rec.getFtofCounters():
            h = {'bar':ctr.bar, 'plane':ctr.plane,
                 'dEleft': [], 'Eleft':[], 'tleft':[],
                 'dEright': [], 'Eright':[], 'tright':[]}
            for tru in ctr.getFtofTruthHits():
               xtra = tru.getFtofTruthExtras()[0]
               if xtra.itrack == 1:
                  if tru.end == 0:
                     h['dEleft'].append(tru.dE)
                     h['Eleft'].append(xtra.E)
                     h['tleft'].append(tru.t)
                  else:
                     h['dEright'].append(tru.dE)
                     h['Eright'].append(xtra.E)
                     h['tright'].append(tru.t)
            nmult = min(len(h['dEleft']), len(h['dEright']))
            tfirst = 999
            tlast = -999
            tsum = [0, 0]
            for i in range(nmult):
               if h['dEleft'][i] > dEthreshold and h['dEright'][i] > dEthreshold:
                  t = (h['tleft'][i] + h['tright'][i]) / 2 - t0
                  tfirst = min(tfirst, t)
                  tlast = max(tlast, t)
                  tsum[0] += 1
                  tsum[1] += t
                  htall.Fill(t)
            hmult.Fill(tsum[0])
            if tsum[0] > 0:
               htfirst.Fill(tfirst)
               htlast.Fill(tlast)
               htmean.Fill(tsum[1] / tsum[0])
