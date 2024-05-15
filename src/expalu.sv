module ExpALU(ExpA, ExpB, ExpSet, ExpDiff);
parameter N = 8;
localparam BIAS = ((2**N)/2) - 1;
localparam MSB = N - 1;

input [MSB:0] ExpA, ExpB;
output [MSB:0] ExpDiff;
output ExpSet;

logic signed [MSB:0] DeBiasedExpA, DeBiasedExpB;

// Circuit to remove exponent bias
assign DeBiasedExpA = ExpA - BIAS;
assign DeBiasedExpB = ExpB - BIAS;

// Comparator Circuit for Exponents
assign ExpSet = (DeBiasedExpA >= DeBiasedExpB) ? 1 : 0;

// Subtractor Circuit for Exponents
assign ExpDiff = (ExpSet ? DeBiasedExpA - DeBiasedExpB : DeBiasedExpB - DeBiasedExpA);

endmodule
