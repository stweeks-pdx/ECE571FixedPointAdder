module top;

parameter WIDTH = 32;

logic [WIDTH-10:0] In;
logic [$clog2(WIDTH)-1:0] ExpDiff;
logic Shiftright_enable;
logic [WIDTH-10:0] ShiftRight_Out;


BarrelShifter DUT(In, ExpDiff, Shiftright_enable, ShiftRight_Out);

initial
begin

Shiftright_enable = '0;	
//repeat (2)
//begin
	In = '1;
	for (int j = 0; j <= 23; j++)
		begin
		ExpDiff = j;
		#100;
		$display("In = %b Shiftright_enable = %b ExpDiff = %d, Out = %b", In, Shiftright_enable, ExpDiff, ShiftRight_Out);
		end
Shiftright_enable = ~Shiftright_enable;
//end

#10000;
$finish;
end
endmodule
