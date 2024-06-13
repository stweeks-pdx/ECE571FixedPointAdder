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
	SelMuxR - selector for the rounding mux (used while rounding the 2nd time)
//top module
	Ready - Asserted after rounding and asserted until Go is set high
**************************/


module Control #(
	parameter EXPBITS = 8,
	parameter MANTISSABITS = 23)  
(
	input Go,Clock,Reset,
	//inputs from exponent difference
	input ExpSet,
	input [EXPBITS-1:0] ExpDiff,Diff,
	//inputs from FFO
	input FFOValid,
	input [$clog2(MANTISSABITS)-1:0] FFOIndex,Index,
	// inputs from rounding hardware
	input [MANTISSABITS+1:0] roundedMant,
	//inputs to shift right
	output logic SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable,
	output logic [$clog2(MANTISSABITS*2)-1:0] ShiftRightAmount,
	//inputs to normalize 
	output logic SREn,SLEn,NoShift,
	output logic [$clog2(MANTISSABITS)-1:0] ShiftAmount,
	output logic SelMuxR,
	output logic FlagResult);

	import controlpkg::*;

	StateType State,NextState;
					
	localparam INDEXCARRY = 24;
	localparam INDEXONE = 23;
	localparam NBITS = $clog2(MANTISSABITS);
	logic [NBITS-1:0] MBITSEN = 5'b10111; // MBITSEN = 23;
	
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
				if (roundedMant[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (roundedMant[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = SR;
				end
				
		SL: begin
				if (roundedMant[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (roundedMant[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = SL;			
				end
				
		NOSHIFT: begin
					if (roundedMant[INDEXCARRY]=='0)
						NextState = RESULT;
					else if (roundedMant[INDEXCARRY])
						NextState = ROUND;
					else
						NextState = NOSHIFT;		
				end
				
		ROUND: begin
					if (roundedMant[INDEXCARRY]=='0)
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
		SelMuxR = '0;
		FlagResult = '0;
		
		unique case (State)
		IDLE: begin
				{SelExpMux,SelSRMuxL,SelSRMuxG} = '0;
				{ShiftRightEnable,ShiftRightAmount} = '0;
				{SREn,SLEn,NoShift,ShiftAmount} = '0;
				SelMuxR = '0;
				FlagResult = '0;
			end
		
		DISSR: begin
				SelExpMux = '1; SelSRMuxG = '1;
			end
				
		ENSRGT: begin
				ShiftRightEnable = '1; 
				ShiftRightAmount = Diff > MANTISSABITS ? MBITSEN : Diff;
				SelExpMux = '1; SelSRMuxG = '1;
			end
		
		ENSRLT: begin
				ShiftRightEnable = '1; 
				ShiftRightAmount = Diff > MANTISSABITS ? MBITSEN : Diff;
				SelSRMuxL = '1;
			end
		
		SR: SREn = '1;
				
		SL: begin
			SLEn = '1; 
			ShiftAmount = MBITSEN - Index;
			end
		
		NOSHIFT: NoShift = '1; 
			
		ROUND: begin
				SelMuxR = '1;
				SREn = '1;
				end

		RESULT: FlagResult = '1;
		endcase
	end 
	
endmodule
