module FullAdder(S, CO, A, B, CI);
input A, B, CI;
output S, CO;

wire W0, W1, W2, W3;

xor
	xor1(W0, A, CI),
	xor2(S, W0, B);

and
	and1(W1, A, B),
	and2(W2, A, CI),
	and3(W3, B, CI);

or
	or1(CO, W1, W2, W3);
endmodule
