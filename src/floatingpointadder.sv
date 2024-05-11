import floatingpointpkg::*;

module FloatingPointAdder(input float AddendA,
			  input float AddendB,
			  input logic Go,
			  output float Result,
			  output logic Zero, 
			  output logic Inf,
			  output logic Nan);
parameter VERSION = "0.1";

//*** TENTATIVE MODULE SKELETON ***//

// *** Small ALU
// Inputs: exponent from AddendA
// 	   exponent from AddendB
//
// Outputs: exponent difference to Control

// *** Exponent MUX
// Inputs: exponent from AddendA
// 	   exponent from AddendB
// 	   expSelect from Control
//
// Outputs: value of larger exponent to ExpIncrement MUX



// *** Small Mantissa MUX
// Inputs: mantissa from AddendA
// 	   mantissa from AddendB 
// 	   mantSelect from Control
//
// Outputs: smaller mantissa to Pre-add Shifter

// *** Large Mantissa MUX
// Inputs: mantissa from AddendA
// 	   mantissa from AddendB 
// 	   ~mantSelect from Control
//
// Outputs: larger mantissa to Big ALU

// *** Pre-add Shifter
// Inputs: smaller mantissa from MUX
// 	   pre-add shift amount from Control
//
// Outputs: shifted mantissa to Big ALU



// *** Big ALU
// Inputs: shifted mantissa from Pre-add Shifter
// 	   larger mantissa from Large Mantissa MUX
// 	   add/sub signal from Control
//
// Outputs: mantissa sum to Control 		## Specifically FindFirstOne module I'm guessing
// 	    mantissa sum to SumShift Mux 	 



// ## TODO: Confirm understanding of the SumShift datapath
//  	    May be an artifact from shifting multiple times in slide implementation
//
// *** SumShift MUX				
// Inputs: mantissa sum from Big ALU
// 	   rounded mantissa from Rounding Hardware
// 	   sumShiftSelect from Control
//
// Outputs: un-normalized mantissa to Normalizing Shifter

// *** Normalizing Shifter
// Inputs: un-normalized mantissa from SumShift MUX
// 	   norm shift value from Control
// 	   norm shift direction from Control
//
// Outputs: shifted mantissa to Rounding Hardware
// 	    sign bit to Result.sign



// ## TODO: Confirm understading of ExpIncrement datapath
//	    May be an artifact from incrementing multiple times in slide implementation
//
// *** ExpIncrement MUX
// Inputs: larger exponent from Exponent MUX
// 	   rounded exponent from Rounding Hardware  
// 	   expIncrSelect from Control
//
// Outputs: pre-incremented/decremented exponent to ExpIncrDecr

// *** ExpIncrDecrement
// Inputs: pre-incr/decr exponent from ExpIncrement MUX
// 	   incr/dec amount from Control
//
// Outputs: pre-rounded exponent to Rounding hardware



// *** Rounding Hardware
// Inputs: shifted mantissa from Normalizing Shifter
// 	   pre-rounded exponent from ExpIncrDecr
// 	   roudingSignal from Control			## TODO: determine what this signal looks like
//
// Outputs: rounded exponent to ExpIncrement MUX
// 	    rounded exponent to Result.exponent
// 	    rounded mantissa to SumShift MUX
// 	    rounded mantissa to Control
// 	    rounded mantissa to Result.mantissa



// ## TODO: Determine format of Control signals and internal datapath
//	    Is FindFirstOne module internal?
//
// *** Control module 					## FSM?
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


endmodule

