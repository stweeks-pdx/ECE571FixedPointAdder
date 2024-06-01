module Normalizer(mantissa, exp, shiftRight, normedExp, normedMantissa, index, valid);
parameter  MANTISSA_N   = 25;
parameter  EXP_N	= 8;
parameter  FILL_TO	= 32;
localparam MANTISSA_MSB = MANTISSA_N - 1;
localparam EXP_MSB      = EXP_N - 1;
localparam FILL_MSB	= FILL_TO - 1;
localparam SHIFT_MSB    = $clog2(FILL_TO) - 1;

input logic [MANTISSA_MSB:0]   mantissa;
input logic signed [EXP_MSB:0] exp;
input logic		       shiftRight;	// Signal for control if right shift is needed
output logic [EXP_MSB:0]       normedExp;
output logic [MANTISSA_MSB:0]  normedMantissa;
output logic [SHIFT_MSB:0]     index;		// Signal to control for index
output logic		       valid;

logic [MANTISSA_MSB:0] rightShiftMantissa, leftShiftMantissa;
logic [FILL_MSB - MANTISSA_N:0] fillIn, fillOut;
logic [SHIFT_MSB:0] ShiftAmount;
logic [EXP_MSB:0]   incrementedExp;

assign fillIn = '0;

/* Normalizing the mantissa */
assign rightShiftMantissa = mantissa >> 1;

FindFirstOne #(.N(MANTISSA_N)) mantissaFFO(mantissa, valid, index);
assign ShiftAmount = 23 - index; 	// Looking to normalize so first one is at 23th bit

BarrelShifter #(.N(FILL_TO)) shiftMantissa({fillIn, mantissa}, ShiftAmount, 1'b0, {fillOut, leftShiftMantissa});

// If control says to shift right (mantissa == 1X.XX...) then shift right, else shift left
assign normedMantissa = (shiftRight) ? rightShiftMantissa: leftShiftMantissa;


/* Normalizing the exponent */
always_comb
	begin
	if (shiftRight)
		normedExp = exp + 1;
	// If no 1s found, then exp remains the same?
	// TODO: Double check if this is a correct assumption
	else if (~valid)
		normedExp = exp;
	else
		normedExp = exp - ShiftAmount;
	end
endmodule
