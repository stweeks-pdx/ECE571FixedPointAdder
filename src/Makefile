DEBUG?=false
ifeq ($(DEBUG), true)
	EXTRAFLAGS="+define+DEBUG"
else
	EXTRAFLAGS=
endif

.PHONY: build clean floatpkg barrelshifter expalu bigalu
build:
	vlib work

clean:
	rm -rf work

floatpkg:
	vlog -source -lint $(EXTRAFLAGS) floatingpointpkg.sv floatingpointpkgtest.sv
	vsim -c top

barrelshifter:
	vlog -source -lint $(EXTRAFLAGS) barrelshifter.sv barrelshiftertest.sv
	vsim -c top

expalu:
	vlog -source -lint $(EXTRAFLAGS) expalu.sv expalutb.sv
	vsim -c top

findfirstone:
	vlog -source -lint $(EXTRAFLAGS) findfirstone.sv ffotb.sv
	vsim -c top

round:
	vlog -source -lint $(EXTRAFLAGS) round.sv roundtb.sv
  vsim -c top

bigalu:
	vlog -source -lint $(EXTRAFLAGS) bigalu.sv bigalutb.sv bigalu-kgm.sv fulladder.sv
	vsim -c top
