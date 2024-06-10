import floatingpointpkg::*;

module FloatingPointAdder(input float AddendA,
                          input float AddendB,
                          input logic Go,
                          input logic Clock,
                          input logic Reset,
                          output float Result,
                          output logic Zero, 
                          output logic Inf,
                          output logic Nan);
parameter VERSION = "0.3";

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
        logic [7:0] ExpA, ExpB;
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
        end


// *** Exponent MUX
// Inputs: exponent from AddendA
//         exponent from AddendB
//         expSelect from Control
//
// Outputs: value of larger exponent to ExpIncrement MUX
assign preNormExp = (SelExpMux) ? R0.ExpA : R0.ExpB;

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
RightShifter #(48) shiftPreALU({smallMant, 24'h0}, ShiftRightEnable, ShiftRightAmount, {smallMantShifted, roundBit, stickyBits});
//      TODO: Add enable to Shift Right module or add Akhila Shift Right module 

// *** Big ALU
// Inputs: shifted mantissa from Pre-add Shifter
//         larger mantissa from Large Mantissa MUX
//         add/sub signal from Control
//
// Outputs: mantissa sum to Control             ## Specifically FindFirstOne module I'm guessing
//          mantissa sum to SumShift Mux         
bigalu BigALU(smallMantShifted, largeMant, smallSign, largeSign, mantSum, ccc, ccz, ccv, ccn);

// *** Find First One
// Needs to be placed before second set of registers so that result is visible to Control FSM
FindFirstOne MantissaFFO({ccc, mantSum}, .FFOIndex, .FFOValid); // FFO on 25 bit mantissa sum


// *** Register1
// Second set of Registers for RTL design
// samples values before mux selection to keep lockstep with FSM
struct packed {
        logic preNormSign, postNormSign;
        logic [7:0] preNormExp, postNormExp;
        logic [24:0] preNormMant, postNormMant;
        logic preNormRound, preNormSticky;
} R1; 

always_ff @(posedge Clock) 
        begin
        R1.preNormSign  <= ccn;
        R1.postNormSign <= R1.preNormSign;

        R1.preNormExp  <= preNormExp;
        R1.postNormExp <= postNormExp;
        
        R1.preNormMant  <= mantSum;
        R1.postNormMant <= roundedMant;
        
        R1.preNormRound  <= roundBit;
        R1.preNormSticky <= |stickyBits;
        // PostNorm Round and Sticky not needed due to feedback being no-round case
        end


// *** SumShift MUX                             
// Inputs: mantissa sum from Big ALU
//         rounded mantissa from Rounding Hardware
//         sumShiftSelect from Control
//
// Outputs: un-normalized mantissa to Normalizing Shifter
assign signToNorm  = (SelManMuxR) ? R1.postNormSign : R1.preNormSign;
assign mantToNorm  = (SelManMuxR) ? R1.postNormMant : R1.preNormMant;

// *** ExpIncrement MUX
// Inputs: larger exponent from Exponent MUX
//         rounded exponent from Rounding Hardware  
//         expIncrSelect from Control
//
// Outputs: pre-incremented/decremented exponent to ExpIncrDecr
assign expToNorm = (SelExpMuxR) R1.postNormExp : R1.preNormExp;


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
Normalizer mantNormalizer(mantToNorm, expToNorm, SREn, postNormExp, mantToRound, FFOIndex, FFOValid);
//      TODO: Modify Normalizer circuit to match FSM signals; remove FFO; update port list

assign {shiftRound, shiftSticky} = (SREn) ? {mantToNorm[0], R1.preNormRound|R1.preNormSticky} : 2'b0;

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
                   .ExpSet, .ExpDiff,                        // Signals from expALU
                   .FFOValid, .FFOIndex,                     // Signals from FFO
                   .roundedMant,                             // Result from rounding hardware
                   .SelExpMux, .SelSRMuxL, .SelSRMuxG,       // R0 Mux select signals
                   .ShiftRightEnable, .ShiftRightAmount,     // Right shifter values
                   .SREn, .SLEn, .NoShift, .IncrEn, .DecrEn  // Normalizer control signals
                   .ShiftAmount                              // Left shifter value
                   .SelExpMuxR, SelManMuxR,                  // R1 Mux select signals
                   .ResultReady);                            // Result ready flag

// *** Result latch
//      TODO: Someone please check my implementation here
always_ff @(posedge ResultReady) Result = {signToNorm, postNormExp, roundedMant[22:0]};
                
endmodule
