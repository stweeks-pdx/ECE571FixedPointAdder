module RightShifter(In, ShiftRightEnable, ShiftRightAmount, Out);
parameter N=48;
parameter M=64;
localparam DIFF = M - N;
localparam MAX_SHIFT_WIDTH = $clog2(N);
input [N-1:0] In;
input [MAX_SHIFT_WIDTH-1:0] ShiftRightAmount;
input ShiftRightEnable;
output [N-1:0] Out;

logic [DIFF-1:0] FillIn, FillOut;
logic [M-1:0] Temp [MAX_SHIFT_WIDTH + 1];


genvar i;

assign FillIn = '0;
assign Temp[0] = {FillIn, In};

generate
	for(i=0; i<MAX_SHIFT_WIDTH; i++)
		assign Temp[i+1] = (ShiftRightAmount[i]) ? (Temp[i] >> 2**i) : Temp[i];
endgenerate

assign {FillOut, Out} = (ShiftRightEnable) ? Temp[MAX_SHIFT_WIDTH] : {FillIn, In};

endmodule
