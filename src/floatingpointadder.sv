import floatingpointpkg::*;

module FloatingPointAdder(input float AddendA,
			  input float AddendB,
			  input logic Go,
			  output float Result,
			  output logic Zero, 
			  output logic Inf,
			  output logic Nan);
parameter VERSION = "0.2";

//*** TENTATIVE MODULE SKELETON ***//

// *** Small ALU
// Inputs: exponent from AddendA
// 	   exponent from AddendB
//
// Outputs: exponent difference to Control
ExpALU expALU(AddendA.exp, AddendB.exp, ExpSet, ExpDiff);

// *** Exponent MUX
// Inputs: exponent from AddendA
// 	   exponent from AddendB
// 	   expSelect from Control
//
// Outputs: value of larger exponent to ExpIncrement MUX
assign expToPipe0 = (SelExpMux) ? AddendA.exp : AddendB.exp;
always @(posedge Clock) expToPreNorm <= expToPipe0;


// *** Small Mantissa MUX
// Inputs: mantissa from AddendA
// 	   mantissa from AddendB 
// 	   mantSelect from Control
//
// Outputs: smaller mantissa to Pre-add Shifter
assign mantSmall = (SelSRMuxL) ? AddendA.frac : AddendB.frac;
assign signSmall = (SelSRMuxL) ? AddendA.sign : AddendB.sign;
always @(posedge Clock) mantToShiftRight <= {1'b1, mantSmall};
always @(posedge Clock) signAtoALU <= signSmall; 

// *** Large Mantissa MUX
// Inputs: mantissa from AddendA
// 	   mantissa from AddendB 
// 	   ~mantSelect from Control
//
// Outputs: larger mantissa to Big ALU
assign mantLarge = (SelSRMuxG) ? AddendA.frac : AddendB.frac;
assign signLarge = (SelSRMuxG) ? AddendA.sign : AddendB.sign;
always @(posedge Clock) mantBtoALU <= {1'b1, mantLarge};
always @(posedge Clock) signBtoALU <= signLarge;

// *** Pre-add Shifter
// Inputs: smaller mantissa from MUX
// 	   pre-add shift amount from Control
//
// Outputs: shifted mantissa to Big ALU
RightShifter #(48) shiftPreALU({mantToShiftRight, 24'h0}, ShiftRightAmount, {mantAtoALU, RoundBit, StickyVal});


// *** Big ALU
// Inputs: shifted mantissa from Pre-add Shifter
// 	   larger mantissa from Large Mantissa MUX
// 	   add/sub signal from Control
//
// Outputs: mantissa sum to Control 		## Specifically FindFirstOne module I'm guessing
// 	    mantissa sum to SumShift Mux 	 
bigalu BigALU(mantAtoALU, mantBtoALU, signAtoALU, signBtoALU, mantSum, ccc, ccz, ccv, ccn);


// *** SumShift MUX				
// Inputs: mantissa sum from Big ALU
// 	   rounded mantissa from Rounding Hardware
// 	   sumShiftSelect from Control
//
// Outputs: un-normalized mantissa to Normalizing Shifter
assign mantToPipe1 = (SelManMuxR) ? mantRounded : mantSum;
assign signToPipe1 = (SelManMuxR) ? signRounded : ccn;
always @(posedge Clock) mantToNorm <= mantToPipe1;
always @(posedge Clock) signToNorm <= signToPipe1;

// *** ExpIncrement MUX
// Inputs: larger exponent from Exponent MUX
// 	   rounded exponent from Rounding Hardware  
// 	   expIncrSelect from Control
//
// Outputs: pre-incremented/decremented exponent to ExpIncrDecr
assign expToPipe1 = (SelExpMuxR) expRounded : expToPreNorm;
always @(posedge Clock) expToNorm <= expToPipe1;

// *** Normalizer circuit includes:
//   * ExpIncrDecrement
// Inputs: pre-incr/decr exponent from ExpIncrement MUX
// 	   incr/dec amount from Control
//
// Outputs: pre-rounded exponent to Rounding hardware
//   * Normalizing Shifter
// Inputs: un-normalized mantissa from SumShift MUX
// 	   norm shift value from Control
// 	   norm shift direction from Control
//
// Outputs: shifted mantissa to Rounding Hardware
// 	    sign bit to Result.sign
Normalizer mantNormalizer(mantToNorm, expToNorm, SREn, expRounded, mantToRound, FFOIndex, FFOValid);

// *** Rounding Hardware
// Inputs: shifted mantissa from Normalizing Shifter
// 	   pre-rounded exponent from ExpIncrDecr
// 	   roudingSignal from Control
//
// Outputs: rounded exponent to ExpIncrement MUX
// 	    rounded exponent to Result.exponent
// 	    rounded mantissa to SumShift MUX
// 	    rounded mantissa to Control
// 	    rounded mantissa to Result.mantissa
RoundNearestEven RoundingHardware(mantRounded, mantToRound, RoundBit, StickyBit);

// *** Control module
// Inputs: exponent difference from Small ALU
//	   mantissa sum from Big ALU
//	   rounded mantissa from Rounding Hardware
//
// Outputs: expSelect to Exponent MUX
// 	    mantSelect to Small Mantissa MUX
//	    ~mantSelect to Large Mantissa MUX
//	    pre-add shift to Pre-add Shifter
//	    add/sub signal to Big ALU
//	    sumShiftSelect to SumShift MUX
//	    norm shift value to Normalizing Shifter
//	    norm shift direction to Normalizing Shifter
//	    expIncrSelect to ExpIncrement MUX
//	    incr/dec amount to ExpIncrDecrement
//	    roundingSignal to Rounding Hardware
// TODO: Insert Anvitha's ControlFSM

endmodule
