import floatingpointpkg::*;

module FloatingPointAdder(AddendA, AddendB, Go, Clock, Reset, Result, Ready, Zero, Inf, Nan);
parameter VERSION = "0.3";

input float AddendA;
input float AddendB;
input logic Go;
input logic Clock;
input logic Reset;
output float Result;
output logic Ready;
output logic Zero;
output logic Inf;
output logic Nan;

logic ExpSet;
logic smallSign, largeSign, smallSignToALU, largeSignToALU, signToNorm;
logic [7:0] ExpDiff, smallExp, largeExp, preNormExp, postNormExp, expToNorm;
logic [23:0] smallMant, largeMant, smallMantShifted, smallMantToALU, largeMantToALU, mantSum;
logic [22:0] stickyBits, resultMant;
logic roundBit, shiftRound, shiftSticky, round, sticky;
logic [24:0] mantToNorm, mantToRound, roundedMant; 
logic ccc, ccz, ccv, ccn;
logic SelExpMux, SelSRMuxL, SelSRMuxG, SelMuxR, SREn, SLEn, NoShift;
logic [4:0] FFOIndex, ShiftAmount;
logic FFOValid;
logic [5:0] ShiftRightAmount;
logic ShiftRightEnable;
logic FlagResult;

// *** Small ALU
ExpALU expALU(AddendA.exp, AddendB.exp, ExpSet, ExpDiff);


// *** Register0
// First set of Registers for RTL design
// samples values before mux selection to keep lockstep with FSM
struct packed {
        logic SignA, SignB;
        logic [7:0] ExpA, ExpB, ExpDiff;
        logic [22:0] MantA, MantB;
} R0; 

always_ff @(posedge Clock) 
        begin
        R0.SignA <= AddendA.sign;
        R0.ExpA  <= AddendA.exp;
        R0.MantA <= AddendA.frac;

        R0.SignB <= AddendB.sign;
        R0.ExpB  <= AddendB.exp;
        R0.MantB <= AddendB.frac;
        
	R0.ExpDiff <= ExpDiff;
`ifdef DEBUG
	$strobe ("R0: %p", R0);
`endif
	end


// *** Exponent MUX
assign smallExp = (~SelExpMux)? R0.ExpA : R0.ExpB;
assign largeExp = (SelExpMux) ? R0.ExpA : R0.ExpB;

// *** Small Mantissa MUX
assign smallMant = (SelSRMuxL) ? {1'b1, R0.MantA} : {1'b1, R0.MantB}; // Appending implied 1 to small mantissa
assign smallSign = (SelSRMuxL) ? R0.SignA : R0.SignB;

// *** Large Mantissa MUX
assign largeMant = (SelSRMuxG) ? {1'b1, R0.MantA} : {1'b1, R0.MantB}; // Appending implied 1 to large mantissa
assign largeSign = (SelSRMuxG) ? R0.SignA : R0.SignB;


// *** Pre-add Shifter
RightShifter #(48) shiftPreALU(.In({smallMant, 24'h0}), .ShiftRightEnable, .ShiftRightAmount, .Out({smallMantShifted, roundBit, stickyBits}));

// *** Zero checking before ALU
assign smallSignToALU = (smallExp != 0 && smallMantShifted != 0) ? smallSign : '0;
assign smallMantToALU = (smallExp != 0) ? smallMantShifted : '0;

assign largeSignToALU = (largeExp != 0) ? largeSign : '0;
assign largeMantToALU = (largeExp != 0) ? largeMant : '0;

// *** Big ALU
bigalu BigALU(smallMantToALU, largeMantToALU, smallSignToALU, largeSignToALU, mantSum, ccc, ccz, ccv, ccn);

// *** Zero Case MUX
assign preNormExp = (ccz) ? '0 : largeExp;

// *** Find First One
// Needs to be placed before second set of registers so that result is visible to Control FSM
FindFirstOne MantissaFFO(.word({ccc, mantSum}), .index(FFOIndex), .valid(FFOValid)); // FFO on 25 bit mantissa sum


