module FourToOneMux(A, B, C, D, S, Out);
parameter N = 2;

input [N-1:0] A, B, C, D;
input [1:0] S;
output logic [N-1:0] Out;

always_comb
begin
case(S)
	2'b00:	Out = A;
	2'b01:	Out = B;
	2'b10:	Out = C;
	2'b11:	Out = D;
endcase
end

endmodule


module NibbleFFO(nibble, inputValid, subIdx);
// Takes in a 4 bit word and encodes it as a 2 bit index
input [3:0] nibble;
output logic inputValid;
output logic [1:0] subIdx;

assign inputValid = |nibble;
assign subIdx[0] = nibble[3] | nibble[1] & ~nibble[2]; 
assign subIdx[1] = nibble[3] | nibble[2];

endmodule

module FindFirstOne(word, valid, index); 
`define NIBBLE_TOP 4*i+3
`define NIBBLE_BOT 4*i
parameter N = 24;
localparam DIFF_FROM_32 = 32 - N;
localparam INDEX_WIDTH = $clog2(N + DIFF_FROM_32);
localparam EMPTY_NIBBLES = DIFF_FROM_32 / 4;
localparam NUM_NIBBLES = N / 4;

input [N-1:0] word;
output logic valid;
output logic [INDEX_WIDTH-1:0] index;

genvar i;

logic [7:0] nibbleValid;
logic [1:0] subIdx [5:0];	
logic [1:0] groupIdx [1:0];
logic [1:0] nibbleSelect [1:0];  
//logic [1:0] topNibbleIdx, botNibbleIdx;
logic topValid, botValid;

generate
for (i = 0; i < NUM_NIBBLES; i++)
	begin: nibbleValidNet
		NibbleFFO n(word[`NIBBLE_TOP:`NIBBLE_BOT], nibbleValid[i], subIdx[i]);
	end
endgenerate

FourToOneMux firstIdx0(subIdx[0], subIdx[1], subIdx[2], subIdx[3], nibbleSelect[0], groupIdx[0]);
FourToOneMux firstIdx1(subIdx[4], subIdx[5], 2'b0, 2'b0, nibbleSelect[1], groupIdx[1]);

// Feeding nibbles comprised of the valid bits into the NibbleFFO module
NibbleFFO botFFO(nibbleValid[3:0], botValid, nibbleSelect[0]);
NibbleFFO topFFO({{EMPTY_NIBBLES{1'b0}}, nibbleValid[5:4]}, topValid, nibbleSelect[1]);

always_comb
begin

index[1:0] = groupIdx[1] | groupIdx[0] & ~{2{topValid}};
index[2]   = nibbleValid[5] 
	   |(nibbleValid[3] | nibbleValid[1] & ~nibbleValid[2]) & ~topValid;
index[3]   = (nibbleValid[3] | nibbleValid[2])& ~topValid;
index[4]   = topValid;
valid	   = topValid | botValid;
end

endmodule  	
