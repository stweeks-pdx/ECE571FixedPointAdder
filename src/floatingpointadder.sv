import floatingpointpkg::*;

module FloatingPointAdder(input float AddendA,
			  input float AddendB,
			  input logic Go,
			  output float Result,
			  output logic Zero, 
			  output logic Inf,
			  output logic Nan);
parameter VERSION = "0.1";

//*** TENTATIVE MODULE SKELETON ***

// Small ALU
// Takes in exponents from AddendA and AddendB
// Outputs exponent difference

// Exponent MUX
// Takes in exponents from AddendA and AddendB
// Takes in select from Control FSM
// Outputs value of larger exponent 



endmodule

