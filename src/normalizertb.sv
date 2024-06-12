module top;
parameter  MANTISSA_N   = 25;
parameter  EXP_N	= 8;
parameter  FILL_TO	= 32;
localparam MANTISSA_MSB = MANTISSA_N - 1;
localparam NORM_MSB	= MANTISSA_MSB - 1;
localparam EXP_MSB      = EXP_N - 1;
//localparam FILL_MSB	= FILL_TO - 1;
localparam SHIFT_MSB    = $clog2(FILL_TO) - 1;

logic [MANTISSA_MSB:0]   mantissa;
logic signed [EXP_MSB:0] exp;
logic	 	         shiftRight;	// Signal for control if right shift is needed
logic [EXP_MSB:0]        normedExp, expectedExp;
logic [MANTISSA_MSB:0]   normedMantissa, expectedMantissa;
logic [SHIFT_MSB:0]      index, ShiftAmount;		// Signal to control for index
logic			 valid, expectedValid;
logic			 SREn, SLEn;


int j;
int ErrorSeen = 0;

Normalizer #(MANTISSA_N, EXP_N, FILL_TO) normDUT(.mantissa, .exp, .SREn, .SLEn, .ShiftAmount, .normedExp, .normedMantissa);
FindFirstOne #(MANTISSA_N) ffoDUT(mantissa, valid, index);

assign SREn = mantissa[MANTISSA_MSB];
assign SLEn = (SREn) ? 1'b0 : ~mantissa[MANTISSA_MSB-1] & valid;
assign ShiftAmount = 23 - index;

initial
begin
`ifdef DEBUG
	$monitor("INPUT:  Exp %0d\t Mantissa %b\t ShiftR %b\t\n\
OUTPUT: Exp %0d\t Mantissa %b\t Index %0d\t Valid %b\n",
		  exp, mantissa, shiftRight, normedExp, normedMantissa, index, valid);
`endif
// First test mantissa norming with set exp 
exp = 8'b0100_0000;
for (j=0; j<2**MANTISSA_N; j++)
	begin
	mantissa = j;
	expectedMantissa = mantissa;
	expectedExp = exp;
	expectedValid = 1'b1;
	shiftRight = mantissa[MANTISSA_MSB];
	if (mantissa[MANTISSA_MSB])
		begin
		expectedMantissa = expectedMantissa >> 1;
		expectedExp = expectedExp + 1;		
		end
	else if (mantissa == 0)
		expectedValid = 1'b0;
	else 
		begin
		while (expectedMantissa[NORM_MSB] != 1)
			begin
			expectedMantissa = expectedMantissa << 1;
			expectedExp = expectedExp - 1;
			end
		end
	#10;
	if (normedMantissa !== expectedMantissa||normedExp !== expectedExp||valid !== expectedValid)
		begin
		$display("ERROR:INPUT:    Exp %d\t Mantissa %b\t ShiftR %b\n\
\tOBSERVED: Exp %d\t Mantissa %b\t Valid %b\n\
\tEXPECTED: Exp %d\t Mantissa %b\t Valid %b\n",
			          exp, mantissa, shiftRight,
				  normedExp, normedMantissa, valid,
				  expectedExp, expectedMantissa, expectedValid);
		ErrorSeen = 1'b1;
		end
	end

// Then check exp incr/decr with set mantissa pattern?
// TODO: Maybe think of a test that makes sense here
//	 I think it will fail any cases of over/underflow but that's expected behavior
//	 so maybe this test is not needed

if (ErrorSeen == 0) $display("*** NO ERRORS ***");
else $display("*** ERROR SEEN ***");
$finish;
end
endmodule
