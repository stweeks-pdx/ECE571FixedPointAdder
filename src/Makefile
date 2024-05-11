.PHONY: build clean floatpkg
build:
	vlib work

clean:
	rm -rf work

floatpkg:
	vlog -source -lint floatingpointpkg.sv floatingpointpkgtest.sv
	vsim -c top
