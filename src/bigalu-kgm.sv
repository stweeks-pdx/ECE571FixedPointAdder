module AddSub8Bit (result, x, y, ccn, ccz, ccv, ccc, sub);
parameter N = 8;

input [N-1:0] x, y;
output [N-1:0] result;
output ccn, ccz, ccv, ccc;
input sub;

wire [N-1:0] ySub;
wire [N:0] C;

genvar i;

// Connect sub to initial carry in 
buf buf1(C[0], sub);

// Instantiating our FA slices and XOR to complement y
generate
for (i = 0; i < N; i++)
	begin: SliceXor 
		xor x(ySub[i], y[i], sub);
	end
for (i = 0; i < N; i++)
	begin: SliceFA
		FullAdder fa(result[i], C[i+1], x[i], ySub[i], C[i]);
	end
endgenerate

// Connecting cc signals from results
buf neg(ccn, result[N-1]);
assign ccz = ~|(result);
xor over(ccv, C[N], C[N-1]);
buf carry(ccc, C[N]);

endmodule
