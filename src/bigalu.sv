module bigalu(FracA, FracB, SignA, SignB, Result, ccc, ccz, ccv, ccn);
parameter N = 24;
localparam MSB = N - 1;

input [MSB:0] FracA, FracB;
input SignA, SignB;
output [MSB:0] Result;
output ccc, ccz, ccv, ccn;

// internal signals
logic [N:0] FracA2sC, FracB2sC, InvResult;
logic [N+1:0] AddendA, AddendB;
logic [MSB:0] MidResult;
logic cb;

// create 2's compliment for the mux
assign FracA2sC = ~{1'b0, FracA} + 1'b1;
assign FracB2sC = ~{1'b0, FracB} + 1'b1;

mux #(N+2) mA({SignA,FracA2sC}, {2'b0,FracA}, SignA, AddendA);
mux #(N+2) mB({SignB,FracB2sC}, {2'b0,FracB}, SignB, AddendB);

// ALU addition + flags
assign {ccn, cb, MidResult} = 26'(AddendA) + 26'(AddendB);
// assign ccc = cb;
assign ccz = ({ccn, ccc, MidResult} == 0); // (not sure this is correct)
// assign ccv = (MidResult[N] != AddendA[N]) && (AddendA[N] == AddendB[N]);
assign ccv = (ccn != AddendA[N]) && (AddendA[N] == AddendB[N]);
// assign ccn = MidResult[N];
assign ccc = (ccn) ? InvResult[N] : cb;

assign InvResult = ~{cb, MidResult} + 1'b1;
assign Result = (ccn ? InvResult : MidResult);


endmodule

module mux(A, B, S, Y);
parameter BITS = 23;
localparam MSB = BITS - 1;

input [MSB:0] A, B;
input S;
output [MSB:0] Y;

assign Y = (S ? A : B);

endmodule
