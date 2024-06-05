module top;
	parameter EXPBITS = 8;
	parameter MANTISSABITS = 23;
	localparam NBITS = $clog2(MANTISSABITS);
	
	logic Go,Clock,Reset,ExpSet,FFOValid;
	logic [EXPBITS-1:0] ExpDiff; 
	logic [NBITS-1:0] FFOIndex;
	logic RoundUp;
	logic [MANTISSABITS+1:0] Out;
	
	wire SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable;
	wire [NBITS-1:0] ShiftRightAmount,ShiftAmount;
	wire SREn,SLEn,NoShift,IncrEn,DecrEn;
	wire SelExpMuxR,SelManMuxR;
	
	localparam DUTYCYCLE = 10;
	
	Control #(EXPBITS,MANTISSABITS) DUT (Go,Clock,Reset,ExpSet,ExpDiff,FFOValid,FFOIndex,Out,SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable,ShiftRightAmount,SREn,SLEn,NoShift,IncrEn,DecrEn,ShiftAmount,SelExpMuxR, SelManMuxR);
	bind Control ControlAssertions #(EXPBITS,MANTISSABITS) DUTA (Go,Clock,Reset,ExpSet,ExpDiff,FFOValid,FFOIndex,Out,SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable,ShiftRightAmount,SREn,SLEn,NoShift,IncrEn,DecrEn,ShiftAmount,SelExpMuxR,SelManMuxR,State);
	
	task Initiate(input logic ready,set,input logic [EXPBITS-1:0] diff);
		@(negedge Clock)
		Go = ready;
		#(DUTYCYCLE/3);
		ExpSet = set;  ExpDiff = diff;
	endtask
	
	task Normalize(input logic ready,valid,input logic [NBITS-1:0] index);
		@(negedge Clock); 
		Go = ready;
		FFOValid = valid;
		FFOIndex = index;
	endtask
	
	task Rounding(input logic [MANTISSABITS+1:0] out);
		@(negedge Clock);
		Out = out;
	endtask


	initial 
	begin
		Clock = '1;
		forever #DUTYCYCLE Clock = ~Clock;
	end
	
	initial 
	begin
		Reset = '1;
		repeat(2) @(negedge Clock);
		Reset = '0;
		
		//a>b, FFO index = 23,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b10,{MANTISSABITS{1'b0}}});
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a=b, FFO index = 25,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b11001);               
		Rounding({2'b00,{MANTISSABITS{1'b1}}});
		
		//a<b, FFO index = 24,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		repeat(2) @(negedge Clock);	
		
	$finish;
	end
	
	
endmodule




