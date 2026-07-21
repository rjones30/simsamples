clean:
	rm -f ./*.dat ./*.root ./*.hddm ./*.hbook ./*.rz ./sim.sh ./randoms ./setup  ./worklist ./control.in simsamples.dag.*
	cd particle_gun.d; rm -f ./*.dat ./*.root ./*.hddm ./*.hbook ./*.rz ./sim.sh ./randoms ./setup  ./worklist ./control.in sim*/log.d/* particle_gun.log
	cd particle_g31.d; rm -f ./*.dat ./*.root ./*.hddm ./*.hbook ./*.rz ./sim.sh ./randoms ./setup  ./worklist ./control.in sim*/log.d/* particle_g31.log
	cd particle_g34.d; rm -f ./*.dat ./*.root ./*.hddm ./*.hbook ./*.rz ./sim.sh ./randoms ./setup  ./worklist ./control.in sim*/log.d/* particle_g34.log
	cd mergehists.d; rm -f ./*.dat ./*.root ./*.hddm ./*.hbook ./*.rz ./sim.sh ./randoms ./setup  ./worklist ./control.in sim*/log.d/* mergehists.log

backup:
	cp config/worklist.in config/randoms.in scripts/setup_centos7_container.sh scripts/setup_alma9_container.sh scripts/setup_centos7_local.sh scripts/osg-container.sh scripts/alma9-container.sh scripts/workscript.sh config/hd_recon.config scripts/mergehists.sh scripts/diagnose_holds.py scripts/hold_reason.sh scripts/hold_stickers.sh scripts/mergehists-postscript.py scripts/mergehists-prescript.py scripts/onerror scripts/particle_gun-postscript.py scripts/particle_gun-prescript.py scripts/rescale.py scripts/resubmit.py scripts/stow.py archive/
	cp particle_gun.d/sim_001/particle_gun.sub particle_g31.d/sim_001/particle_g31.sub particle_g34.d/sim_001/particle_g34.sub archive/
	cp mergehists.d/mergehists.sub archive/
	cp mergehists.d/prescript.py archive/mergehists_prescript.py
	cp mergehists.d/postscript.py archive/mergehists_postscript.py
	cp particle_gun.d/prescript.py archive/particle_gun_prescript.py
	cp particle_gun.d/postscript.py archive/particle_gun_postscript.py
	cp particle_g31.d/prescript.py archive/particle_g31_prescript.py
	cp particle_g31.d/postscript.py archive/particle_g31_postscript.py
	cp particle_g31.d/prescript.py archive/particle_g31_prescript.py
	cp particle_g31.d/prescript.py archive/particle_g31_prescript.py
	cp particle_g34.d/postscript.py archive/particle_g34_postscript.py
	cp particle_g34.d/postscript.py archive/particle_g34_postscript.py
	cp simsamples.dag mergehists.dag archive/
	cp Makefile archive/
