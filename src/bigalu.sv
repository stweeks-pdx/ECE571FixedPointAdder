module bigalu(FracA, FracB, SignA, SignB, Result, ccc, ccz, ccv, ccn);
parameter N = 24;
localparam MSB = N - 1;

input [MSB:0] FracA, FracB;
input SignA, SignB;
output [MSB:0] Result;
output ccc, ccz, ccv, ccn;

// internal signals
logic [N:0] FracA2sC, FracB2sC;
logic [N:0] AddendA, AddendB;
logic [N:0] MidResult;
logic cb;

// create 2's compliment for the mux
assign FracA2sC = ~{SignA, FracA} + 1'b1;
assign FracB2sC = ~{SignB, FracB} + 1'b1;

mux mA(FracA2sC, {1'b0,FracA}, SignA, AddendA);
mux mB(FracB2sC, {1'b0,FracB}, SignB, AddendB);

// ALU addition + flags
assign {cb,MidResult} = AddendA + AddendB;
assign ccc = cb;
assign ccz = (MidResult[N:0] == 0); // (not sure this is correct)
assign ccv = (MidResult[N] != AddendA[N]) && (AddendA[N] == AddendB[N]);
assign ccn = MidResult[N];

assign Result = (ccn ? ~MidResult[MSB:0] : MidResult[MSB:0]);

endmodule

module mux(A, B, S, Y);
parameter BITS = 25;
localparam MSB = BITS - 1;

input [MSB:0] A, B;
input S;
output [MSB:0] Y;

assign Y = (S ? A : B);

endmodule
