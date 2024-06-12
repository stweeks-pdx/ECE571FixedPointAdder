module top;
parameter TEST_N = 48;
parameter TEST_M = 64;
localparam SHIFT_WIDTH = $clog2(TEST_N);

class testVectors;
	rand reg [TEST_N-1:0] RandIn; // Random input, without replacement, for testing N >=32
endclass

int i;			// Shift loop iteration
longint unsigned j;	// Test loop iteration

int MAX;		// Cap on test loop iterations
int ErrorsSeen = 0;	// Bool for encountered errors

logic [SHIFT_WIDTH-1:0] TestShift;
logic [TEST_N-1:0] TestIn;
logic TestEn;
wire [TEST_N-1:0] TestOut;

testVectors Random = new;

RightShifter #(TEST_N) M(TestIn, TestEn, TestShift, TestOut);

initial
begin
$display("TESTING\n"); 

// If N > 16, set cap on testing to keep within reasonable timeframe
if (TEST_N > 16)
	MAX = 2**16-1;
else
	MAX = 2**TEST_N-1; 

// Start Testing
TestEn = 1'b1;
for (j = 0; j <= MAX; j+=1)
	begin

	// Check if we're preforming exhaustive or randomized test for TestIn
	if (TEST_N > 16) begin
		assert (Random.randomize());
		TestIn = Random.RandIn;
		end
	else 
		TestIn = j;

	// For loops structured for human readability during debugging
	for (i = 0; i < TEST_N; i = i+1)
		begin
		TestShift = i;
		#10;
`ifdef DEBUG
			$display("Shift = %d\tIn = %b\n\tOut = %b\tExpecting = %b\n", TestShift, TestIn, TestOut, TestIn >> i);
`endif
		if (TestOut !== TestIn >> i) begin 
			$display("ERROR: Shift = %b\tIn = %b\n\tOut = %b\tExpected = %b\n", TestShift, TestIn, TestOut, TestIn >> i);
			ErrorsSeen = 1;
			end;
		end
	end
// Testing Enable
TestEn = 1'b0;
for (j = 0; j <= MAX; j++)
	begin
	assert (Random.randomize());
	TestIn = Random.RandIn;
	for (i = 0; i < TEST_N; i = i+1)
		begin
		TestShift = i;
		#10;
`ifdef DEBUG
			$display("Shift = %d\tIn = %b\n\tOut = %b\tExpecting = %b\n", TestShift, TestIn, TestOut, TestIn);

`endif

		if (TestOut !== TestIn) begin 
			$display("ERROR: Shift = %b\tIn = %b\n\tOut = %b\tExpected = %b\n", TestShift, TestIn, TestOut, TestIn);
			ErrorsSeen = 1;
			end;
		end
	end

$display("FINISHED TESTING");
if(ErrorsSeen == 0)
	$display("*** No Errors ***");
$stop;
end
endmodule
