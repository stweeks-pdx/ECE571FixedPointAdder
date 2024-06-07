module top;
parameter TEST_N = 24;

logic [TEST_N-1:0] x, xKGM;
logic [TEST_N-1:0] y, yKGM;
logic [TEST_N-1:0] result, expected;
logic [TEST_N:0] resultKGM;
logic ccn, ccz, ccv, ccc, exn, exz, exv, exc;
logic signA, signB, sub;

int j;
longint unsigned i;
longint unsigned MAX;
int ErrorsSeen = 0;

AddSub8Bit  #(.N(TEST_N+1)) KGM(resultKGM, {signA, xKGM}, {signB, yKGM}, exn, exz, exv, exc, sub);
bigalu	    #(.N(TEST_N)) DUT(x, y, signA, signB, result, ccc, ccz, ccv, ccn);

class RandVector; // Random input, without replacement, for testing TEST_N > 8
	rand logic [2*TEST_N-1:0] Value; 
endclass

RandVector Random = new;

function automatic void CheckResults();
	expected = (exn) ? resultKGM * -1 : resultKGM;
	if ({result, ccn, ccz, ccv, ccc} !== {expected, exn, exz, exv, exc})
		begin
		$display("ERROR:\n\tInput: (%s%d) + (%s%d)",(signA) ? "-" : "+", x,(signB) ? "-" : "+", y); 
		$display("\tExpected: Result = %d, ccn = %b, ccz = %b, ccv = %b, ccc = %b", $signed(expected), exn, exz, exv, exc);
		$display("\tObserved: Result = %d, ccn = %b, ccz = %b, ccv = %b, ccc = %b", $signed(result), ccn, ccz, ccv, ccc);
		ErrorsSeen = 1;
		end
endfunction

`ifdef DEBUG
initial
begin
$display("\t\tTime\t x\t y\t sub\t result\t ccn\t ccz\t ccv\t ccc");
$monitor("%t\t %d\t %d\t %b\t %d\t %b\t %b\t %b\t %b",$time,$signed(x),$signed(y),sub,$signed(result),ccn,ccz,ccv,ccc); 
end
`endif

initial 
begin
sub = 1'b0;
if(TEST_N > 8)
	MAX = 2**16 - 1;
else
	MAX = 2**(2*TEST_N) - 1;

for (i = '0; i < MAX; i++)
	begin

	// Exhaustive test portion; add then sub
	{x, y} = i;
	for (j = 0; j < 4; j++) 
		begin
		{signA, signB} = j;
		xKGM = (signA) ? (x * -1) : x;
		yKGM = (signB) ? (y * -1) : y;			
		#10 CheckResults();
		end

	// Also test random vectors if TEST_N > 8
	if (TEST_N > 8)
		begin
		assert(Random.randomize());
		{x, y} = Random.Value;
		for (j = 0; j < 4; j++) 
			begin
			{signA, signB} = j;
			xKGM = (signA) ? (x * -1) : x;
			yKGM = (signB) ? (y * -1) : y;			
			#10 CheckResults();
			end;
		end	
	end

if (ErrorsSeen == 0)
	$display("*** No Errors ***");
end

endmodule
