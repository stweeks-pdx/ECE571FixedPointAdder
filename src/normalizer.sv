module Normalizer(mantissa, exp, shiftRight, normedExp, normedMantissa, index);
parameter  MANTISSA_N   = 25;
parameter  EXP_N	= 8;
parameter  FILL_TO	= 32;
localparam MANTISSA_MSB = MANTISSA_N - 1;
localparam EXP_MSB      = EXP_N - 1;
localparam SHIFT_MSB    = $clog2(FILL_TO) - 1;

input logic [MANTISSA_MSB:0]   mantissa;
input logic signed [EXP_MSB:0] exp;
input logic		       shiftRight;	// Signal for control if right shift is needed
output logic [EXP_MSB:0]       normedExp;
output logic [MANTISSA_MSB:0]  normedMantissa;
output logic [SHIFT_MSB:0]     index;		// Signal to control for index

logic [MANTISSA_MSB:0] rightShiftMantissa, leftShiftMantissa;
logic [FILL_TO-MANTISSA_N:0] fillIn, fillOut;
logic valid;
logic [SHIFT_MSB:0] ShiftAmount;
logic [EXP_MSB:0]   incrementedExp;

assign fillIn = '0;

/* Normalizing the mantissa */
assign rightShiftMantissa = mantissa >> 1;

FindFirstOne mantissaFFO(mantissa, valid, index);
assign ShiftAmount = 24 - index; 	// Looking to normalize so first one is at 24th bit

BarrelShifter shiftMantissa({fillIn, mantissa}, ShiftAmount, 1'b0, {fillOut, leftShiftMantissa});

// If control says to shift right (mantissa == 1X.XX...) then shift right, else shift left
assign normedMantissa = (shiftRight) ? rightShiftMantissa: leftShiftMantissa;


/* Normalizing the exponent */
assign normedExp = (shiftRight) ? exp - 1: exp + ShiftAmount;

endmodule
