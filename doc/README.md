## Documentation
This directory includes all documentation surrounding the design choices, for how to run the system please refer to the master README at the root of this project.

## Block Diagram
![Floating Point Adder Block Diagram](https://github.com/stweeks-pdx/ECE571IEEE754PointAdder/blob/main/doc/FloatingPointAdder.jpg)

## Floating Point Interface
For the floating point system the user is required to put their two addends on lines addendA and addendB, when the user wants to begin computation they will set
the Go bit high, in which place the Ready bit will go low. The Ready bit stays low until the computation is complete, where the system will set the Ready bit high
and the Result of the computation will be on the Result line. The computation also will provide a Zero, Inf, and NaN flags to alert the user to if the result was
zero, infinity, or not-a-number respectively. The AddendA, AddendB, and Result are all of type float, which is a packed struct representing the IEEE-754 single
precision floating point number. Because it is packed, the user can either use the 32-bit number directly, or convert to a realshort using the provided package 
interfaces. The floating point adder recieves a clock and reset for an internal control system, but the system is not designed to operate around a set calculation
period but instead relies on handshaking for the computation.

## Sub Components

# Normalizer
Barrel Shifter
![Barrel Shifter Circuit](https://github.com/stweeks-pdx/ECE571IEEE754PointAdder/blob/feat/Docs/doc/BarrelShifter.jpg)
