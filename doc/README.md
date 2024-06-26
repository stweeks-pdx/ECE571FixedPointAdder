## Documentation
This directory includes all documentation surrounding the design choices, for how to run the system please refer to the master README at the root of this project.

## Block Diagram
![Floating Point Adder Block Diagram](FloatingPointAdder.jpg)

![Control FLow](workflow.png)

## Floating Point Interface
For the floating point system the user is required to put their two addends on lines addendA and addendB, when the user wants to begin computation they will set
the Go bit high (deassertion of Go is the responsibility of the user), in which place the Ready bit will go low. The Ready bit stays low until the computation 
is complete, where the system will set the Ready bit high and the Result of the computation will be on the Result line. The computation also will provide a Zero,
Inf, and NaN flags to alert the user to if the result was zero, infinity, or not-a-number respectively. This does not guarauntee that NaN or Inf is on the Result
line. The AddendA, AddendB, and Result are all of type float, which is a packed struct representing the IEEE-754 single precision floating point number. Because it
is packed, the user can either use the 32-bit number directly, or convert to a realshort using the provided package  interfaces. The floating point adder receives
a clock and reset for an internal control system, but the system is not designed to operate around a set calculation period but instead relies on handshaking for
the computation. The design does not support denormalized numbers.

### NOTE: Currently NaN and Inf flag go high at the same time as we have no clever way to distinguish the two in the adder

## SV Constructs Used
For this design we made use of the follwoing System Verilog constructs: unique case, packed structs, classes, randomized constraints, coverage, enums, always_ff,
and always_comb.

## Sub Components

# Exponent ALU
Exponent ALU

![Exponent ALU](ExponentALU.jpg)

The Exponent ALU is responsible for determining which exponent is passed forward and by what amount the system should do a right shift of the smaller exponents
mantissa. The exponent ALU takes in two 8-bit wide exponents and returns an 8-bit difference and set bit that are fed to the FSM. First the exponent ALU needs
to de-bias the incoming exponents by subtracting 128 from them, it then will pass these to a comparison unit that sees if A >= B or A < B. If the former is true
the ExpSet bit is set to 1, else it is set to 0. This set bit is also used to determine the subtraction operation where the smaller exponent is subtracted from
the larger and this returns the difference result to ExpDiff.

# Big ALU
Big ALU

![Big ALU](BigAlu.jpg)

The Big ALU is responsible for adding the 2-mantissas together using 2's compliment. Because the IEEE-754 standard is in signed magnitude, and we have the implied
1 for the 1.M, we need to pass the sign down to select if we need to 2's compliment the numbers before adding as well as a phantom 0, this is accomplished with the
sign bit and 0 concactenated to the 2's compliment and fed to a 2:1 Mux. We also need to append thei phantom 0 and signed bit to the front of the values so as to add the signed
information back in, to give the number a true 2's compliment value. Once this is accomplished we pass the values into an adder and return the result along with the
ccc, ccz, ccv, and ccn flags to be consumed by the normalizer circuit.

# Normalizer
### Barrel Shifter

![Barrel Shifter Circuit](BarrelShifter.jpg)


### Find First One

![Find First One Circuit](FindFirstOne.jpg)


### Normalizer

![Normalizer Circuit](Normalizer.jpg)

The normalizers circuitry (we decided to pull the find first one out but is a part of its function) purpose is to take in the mantissa and shift it to the appropriate
point such that we get 1.M format. This may involve a single right shift or a multiple left shift. The left shift was implemented using the barrel shifter provided in class
where the right shifter is hard coded as it is only ever one shift. The find first one's circuities job is to find the first occurrance of a one and then return the
index to that one location, allowing us to determine by what amount the mantissa needs shifted to create the 1.M value. The exponent normalization is also accomplished
by this determined shift amount based on if we shift left or right then merely do an add or subtract operation.

# Rounding Hardware
![Rounding Circuit](Rounding.png)

The Rounding circuit uses logic gates to assert a RoundUp signal. This signal is then added to the In value to make our rounded Out Value.
There is currently a known issue where the rounding circuit is only capable of rounding up and does not take into account the possibility of rounding down in the case of differing
signs; in these cases our circuit would need to reduce the magnitude rather than rounding up for specific RoundBit and StickyBit values.

# Control System

![FSM Black Box](fsmblackbox.png)

![FSM Diagram](fsm.png)

The FSM controls the components in the data path during the design flow. The functions of the FSM are as follows:

1. Based on the Exponent Difference, the FSM either enables or disables the Right Shift register. Simultaneously the FSM also enables the selector for the Exponent Mux.
This step ensures that the smaller Addend Mantissa is right shifted and its Exponent is incremented by exponent Differences.

