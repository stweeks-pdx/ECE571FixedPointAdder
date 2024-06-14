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
logic [22:0] stickyBits;
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
// Inputs: exponent from AddendA
//         exponent from AddendB
//
// Outputs: exponent difference to Control
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
// Inputs: exponent from AddendA
//         exponent from AddendB
//         expSelect from Control
//
// Outputs: value of larger exponent to ExpIncrement MUX
assign smallExp = (~SelExpMux)? R0.ExpA : R0.ExpB;
assign largeExp = (SelExpMux) ? R0.ExpA : R0.ExpB;

// *** Small Mantissa MUX
// Inputs: mantissa from AddendA
//         mantissa from AddendB 
//         mantSelect from Control
//
// Outputs: smaller mantissa to Pre-add Shifter
assign smallMant = (SelSRMuxL) ? {1'b1, R0.MantA} : {1'b1, R0.MantB}; // Appending implied 1 to small mantissa
assign smallSign = (SelSRMuxL) ? R0.SignA : R0.SignB;

// *** Large Mantissa MUX
// Inputs: mantissa from AddendA
//         mantissa from AddendB 
//         ~mantSelect from Control
//
// Outputs: larger mantissa to Big ALU
assign largeMant = (SelSRMuxG) ? {1'b1, R0.MantA} : {1'b1, R0.MantB}; // Appending implied 1 to large mantissa
assign largeSign = (SelSRMuxG) ? R0.SignA : R0.SignB;


// *** Pre-add Shifter
// Inputs: smaller mantissa from MUX
//         pre-add shift amount from Control
//
// Outputs: shifted mantissa to Big ALU
RightShifter #(48) shiftPreALU(.In({smallMant, 24'h0}), .ShiftRightEnable, .ShiftRightAmount, .Out({smallMantShifted, roundBit, stickyBits}));

// *** Zero checking before ALU
assign smallSignToALU = (smallExp != 0 && smallMantShifted != 0) ? smallSign : '0;
assign smallMantToALU = (smallExp != 0) ? smallMantShifted : '0;

assign largeSignToALU = (largeExp != 0) ? largeSign : '0;
assign largeMantToALU = (largeExp != 0) ? largeMant : '0;

// *** Big ALU
// Inputs: shifted mantissa from Pre-add Shifter
//         larger mantissa from Large Mantissa MUX
//         add/sub signal from Control
//
// Outputs: mantissa sum to Control             ## Specifically FindFirstOne module I'm guessing
//          mantissa sum to SumShift Mux         
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
// Inputs: mantissa sum from Big ALU
//         rounded mantissa from Rounding Hardware
//         sumShiftSelect from Control
//
// Outputs: un-normalized mantissa to Normalizing Shifter
assign signToNorm  = (SelMuxR) ? R1.postNormSign : R1.preNormSign;
assign mantToNorm  = (SelMuxR) ? R1.postNormMant : R1.preNormMant;

// *** ExpIncrement MUX
// Inputs: larger exponent from Exponent MUX
//         rounded exponent from Rounding Hardware  
//         expIncrSelect from Control
//
// Outputs: pre-incremented/decremented exponent to ExpIncrDecr
assign expToNorm = (SelMuxR) ? R1.postNormExp : R1.preNormExp;


// *** Normalizer circuit includes:
//   * ExpIncrDecrement
// Inputs: pre-incr/decr exponent from ExpIncrement MUX
//         incr/dec amount from Control
//
// Outputs: pre-rounded exponent to Rounding hardware
//   * Normalizing Shifter
// Inputs: un-normalized mantissa from SumShift MUX
//         norm shift value from Control
//         norm shift direction from Control
//
// Outputs: shifted mantissa to Rounding Hardware
//          sign bit to Result.sign
Normalizer mantNormalizer(mantToNorm, expToNorm, SREn, SLEn, ShiftAmount, postNormExp, mantToRound);


// *** Rounding Hardware
// Inputs: shifted mantissa from Normalizing Shifter
//         pre-rounded exponent from ExpIncrDecr
//         roudingSignal from Control
//
// Outputs: rounded exponent to ExpIncrement MUX
//          rounded exponent to Result.exponent
//          rounded mantissa to SumShift MUX
//          rounded mantissa to Control
//          rounded mantissa to Result.mantissa
assign {shiftRound, shiftSticky} = (SREn) ? {mantToNorm[0], R1.preNormRound|R1.preNormSticky} : 2'b0;
assign {round, sticky} = (NoShift) ? {R1.preNormRound, R1.preNormSticky} : {shiftRound, shiftSticky};
RoundNearestEven RoundingHardware(roundedMant, mantToRound, round, sticky);


// *** Control module
// Inputs: exponent difference from Small ALU
//         mantissa sum from Big ALU
//         rounded mantissa from Rounding Hardware
//
// Outputs: expSelect to Exponent MUX
//          mantSelect to Small Mantissa MUX
//          ~mantSelect to Large Mantissa MUX
//          pre-add shift to Pre-add Shifter
//          add/sub signal to Big ALU
//          sumShiftSelect to SumShift MUX
//          norm shift value to Normalizing Shifter
//          norm shift direction to Normalizing Shifter
//          expIncrSelect to ExpIncrement MUX
//          incr/dec amount to ExpIncrDecrement
//          roundingSignal to Rounding Hardware
// TODO: Insert Anvitha's ControlFSM
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

assign Result = (FlagResult) ? '{R2.Sign, R2.Exp, R2.Mant} : Result;
assign Inf = (FlagResult) ? (R2.Exp == 255) : Inf; 


// *** Result latch
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
