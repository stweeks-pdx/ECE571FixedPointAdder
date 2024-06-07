module bigalu(FracA, FracB, SignA, SignB, Result, ccc, ccz, ccv, ccn);
parameter N = 24;
localparam MSB = N - 1;

input [MSB:0] FracA, FracB;
input SignA, SignB;
output [MSB:0] Result;
output ccc, ccz, ccv, ccn;

// internal signals
logic [MSB:0] FracA2sC, FracB2sC;
logic [MSB:0] AddendA, AddendB;
logic cb;

// create 2's compliment for the mux
assign FracA2sC = ~FracA + 1'b1;
assign FracB2sC = ~FracB + 1'b1;

mux mA(FracA2sC, FracA, SignA, AddendA);
mux mB(FracB2sC, FracB, SignB, AddendB);

// ALU addition + flags
assign {cb,Result} = AddendA + AddendB;
assign ccc = cb;
assign ccz = (Result[MSB:0] == 0); // (not sure this is correct)
assign ccv = (Result[MSB] != AddendA[MSB]) && (AddendA[MSB] == AddendB[MSB]);
assign ccn = Result[MSB];

endmodule

module mux(A, B, S, Y);
parameter BITS = 24;
localparam MSB = BITS - 1;

input [MSB:0] A, B;
input S;
output [MSB:0] Y;

assign Y = (S ? A : B);

endmodule
