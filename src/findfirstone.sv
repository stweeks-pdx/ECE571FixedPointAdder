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


// TODO: Hard code to 23 bits
// TODO: Split nibble FFO into module

module FindFirstOne(word, valid, index); 
parameter N = 32;
localparam INDEX_WIDTH = $clog2(N);

input [N-1:0] word;
output logic valid;
output logic [INDEX_WIDTH-1:0] index;

genvar i;

// TODO: Determine how to parameterize everything below this point
logic [7:0] subV;
logic [1:0] subIndex [9:0];	// 2 extra are for non-parameterized tasks and modules
logic [1:0] idxSelect [2:0];  // same as above

function automatic bit [2:0] subFFO(input bit [3:0] subWord);
// Takes in a 4 bit word and encodes it as a 2 bit index
logic v;
logic [1:0] subIdx;
v = |subWord;
subIdx[0] = subWord[3] | subWord[1] & ~subWord[2]; 
subIdx[1] = subWord[3] | subWord[2];

return {v, subIdx};
endfunction

generate
for (i = 0; i < 8; i++)
	begin: subVNet
		assign {subV[i], subIndex[i]} = subFFO(word[4*i+3: 4*i]);
	end
endgenerate

// TODO: Replace multiple modules with generate when parameterizing
FourToOneMux preIdx0(subIndex[0], subIndex[1], subIndex[2], subIndex[3], idxSelect[0], subIndex[8]);
FourToOneMux preIdx1(subIndex[4], subIndex[5], subIndex[6], subIndex[7], idxSelect[1], subIndex[9]);

// TODO: Modify final assignments when when parameterizing
always_comb
begin
// Feeding nibbles comprised of the valid bits into the FFONibble circuit
{idxSelect[2][0], idxSelect[0]} = subFFO(subV[3:0]); 
{idxSelect[2][1], idxSelect[1]} = subFFO(subV[7:4]);

index[1:0] = subIndex[9] | subIndex[8] & ~{2{idxSelect[2][1]}};
index[2]   = subV[7] | subV[5] & ~subV[6]
	   |(subV[3] | subV[1] & ~subV[2]) & ~idxSelect[2][1];
index[3]   = subV[7] | subV[6]
	   |(subV[3] | subV[2])& ~idxSelect[2][1];
index[4]   = idxSelect[2][1];
valid	   = idxSelect[2][1] | idxSelect[2][0];
end

endmodule   	

