module Normalizer(mantissa, exp, SREn, SLEn, ShiftAmount, normedExp, normedMantissa);
parameter  MANTISSA_N   = 25;
parameter  EXP_N	= 8;
parameter  FILL_TO	= 32;
localparam MANTISSA_MSB = MANTISSA_N - 1;
localparam EXP_MSB      = EXP_N - 1;
localparam FILL_MSB	= FILL_TO - 1;
localparam SHIFT_MSB    = $clog2(FILL_TO) - 1;

input logic [MANTISSA_MSB:0]   mantissa;
input logic signed [EXP_MSB:0] exp;
input logic		       SREn, SLEn; // Signals from control if right/left shift is needed
input logic  [SHIFT_MSB:0]     ShiftAmount;
output logic [EXP_MSB:0]       normedExp;
output logic [MANTISSA_MSB:0]  normedMantissa;

logic [MANTISSA_MSB:0] rightShiftMantissa, leftShiftMantissa;
logic [FILL_MSB - MANTISSA_N:0] fillIn, fillOut;
logic [SHIFT_MSB:0] LeftShiftAmount;
logic [EXP_MSB:0]   incrementedExp;

assign fillIn = '0;

/* Normalizing the mantissa */
assign rightShiftMantissa = mantissa >> 1;

assign LeftShiftAmount = (SLEn) ? (ShiftAmount):0; // Looking to normalize so first one is at 23th bit

BarrelShifter #(.N(FILL_TO)) shiftMantissa({fillIn, mantissa}, LeftShiftAmount, 1'b0, {fillOut, leftShiftMantissa});

// If control says to shift right (mantissa == 1X.XX...) then shift right, else shift left
assign normedMantissa = (SREn) ? rightShiftMantissa: leftShiftMantissa;

/* Normalizing the exponent */
assign normedExp = (SREn) ? exp + 1 : exp - LeftShiftAmount;

endmodule
