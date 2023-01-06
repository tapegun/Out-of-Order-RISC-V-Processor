#Collect All Source Files
PKG_SRCS := $(shell find $(PWD)/pkg -name '*.sv')
HDL_SRCS := $(shell find $(PWD)/hdl -name '*.sv')
HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

SYNTH_TCL := $(CURDIR)/synthesis.tcl

VCS_FLAGS= -full64 -sv=2012 +lint=all,noSVA-UA,noNS,noSVA-AECASR -timescale=1ns/10ps -debug_acc+all -kdb -fsdb +v2k +incdir+$(PWD) 

.PHONY: clean
.PHONY: run
.PHONY: synth

sim/simv: $(SRCS)
	mkdir -p sim
	cd sim && vcs -R $(SRCS) $(VCS_FLAGS) -msg_config=../warn.config

sim/grading: $(SRCS)
	mkdir -p sim
	cd sim && vcs -o grading -R $(SRCS) $(VCS_FLAGS) 

run: sim/simv
	cd sim && ./simv

grade: sim/grading
	cd sim && ./grading

clean: 
	rm -rf sim