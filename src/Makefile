DEBUG?=false
ifeq ($(DEBUG), true)
	EXTRAFLAGS="+define+DEBUG"
else
	EXTRAFLAGS=
endif

.PHONY: build clean floatpkg barrelshifter expalu
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