// *** Register1
// Second set of Registers for RTL design
// samples values before mux selection to keep lockstep with FSM
struct packed {
        logic preNormSign, postNormSign;
        logic [7:0] preNormExp, postNormExp;
        logic [24:0] preNormMant, postNormMant;
        logic preNormRound, preNormSticky;
	logic [4:0] Index;
} R1; 

always_ff @(posedge Clock) 
        begin
        R1.preNormSign  <= ccn;
        R1.postNormSign <= R1.preNormSign;

        R1.preNormExp  <= preNormExp;
        R1.postNormExp <= postNormExp;
        
        R1.preNormMant  <= {ccc, mantSum};
        R1.postNormMant <= roundedMant;
        
	R1.Index	 <= FFOIndex;
        R1.preNormRound  <= roundBit;
        R1.preNormSticky <= |stickyBits;
        // Index, PostNorm Round and Sticky not needed due to feedback being no-round case
`ifdef DEBUG
	$strobe ("R1: %p", R1);
`endif
        end


// *** SumShift MUX                             
assign signToNorm  = (SelMuxR) ? R1.postNormSign : R1.preNormSign;
assign mantToNorm  = (SelMuxR) ? R1.postNormMant : R1.preNormMant;

// *** ExpIncrement MUX
assign expToNorm = (SelMuxR) ? R1.postNormExp : R1.preNormExp;


// *** Normalizer circuit includes:
//   * Normalizing Shifter
//   * Exponent Increment/Decrement
Normalizer mantNormalizer(mantToNorm, expToNorm, SREn, SLEn, ShiftAmount, postNormExp, mantToRound);


// *** Rounding Hardware
// Two muxes change the round and sticky bit based on shift direction
assign {shiftRound, shiftSticky} = (SREn) ? {mantToNorm[0], R1.preNormRound|R1.preNormSticky} : 2'b0;
assign {round, sticky} = (NoShift) ? {R1.preNormRound, R1.preNormSticky} : {shiftRound, shiftSticky};
RoundNearestEven RoundingHardware(roundedMant, mantToRound, round, sticky);


// *** Control module
Control controlFSM(.Go, .Clock, .Reset,                      // Control base signals
                   .ExpSet, .ExpDiff, .Diff(R0.ExpDiff),     // Signals from expALU
                   .FFOValid, .FFOIndex, .Index(R1.Index),   // Signals from FFO
                   .roundedMant,                             // Result from rounding hardware
                   .SelExpMux, .SelSRMuxL, .SelSRMuxG,       // R0 Mux select signals
                   .ShiftRightEnable, .ShiftRightAmount,     // Right shifter values
                   .SREn, .SLEn, .NoShift,		     // Normalizer control signals
                   .ShiftAmount,                             // Left shifter value
                   .SelMuxR, 		                     // R1 Mux select signal
                   .FlagResult);                            // Result ready flag

// *** Result Register R2
// First set of Registers for RTL design
// samples values before mux selection to keep lockstep with FSM
struct packed {
        logic Sign;
        logic [7:0] Exp;
        logic [22:0] Mant;
} R2; 

always_ff @(posedge Clock) 
        begin
        R2.Sign <= (roundedMant[24]) ? R2.Sign : signToNorm;
        R2.Exp  <= (roundedMant[24]) ? R2.Exp  : postNormExp;
        R2.Mant <= (roundedMant[24]) ? R2.Mant : roundedMant[22:0];
`ifdef DEBUG
	$strobe ("R2: %p", R2);
`endif
	end


// *** Result latches and flag assignments
assign resultMant = (R2.Exp == 255) ? '0 : R2.Mant;	// Sets mantissa to 0 in case of inf exponent
assign Result = (FlagResult) ? '{R2.Sign, R2.Exp, resultMant} : Result;
assign Inf = (FlagResult) ? (R2.Exp == 255) : Inf; 
assign Nan = (FlagResult) ? Inf : Nan;	// Currently no way to distinguish, so flag both if exp is 255.
assign Zero = (FlagResult) ? (R2.Exp == 0) : Zero;

always_ff @ (posedge Clock)
	begin
		if (Reset) begin
			Ready <= '0;
			end
		else if (FlagResult) begin
			Ready <= '1;
			end
		else if (Go) begin
			Ready <= '0;
			end
		else begin
			Ready <= Ready;
                end
end
endmodule
