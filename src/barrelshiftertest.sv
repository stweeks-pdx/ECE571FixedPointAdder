module top;

parameter WIDTH = 32;

reg Error;


reg [WIDTH-1:0] In;
reg [$clog2(WIDTH)-1:0] ShiftAmount;
reg ShiftIn;
wire [WIDTH-1:0] Out;

reg [2*WIDTH-1:0] Temp;
reg [WIDTH-1:0] Expected;

int N;


BarrelShifter #(WIDTH) BS (In, ShiftAmount, ShiftIn, Out);


initial
begin
assert ($countones(WIDTH) == 1) else $fatal(0, "WIDTH must be power of 2");		

`ifdef DEBUG
$display("WIDTH = %d", WIDTH);
$display("In		ShiftAmount	ShiftIn");
$monitor("%b		%d	%b", In, ShiftAmount, ShiftIn);
`endif

Error = 0;
	
// exhaustive test for "reasonable" size
if (WIDTH <= 16)
	N = WIDTH;
else
	N = 16;
	
ShiftIn = 0;
repeat(2)
	begin
	for (int i = 0; i < N; i = i + 1)
		begin
		ShiftAmount = i;
		for (int j = 0 ; j < 2**N; j = j + 1)
			begin
			In = j;
			#100;
			end
		end
	ShiftIn = ~ShiftIn;
	end


// if exhaustive isn't practical use some good directed tests
if (WIDTH > 16)
	begin
	In = '1;	// could use {WIDTH{1'b1}}
	ShiftIn = 0;
	repeat(2)
		begin
		repeat(2)
			begin
			for (int i = 0; i < WIDTH; i = i + 1)
			  begin
			  ShiftAmount = i;
			  #100;
			  end
			In = ~In;
			end
		ShiftIn = ~ShiftIn;		
		end
	end
	

if (Error)
  $display("*** FAILED ***");
else
  $display("*** OK ***");
$finish();
end


always @(In, ShiftAmount, ShiftIn)
begin

#(50) 

Temp = {In, {WIDTH{ShiftIn}}};
Expected = Temp[2*WIDTH-1-ShiftAmount -: WIDTH];

if (Out !== Expected)
  begin
  $display("*** Failed testcase:   In = %b, ShiftAmount = %d, ShiftIn = %b Expected = %b, Out = %b",In,ShiftAmount,ShiftIn,Expected,Out);
  Error = 1;
  end
end

endmodule

