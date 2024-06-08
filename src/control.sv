package controlpkg;
typedef enum logic [3:0] {IDLE,DISSR,ENSRGT,ENSRLT,SR,SL,NOSHIFT,ROUND,RESULT} StateType;
endpackage

/**************************
//inputs for the right shifter
	SelExpMux -- selector for the exponent mux
	SelSRMuxL -- selector for right shifter mux 1 (LHS in the pdf)
	SelSRMuxG -- selector for right shifter mux 2 (RHS in the pdf)
	ShiftRightEnable -- enables the right shifter
	ShiftRightAmount -- Amount of bits to be shifted
//inputs to normalizing circuit
	SREn - enables right shifter
	SLEn - enables left shifter
	ShiftAmount - Amount of bits to be shifted in case of left shifter
	NoShift - disable left and right shifter
	IncrEn - increment the exponent
	DecrEn - decrement the exponent
	SelExpMuxR - selector for the exponent mux in case of rounding(rounding the 2nd time) 
	SelManMuxR - selector for the mantissa mux in case of rounding(rounding the 2nd time)
**************************/


module Control #(
	parameter EXPBITS = 8,
	parameter MANTISSABITS = 23)  
(
	input Go,Clock,Reset,
	//inputs from exponent difference
	input ExpSet,
	input [EXPBITS-1:0] ExpDiff,
	//inputs from FFO
	input FFOValid,
	input [$clog2(MANTISSABITS)-1:0] FFOIndex,
	// inputs from rounding hardware
	input [MANTISSABITS+1:0] Out,
	//inputs to shift right
	output logic SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable,
	output logic [$clog2(MANTISSABITS)-1:0] ShiftRightAmount,
	//inputs to normalize 
	output logic SREn,SLEn,NoShift,IncrEn,DecrEn,
	output logic [$clog2(MANTISSABITS)-1:0] ShiftAmount,
	output logic SelExpMuxR, SelManMuxR,
	output logic Result );

	import controlpkg::*;

	//enum {I_POS= 0,D_POS = 1,EGT_POS = 2,ELT_POS = 3,SR_POS = 4, SL_POS = 5, NS_POS = 6}StateBit;
	/*enum logic [6:0] {IDLE = 7'b0000001<<I_POS,
					DISSR  = 7'b0000001<<D_POS,
					ENSRGT = 7'b0000001<<EGT_POS,
					ENSRLT = 7'b0000001<<ELT_POS,
					SR 	   = 7'b0000001<<SR_POS,
					SL     = 7'b0000001<<SL_POS,
					NOSHIFT= 7'b0000001<<NS_POS} State, NextState;*/
	//enum logic [2:0] {IDLE,DISSR,ENSRGT,ENSRLT,SR,SL,NOSHIFT} State, NextState;
	StateType State,NextState;
					
	localparam INDEXCARRY = 24;
	localparam INDEXONE = 23;
	localparam NBITS = $clog2(MANTISSABITS);
	logic [NBITS-1:0] MBITSEN = 5'b10111; // MBITSEN = 23;
	logic FlagResult;

	always_ff @ (posedge Clock)
	begin
		if (Reset)
			Result <= '0;
		else if (FlagResult)
			Result <= '1;
		else if (Go)
			Result <= '0;
	end
	
	always_ff @ (posedge Clock)
	begin
		if (Reset)
			State <= IDLE;
		else
			State <= NextState;
	end
	
	//Next State Logic
	always_comb
	begin
		NextState = State;
		unique case (State)		
		IDLE: begin
				if (ExpDiff == '0 && Go)
					NextState = DISSR;
				else if (ExpSet == '1 && ExpDiff != '0 && Go)
					NextState = ENSRGT;
				else if (ExpSet == '0 && Go)
					NextState = ENSRLT;
				else
					NextState = IDLE;
			end
				
		DISSR: begin
				if (FFOValid && FFOIndex == INDEXCARRY)
					NextState = SR;
				else if ((FFOValid && FFOIndex == INDEXONE) || (!FFOValid))
					NextState = NOSHIFT;
				else if (FFOValid && FFOIndex < INDEXONE)
					NextState = SL;
				else
					NextState = DISSR;
			end
				
		ENSRGT: begin
				if (FFOValid && FFOIndex == INDEXCARRY)
					NextState = SR;
				else if ((FFOValid && FFOIndex == INDEXONE) || (!FFOValid))
					NextState = NOSHIFT;
				else if (FFOValid && FFOIndex < INDEXONE)
					NextState = SL;
				else
					NextState = ENSRGT;
			end
				
		ENSRLT: begin
				if (FFOValid && FFOIndex == INDEXCARRY)
					NextState = SR;
				else if ((FFOValid && FFOIndex == INDEXONE) || (!FFOValid))
					NextState = NOSHIFT;
				else if (FFOValid && FFOIndex < INDEXONE)
					NextState = SL;
				else
					NextState = ENSRLT;
				end
				
		SR: begin
				if (Out[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (Out[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = SR;
				end
				
		SL: begin
				if (Out[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (Out[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = SL;			
				end
				
		NOSHIFT: begin
					if (Out[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (Out[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = NOSHIFT;		
				end
				
		ROUND: begin
					if (Out[INDEXCARRY]=='0)
						NextState = RESULT;
					else
						NextState = ROUND;
				end
		RESULT:begin
			NextState = IDLE;
			end
		endcase
	end
	
	//output logic
	always_comb
	begin
		{SelExpMux,SelSRMuxL,SelSRMuxG} = '0;
		{ShiftRightEnable,ShiftRightAmount} = '0;
		{SREn,SLEn,NoShift,ShiftAmount} = '0;
		{IncrEn,DecrEn} = '0;
		{SelExpMuxR,SelManMuxR} = '0;
		FlagResult = '0;
		
		unique case (State)
		IDLE: begin
				{SelExpMux,SelSRMuxL,SelSRMuxG} = '0;
				{ShiftRightEnable,ShiftRightAmount} = '0;
				{SREn,SLEn,NoShift,ShiftAmount} = '0;
				{IncrEn,DecrEn} = '0;
				{SelExpMuxR,SelManMuxR} = '0;
			end
		
		DISSR: begin
				SelExpMux = '1; SelSRMuxG = '1;
			end
				
		ENSRGT: begin
				ShiftRightEnable = '1; 
				ShiftRightAmount = ExpDiff > MANTISSABITS ? MBITSEN : ExpDiff;
				SelExpMux = '1; SelSRMuxG = '1;
			end
		
		ENSRLT: begin
				ShiftRightEnable = '1; 
				ShiftRightAmount = ExpDiff > MANTISSABITS ? MBITSEN : ExpDiff;
				SelSRMuxL = '1;
			end
		
		SR: begin
			SREn = '1; IncrEn = '1; 
			end
		
		SL: begin
			SLEn = '1; DecrEn = '1;
			ShiftAmount = MBITSEN - FFOIndex;
			end
		
		NOSHIFT: NoShift = '1; 
			
		ROUND: begin
				SelExpMuxR = '1; SelManMuxR = '1;
				SREn = '1; IncrEn = '1; 
				end
		RESULT: FlagResult = '1;
		endcase
	end 
	
endmodule