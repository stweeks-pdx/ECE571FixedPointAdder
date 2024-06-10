# ECE 571 IEEE-754 ADDER Group 1
IEEE-754 Point Adder for ECE 571 at PSU

## Introduction
This repo contains the instructions for a IEEE-754 adder for Team 1 in ECE 571 Spring 2024.


The goal of this project was to design an IEEE-754 single precision floating point adder.
This involved designing and testing all the internals needed to create a floating point adder 
that could take two normalized numbers and perform floating point addition with even rounding and
normalization. For group 1 we focused on a handshake approach that included a FSM control path and
a separate datapath drawn from the specs provided to us by Professor Faust.


The layout of the project includes this README, a doc directory that includes documentation and
design constraints, and a src directory that includes all System Verilog files including tests and
a general Makefile.


This README will provide a quick tutorial instruction on general overview of how to build the system
and run testing.

## Building the Project
Inside the `src/` directory you can find the Makefile, this will be what is needed to build any sub directory
or the total project.


For example, if you wanted to run the normalizer circuit you can look for the normalizer build instruction in the Makefile
to see what the name is, but all individual components build name is the same as their module name (all lower case).


To build the Normalizer Circuit you will need to follow these steps:
1) run `make clean`. This will clean the directory for you.


2) run `make build`. This will setup the vlib library under the `work/` directory.


3a) run `make normalizer`. This runs the vlog and vsim commands for the user. This does not allow, currently, for overwriting
parameters, so one would need to remove the vsim part of the build command.


3b) if a user wanted DEBUG set they would run `make normalizer DEBUG=true`.


By following these three steps someone can come in and quickly run and review all tests for the Floating Point Adder project.

