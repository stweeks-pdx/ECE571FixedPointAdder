module top;
parameter TEST_N = 25;
parameter TEST_MAX = 25;
localparam DIFF_FROM_32 = 32 - TEST_N;
localparam INDEX_WIDTH = $clog2(TEST_N+DIFF_FROM_32);

/* Macros for CheckResults bitmasks */
localparam TOP16MASK = 32'hFFFF0000;
localparam TOP8MASK  = 32'hFF000000;
localparam TOP4MASK  = 32'hF0000000;
localparam TOP2MASK  = 32'hC0000000;
localparam TOP1MASK  = 32'h80000000;

logic [TEST_N-1:0] testVal;
logic [INDEX_WIDTH-1:0] index;
logic valid;

int unsigned j = 0;
int unsigned max;
int ErrorSeen = 0;

FindFirstOne DUT(testVal, valid, index);

function automatic void CheckResults(input [2**INDEX_WIDTH-1:0] x);
logic [INDEX_WIDTH-1:0] n, i;
logic v = 1'b0;

n = '0;
if (x == 0) i = 0;
else
	begin
	v = 1'b1;

	if ((x & TOP16MASK) == 0)
		begin
		n = n + 16;
		x = x << 16;
		end
	if ((x & TOP8MASK) == 0)
		begin
		n = n + 8;
		x = x << 8;
		end
	if ((x & TOP4MASK) == 0)
		begin
		n = n + 4;
		x = x << 4;
		end
	if ((x & TOP2MASK) == 0)
		begin
		n = n + 2;
		x = x << 2;
		end
	if ((x & TOP1MASK) == 0)
		begin
		n = n + 1;
		x = x << 1;
		end
	i = 2**INDEX_WIDTH - 1 - n;
	end

if (i !== index)
	begin
	$display("ERROR: input = %b_%b_%b_%b_%b_%b_%b_%b\texpected: v = %b n = %b\tobserved: v = %b n = %b",
		 j[31:28], j[27:24], j[23:20], j[19:16], j[15:12], j[11:8], j[7:4], j[3:0], v, i, valid, index);
	ErrorSeen = 1'b1;
	end

endfunction

initial
begin

max = 2**TEST_MAX -1;
for (j = 0; j <= max; j++)
	begin
	testVal = j;
	#100 CheckResults({{DIFF_FROM_32{1'b0}}, testVal});
	if(j%2**20== 0) $display("j = %b", j);
	`ifdef DEBUG
		$display("Input = %b_%b_%b_%b_%b_%b_%b_%b\tObserved: v = %b n = %b",
			 j[31:28], j[27:24], j[23:20], j[19:16], j[15:12], j[11:8], j[7:4], j[3:0], valid, index);
	`endif	
	end

// TODO: Add directed tests for larger values or brute force; walking ones, one-hot, etc.

if (ErrorSeen == 0) $display("*** NO ERRORS ***");
else $display ("*** ERROR SEEN ***");
$stop;

end

endmodule
