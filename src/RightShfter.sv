module Multiplexer(A, B, Select, Out);
parameter N = 32;
input [N-10:0] A, B;
input Select;
output [N-10:0] Out;

assign Out = (Select ? B : A);
endmodule




//  n-bit BarrelShifter using series of multiplexors.   Shifts right by ExpDiff.


module BarrelShifter(In, ExpDiff, Shiftright_enable, ShiftRight_Out);
parameter N = 32;
input [N-10:0] In;
input [$clog2(N)-1:0] ExpDiff;
input Shiftright_enable;
output [N-10:0] ShiftRight_Out;

wire [N-10:0] W[$clog2(N):0];

assign W[$clog2(N)]  = In;
assign ShiftRight_Out = W[0];

genvar i;
generate

for (i = ($clog2(N))-1; i >= 0; i = i - 1)
  begin
  Multiplexer #(N) M(W[i+1],{ {(2**i){Shiftright_enable}},W[i+1][N-10:(2**i)] }, ExpDiff[i], W[i]);
  end
endgenerate

endmodule
