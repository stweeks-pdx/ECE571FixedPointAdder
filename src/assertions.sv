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

//when reset state = idle
property p_resetstate;
	@(posedge Clock) disable iff (Reset)
	Reset |=> State === IDLE;
endproperty
a_resetstate: assert property(p_resetstate) else $error("on reset state is not IDLE");

property p_stransitiondissr;
	@(posedge Clock) disable iff (Reset)
	(State === DISSR) |=> (State !== ENSRGT)or(State !== ENSRLT);
endproperty
a_stransitiondissr: assert property(p_stransitiondissr) else $error("State transitions from DISSR to ENSRGT or ENSRLT");

property p_stransitionensrgt;
	@(posedge Clock) disable iff (Reset)
	(State === ENSRGT) |=> (State !== DISSR)or(State !== ENSRLT);
endproperty
a_stransitionensrgt: assert property(p_stransitionensrgt) else $error("State transitions from ENSRGT to DISSR or ENSRLT");

property p_stransitionensrlt;
	@(posedge Clock) disable iff (Reset)
	(State === ENSRLT) |=> (State !== DISSR)or(State !== ENSRGT);
endproperty
a_stransitionensrlt: assert property(p_stransitionensrlt) else $error("State transitions from ENSRLT to DISSR or ENSRGT");

property p_stransitionsr;
	@(posedge Clock) disable iff (Reset)
	(State === SR) |=> (State !== SL)or(State !== NOSHIFT);
endproperty
a_stransitionsr: assert property(p_stransitionsr) else $error("State transitions from SR to SL or NOSHIFT");

property p_stransitionsl;
	@(posedge Clock) disable iff (Reset)
	(State === SL) |=> (State !== SR)or(State !== NOSHIFT);
endproperty
a_stransitionsl: assert property(p_stransitionsl) else $error("State transitions from SL to SR or NOSHIFT");

property p_stransitionnoshift;
	@(posedge Clock) disable iff (Reset)
	(State === NOSHIFT) |=> (State !== SL)or(State !== SR);
endproperty
a_stransitionnoshift: assert property(p_stransitionnoshift) else $error("State transitions from NOSHIFT to SR or SL");	

//when expmux = rightmux = 1, leftmux = 0 and vice versa
property p_expgmux;
	@(posedge Clock) disable iff (Reset)
	(SelExpMux && SelSRMuxG) |-> (SelSRMuxL == '0);
endproperty
a_expgmux: assert property(p_expgmux) else $error("SelSRMuxL is not zero when SelExpMux & SelSRMuxG is set");	

property p_explmux;
	@(posedge Clock) disable iff (Reset)
	SelSRMuxL |-> !(SelExpMux && SelSRMuxG);
endproperty
a_explmux: assert property(p_explmux) else $error("SelExpMux & SelSRMux is not zero when SelSRMuxL is set");	

//if expdiff is 0 srenable =0 else 1
property p_expdiffz;
	@(posedge Clock) disable iff (Reset)
	(ExpDiff == '0) |=> ((ShiftRightEnable == '0) && (ShiftRightAmount == '0));
endproperty
a_expdiffz: assert property(p_expdiffz) else $error("SR enable and SR amount is not zero when ExpDiff is zero");	

property p_expdiffnz;
	@(posedge Clock) disable iff (Reset)
	(State == IDLE && ExpDiff != '0) |=> (ShiftRightEnable && (ShiftRightAmount == 5'b10111 || ShiftRightAmount == ExpDiff)) ##1 !(ShiftRightEnable && (ShiftRightAmount == 5'b10111 || ShiftRightAmount == ExpDiff));
endproperty
a_expdiffnz: assert property(p_expdiffnz) else $error("SR enable and SR amount is not set when ExpDiff is not zero");	

//SelExpMux & SelSRMuxG is set when ExpSet is set and vice versa
property p_expset;
	@(posedge Clock) disable iff (Reset)
	(State == IDLE && ExpSet) |=> (SelExpMux && SelSRMuxG);
endproperty
a_expset: assert property(p_expset) else $error("SelExpMux & SelSRMuxG is not set when ExpSet is set");

property p_expsetz;
	@(posedge Clock) disable iff (Reset)
	(State == IDLE && !ExpSet) |=> !(SelExpMux && SelSRMuxG);
endproperty
a_expsetz: assert property(p_expsetz) else $error("SelExpMux & SelSRMuxG is set when ExpSet is not set");

//if sr = 1,sl= 0 and noshift = 0 and so on
property p_sren;
	@(posedge Clock) disable iff (Reset)
	SREn |-> !SLEn && !NoShift;
endproperty
a_sren: assert property(p_sren) else $error("when SREn is set SLEn and NoShift are also set");

property p_slen;
	@(posedge Clock) disable iff (Reset)
	SLEn |-> !SREn && !NoShift;
endproperty
a_slen: assert property(p_slen) else $error("when SLEn is set SREn and NoShift are also set");

property p_noshift;
	@(posedge Clock) disable iff (Reset)
	NoShift |-> !SLEn && !SREn;
endproperty
a_noshift: assert property(p_noshift) else $error("when NoShift is set SLEn and SREn are also set");

//if sr =1 incr = 1
property p_srenincr;
	@(posedge Clock) disable iff (Reset)
	SREn |-> IncrEn && !DecrEn && ShiftAmount == 0 ;
endproperty
a_srenincr: assert property(p_srenincr) else $error("When SREn is set only IncrEn is set");
               
//if sl = 1 decr = 1
property p_slendecr;
	@(posedge Clock) disable iff (Reset)
	SLEn |-> DecrEn && !IncrEn && ShiftAmount == MANTISSABITS - FFOIndex;
endproperty
a_slendecr: assert property(p_slendecr) else $error("When SLEn is set only DecrEn and ShiftAmount are set");

property p_noshiftsincrr;
	@(posedge Clock) disable iff (Reset)
	NoShift |-> !IncrEn && !DecrEn && ShiftAmount == 0;
endproperty
a_noshiftsincrr: assert property(p_noshiftsincrr) else $error("When NoShift is set IncrEn and DecrEn are not reset");

//FFOValid
property p_ffovalidshifter;
	@(posedge Clock) disable iff (Reset)
	FFOValid && (State == DISSR || State == ENSRGT || State == ENSRLT) |=> SREn || SLEn || NoShift;
endproperty
a_ffovalidshifter: assert property(p_ffovalidshifter) else $error("When FFOValid is set either SREn,SLEn or NoShift is not set");

property p_ffovalidreset;
	@(posedge Clock) disable iff (Reset)
	!FFOValid && (State == DISSR || State == ENSRGT || State == ENSRLT) |=> NoShift;
endproperty
a_ffovalidreset: assert property(p_ffovalidreset) else $error("When FFOValid is reset, NoShift is set");

property p_ffovalidmuxsel;
	@(posedge Clock) disable iff (Reset)
	(FFOValid || !FFOValid)&& (State == DISSR || State == ENSRGT || State == ENSRLT)  |=> !SelExpMuxR && !SelManMuxR;
endproperty
a_ffovalidmuxsel: assert property(p_ffovalidmuxsel) else $error("When FFOValid is reset or set, SelExpMuxR and SelManMuxR are set");

property p_normuxsel;
	@(posedge Clock) disable iff (Reset)
	!SelExpMuxR && !SelManMuxR && Out[24] |=> (SelExpMuxR && SelManMuxR)[*1:$] ##1 !Out[24];
endproperty
a_normuxsel: assert property(p_normuxsel) else $error("SelExpMuxR and SelManMuxR are not set during rounding"); 
	
endmodule
