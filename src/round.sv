module RoundNearestEven(Out, In, RoundBit, StickyBit);
parameter  N   = 25;
localparam MSB = N-1;

input logic  [MSB:0] In;
input logic  RoundBit, StickyBit;
output logic [MSB:0] Out;

logic GuardBit;
logic RoundUp;

assign GuardBit = In[0];
assign RoundUp = RoundBit & StickyBit
		|GuardBit & RoundBit;

assign Out = In + RoundUp;

endmodule
