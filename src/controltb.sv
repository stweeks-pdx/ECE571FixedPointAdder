module top;
	parameter EXPBITS = 8;
	parameter MANTISSABITS = 23;
	localparam NBITS = $clog2(MANTISSABITS);
	localparam NBITSE = $clog2(MANTISSABITS*2);
	
	logic Go,Clock,Reset,ExpSet,FFOValid;
	logic [EXPBITS-1:0] ExpDiff,Diff;
	logic [NBITS-1:0] FFOIndex,Index;
	logic [MANTISSABITS+1:0] roundedMant;
	
	wire SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable;
	wire [NBITSE-1:0] ShiftRightAmount;
	wire [NBITS-1:0] ShiftAmount;
	wire SREn,SLEn,NoShift;
	wire SelMuxR,FlagResult;
	
	localparam DUTYCYCLE = 10;
	
	Control #(EXPBITS,MANTISSABITS) DUT (.*);
	bind Control ControlAssertions #(EXPBITS,MANTISSABITS) DUTA (.*);
	
	task Initiate(input logic ready,set,input logic [EXPBITS-1:0] diff);
		@(negedge Clock)
		Go = ready;
		#(DUTYCYCLE/3);
		ExpSet = set;  ExpDiff = diff; Diff = diff;
	endtask
	
	task Normalize(input logic ready,valid,input logic [NBITS-1:0] index);
		@(negedge Clock); 
		Go = ready;
		FFOValid = valid;
		FFOIndex = index; Index = index;
	endtask
	
	task Rounding(input logic [MANTISSABITS+1:0] roundedmant);
		@(negedge Clock);
		roundedMant = roundedmant;
		@(negedge Clock);
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
		repeat (4) @ (negedge Clock);

		//a=b, FFO index = 24,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b00,{MANTISSABITS{1'b1}}});
		repeat (4) @ (negedge Clock);
		
		//a<b, FFO index = 22,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10110);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//equal without additional rounding
		//a=b, FFO index = 23,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b00,{MANTISSABITS{1'b1}}});
		
		//a=b, FFOValid=0, FFO index = 23,noround 
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'0,5'b10111);               
		Rounding({2'b00,{MANTISSABITS{1'b0}}});
		repeat (3) @ (negedge Clock);
		
		//a=b, FFO index = 21,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b10101);               
		Rounding({2'b00,{MANTISSABITS{1'b1}}});
		
		//equal with additional rounding
		//a=b, FFO index = 23,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//a=b, FFOValid=0, FFO index = 23,noround 
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'0,5'b10111);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		repeat (3) @ (negedge Clock);

		
		//a=b, FFO index = 21,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b10101);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//a=b, FFO index = 24,noround
		Initiate('1,'1,{EXPBITS/2{2'b00}});
		Normalize('0,'1,5'b11000);  
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b00,{MANTISSABITS{1'b1}}});
		
		//greater than with additional rounding
		//a>b, FFO index = 24,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b10,{MANTISSABITS{1'b0}}});
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a>b, FFO index = 23,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'0,5'b10111);               
		Rounding({2'b10,{MANTISSABITS{1'b0}}});
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a>b, FFO index = 20,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10100);               
		Rounding({2'b10,{MANTISSABITS{1'b0}}});
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//greater than without additional rounding
		//a>b, FFO index = 23,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a>b, FFO index = 24,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a>b, FFO index = 23,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'0,5'b10111);               
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//a>b, FFO index = 20,round
		Initiate('1,'1,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10100);               
		Rounding({2'b01,{MANTISSABITS{1'b0}}});
		
		//less than with additional rounding
		//a<b, FFO index = 23,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b11,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		repeat (3) @ (negedge Clock);
	
		//a<b, FFO index = 24,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'0,5'b11000);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//a<b, FFO index = 24,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b10,{MANTISSABITS{1'b1}}});
		Rounding({2'b11,{MANTISSABITS{1'b1}}});
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//less than with no additional rounding
		//a<b, FFO index = 23,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10111);               
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//a<b, FFO index = 24,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'0,5'b11000);               
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		repeat (3) @ (negedge Clock);
		
		//a<b, FFO index = 24,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b11000);               
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//a<b, FFO index = 22,round
		Initiate('1,'0,{EXPBITS/2{2'b01}});
		Normalize('0,'1,5'b10110);               
		Rounding({2'b01,{MANTISSABITS{1'b1}}});
		
		//Finish
		Initiate('0,'0,{EXPBITS/2{2'b00}});
	
		repeat(2) @(negedge Clock);	
		
	$finish;
	end
	
	
endmodule




