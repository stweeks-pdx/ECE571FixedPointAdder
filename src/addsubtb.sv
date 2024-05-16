module AddSubKGM(result, x, y, ccn, ccz, ccv, ccc, sub);
parameter N = 8;

input [N-1:0] x, y;
output [N-1:0] result;
output ccn, ccz, ccv, ccc;
input sub;

wire [N-1:0] yIn;

// Adding block
assign yIn = (sub) ? ~y : y;
assign {ccc, result} = x + yIn + sub;

// CC signals; other than ccc assigned above
assign ccn = (result[N-1]);
assign ccz = (result == '0);
assign ccv = (x[N-1] & yIn[N-1] & ~result[N-1]
	   | ~x[N-1] & ~yIn[N-1] & result[N-1]);
endmodule



module top;
parameter TEST_N = 8;

logic [TEST_N-1:0] x;
logic [TEST_N-1:0] y;
logic [TEST_N-1:0] result, expected;
logic ccn, ccz, ccv, ccc, exn, exz, exv, exc;
logic sub;

longint unsigned i;
longint unsigned MAX;
int ErrorsSeen = 0;

AddSubKGM  #(.N(TEST_N)) KGM(expected, x, y, exn, exz, exv, exc, sub);
AddSub8Bit #(.N(TEST_N)) DUT(result, x, y, ccn, ccz, ccv, ccc, sub);

class RandVector; // Random input, without replacement, for testing TEST_N > 8
	rand logic [2*TEST_N-1:0] Value; 
endclass

RandVector Random = new;

function automatic void CheckResults();
	if ({result, ccn, ccz, ccv, ccc} !== {expected, exn, exz, exv, exc})
		begin
		$display("ERROR:\n\tInput: (%d) %s (%d)", $signed(x), (sub) ? "-" : "+", $signed(y)); 
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
if(TEST_N > 8)
	MAX = 2**16 - 1;
else
	MAX = 2**(2*TEST_N) - 1;

for (i = '0; i < MAX; i++)
	begin

	// Exhaustive test portion; add then sub
	{x, y} = i;
	sub = 1'b0;
	#10 CheckResults();
	sub = 1'b1;
	#10 CheckResults();
	
	// Also test random vectors if TEST_N > 8
	if (TEST_N > 8)
		begin
		assert(Random.randomize());
		{x, y} = Random.Value;
		sub = 1'b0;
		#10 CheckResults();
		sub = 1'b1;
		#10 CheckResults();
		end	

	end

if (ErrorsSeen == 0)
	$display("*** No Errors ***");
end

endmodule
