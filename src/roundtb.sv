module top;
parameter  TEST_N   = 25;
localparam MSB = TEST_N-1;

logic [MSB:0] TestIn, TestOut;
logic TestRound, TestSticky;

int j = 0;
int i;
int unsigned max;
int ErrorSeen = 0;

RoundNearestEven #(TEST_N) DUT(TestOut, TestIn, TestRound, TestSticky);

function automatic void CompareResults(input logic [MSB:0] Observed, Expected);

if (Observed !== Expected)
	begin 
	$display("ERROR:\n\tIn: %b\tRound: %b\tSticky: %b\tExpected: %b\tObserved: %b\n", 
			   TestIn, TestRound, TestSticky, Expected,     Observed);
	ErrorSeen = 1'b1;
	end

endfunction

task automatic CheckResults(); 
int unsigned CheckVal; 
logic [MSB:0] Expected;

CheckVal = {TestIn, TestRound, TestSticky};

if ((CheckVal % 4) > 2)
	begin
	Expected = TestIn + 1;
	#10 CompareResults(TestOut, Expected);
	end
else if ((CheckVal % 4) < 2)
	begin
	Expected = TestIn;
	#10 CompareResults(TestOut, Expected);
	end
else
	begin
	Expected = (TestIn[0]) ? TestIn + 1 : TestIn;
	#10 CompareResults(TestOut, Expected);
	end

endtask

initial
begin
`ifdef DEBUG
	$monitor(In: %b\tRound: %b\tSticky: %b\tObserved: %b\n", 
		 TestIn, TestRound, TestSticky, TestOut);
`endif

max = 2**TEST_N - 1;
for (j=0; j<= max; j++)
	for (i=0; i<4; i++)
		begin
		TestIn = j;
		{TestRound, TestSticky} = i;
		#10 CheckResults();
		end

if (ErrorSeen == 0) $display("*** NO ERRORS ***");
else $display ("*** ERROR SEEN ***");

end

endmodule
