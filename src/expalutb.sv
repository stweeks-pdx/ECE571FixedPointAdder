module top;
parameter tN = 8;
localparam BIAS = (2**tN)/2;
localparam MIN = (-1*BIAS) + 1;
localparam MAX = BIAS - 1;

// DUT parameters
logic [tN-1:0] ExpA, ExpB, ExpDiff;
logic ExpSet;

ExpALU #(tN) DUT(.ExpA, .ExpB, .ExpSet, .ExpDiff);

// Test parameters
logic [tN-1:0] TDiff;
logic TSet;

int i, j;
int Error; // default case is zero

initial
begin
`ifdef DEBUG
	$monitor("ExpA:%d, ExpB:%d, ExpSet:%b, ExpDiff:%d, i:%d, j:%d",
		   ExpA, ExpB, ExpSet, ExpDiff, i, j);
`endif

for (i = MIN; i < MAX; i++)
begin
	ExpA = i + BIAS;
	for (j = MIN; j < MAX; j++)
	begin
		ExpB = j + BIAS;
		#100;
		if (TSet !== ExpSet || TDiff !== ExpDiff)
		begin
			$display("****ERROR ExpA = %d, ExpB = %d, Expected: ExpSet = %b, ExpDiff = %d Observed: ExpSet = %b, ExpDiff = %d",
					ExpA, ExpB, TSet, TDiff, ExpSet, ExpDiff);
			Error = 1;
		end 
	end
end

if (Error)
	$display("**** FAILED ****");
else
	$display("**** SUCCESS ****");
end

always_comb
begin
	TSet = ExpA >= ExpB;
	if (i > j) TDiff = i - j;
	else       TDiff = j - i;

end
endmodule
