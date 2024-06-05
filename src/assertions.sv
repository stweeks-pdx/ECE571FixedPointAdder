import controlpkg::*;
module ControlAssertions #(
	parameter EXPBITS = 8,
	parameter MANTISSABITS = 23)  
(	input logic Go,Clock,Reset,ExpSet,
	input logic [EXPBITS-1:0] ExpDiff,
	input logic FFOValid,
	input logic [$clog2(MANTISSABITS)-1:0] FFOIndex,
	input logic [MANTISSABITS+1:0] Out,
	input logic SelExpMux,SelSRMuxL,SelSRMuxG,ShiftRightEnable,
	input logic [$clog2(MANTISSABITS)-1:0] ShiftRightAmount,
	input logic SREn,SLEn,NoShift,IncrEn,DecrEn,
	input logic [$clog2(MANTISSABITS)-1:0] ShiftAmount,
	input logic SelExpMuxR, SelManMuxR,
	input StateType State);  //fsm state
/*
//when reset state = idle
property p_resetstate;
	@(posedge Clock)
	Reset |=> State == IDLE;
endproperty
a_resetstate: assert property(p_resetstate) else $error("on reset state is not IDLE");

//when go =1 nextstate is exp
property p_exponentstate;
	@(posedge Clock)
	Go |=> State == DISSR;
endproperty
a_exponentstate: assert property(p_exponentstate) else $error("on reset state is not IDLE");

*/	
	
//when expmux = rightmux = 1, leftmux = 0 and vice versa
//if expdiff is 0 srenable =0 else 1
//no transition from disSR to engt or enlt and so on

//if sr = 1,sl= 0 and noshift = 0 and so on
//if sr =1 incr = 1
//if sl = 1 decr = 1
//shift amount = 23 -index
	
	
endmodule