2. The FSM uses FFOValid and FFOIndex to initiate normalization. When carry is generated during the addition, the Sum is right shifted once. If the MSB-1 bit of the Sum
is '1', the Sum is left shifted once. Otherwise, shift operation is not performed on the Sum.

3. During rounding, the FSM checks if a carry is generated. When a carry is generated, the FSM performs normalization by shifting the Result to the right as well as
incrementing the exponent.

4. After rounding, the FSM sets the Ready signal until the reception of the next Go signal.

# Testing Strategy
For the testing our strategy we used directed and constrained randomized testing. For the directed testing we wanted to test the following cases:

--- -0 added to +0

--- -0 added to a float

--- +0 added to a float

--- The two largest numbers for IEEE-754 added together

--- The two smallest numbers fo IEEE-754 added together

--- Three float number pairs added together

---- one with opposite signs and two with matching signs

For the randomized testing we used the floating point class we desing but also added a constraint that produces only normalized numbers. We run through 2^32 cases
of this randomization constraint where we are feeding normalized numbers into our adder. We then randomize with the constraint of only denormalized numbers to pass into 
our module to verify that we can handle denorms (without doing the addition) gracefully. We also do this 2^32 times to make sure we don't encounter any edge cases. Our 
final randomization test disables all constraints and we generate 2^32 random numbers in the hopes to generate some NaN and INF numbers to verify our approach.

We want to use coverage to verify that we see rounding, a denormalized result, and one of an INF or NaN in our results output (ideally both). The hope is by iterating over 2^32
cases we increaase our chances of hitting all possibilities for the adder and any possible edge cases.

For the class, FpClass, contained our constrained randomization. While not all constraints were used in the testing, below is an exhaustive list of all constraints in the class:

1. Denormalized numbes are not generated

2. Only denomarlized numbers are generated

3. NaN is not generated

4. Inf is not generated

6. Exponent is in the range of 1 to 254

7. Only normalized numbers are generated

## Coverage
Coverage samples the outputs of the floating-point adder using the following cover points:

NOTE: Option is set to at least 1 value.

1. Sign of the Result when Ready is asserted

2. Exponent ranging from 1 to 254 when Ready is asserted

3. Mantissa ranging from 0 to 2^23 - 1 when Ready is asserted

4. Cross between Sign and Mantissa

5. Cross between Sign and Exponent

6. Result is Zero when Ready is asserted

7. Result is Inf when Ready is asserted

8. Result is NaN when Ready is asserted

9. Result is Denorm when Ready is asserted 

## Sub-module Testing
We used the V approach to testing that was discussed in class. Each sub-module that we designed we also created tests for to verify that our approach was correct. This
allowed us to have extreme confidence that bugs at the sub-module level would be design based and spec based and not logical errors. Each test can be ran individually from
the Makefile using the `make <module>` command and DEBUG can be set to true. This approach was chosen as it allowed multiple people to work on sub-components without having
to have an immediate knowledge of the final integration of the system. Tests followed exhaustive testing standards where applicable, and assertions were used for the FSM.

Assertions used for testing the FSM:
1. On reset, FSM state must be IDLE.

2. FSM State should not transition from DISSR to ENSRGT or ENSRLT.

3. FSM State should not transition from ENSRGT to DISSR or ENSRLT.

4. FSM State should not transition from ENSRLT to DISSR or ENSRGT.

5. FSM State should not transition from SR to SL or NOSHIFT.

6. FSM State should not transition from SL to SR or NOSHIFT.

7. FSM State should not transition from NOSHIFT to SL or SR.

8. SelSRMuxL should be low when SelExpMux &amp; SelSRMuxG is high.

9. SelExpMux &amp; SelSRMux should be zero when SelSRMuxL is set.

10. Shift Right enable and Shift Right amount should be zero when ExpDiff is zero.

11. Shift Right enable and Shift Right amount should not be zero when ExpDiff is not zero.

12. SelExpMux &amp; SelSRMuxG should be set when ExpSet is set.

13. SelExpMux &amp; SelSRMuxG should not be set when ExpSet is not set.

14. When SREn is set, SLEn and NoShift should not be set.

15. When SLEn is set, SREn and NoShift should not be set.

16. When NoShift is set, SLEn and SREn should not be set.

17. When SREn is set, ShiftAmount should be zero.

18. When SLEn is set, ShiftAmount should be set to the required amount.

19. When NoShift is set, ShiftAmount should be zero.

20. When FFOValid is set, one of the following signals (SREn, SLEn, NoShift) should be set.

21. When FFOValid is not set, NoShift should be set.

22. When FFOValid is reset or set in states DISSR, ENSRGT, and ENSRLT, SelMuxR
should not be set.

23. SelMuxR should be set in the ROUND state.

24. FlagResult should be set after rounding.
