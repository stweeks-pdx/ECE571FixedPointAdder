// BarrelShifter Module
module BarrelShifter(In, ShiftAmount, ShiftIn, Out);
parameter N = 32;
localparam nSel = $clog2(N);
input [N-1:0] In;
input [nSel-1:0] ShiftAmount;
input ShiftIn;
output [N-1:0] Out;

genvar i;
// mux out needs to be one bit higher than needed select bits
wire [N-1:0] muxOut [nSel:0];
assign muxOut[nSel] = In;

// (N-1) - ((1 << i)/2) will always give you the top of the lower bits that are going to be shifted up.
generate
    for(i = nSel; i > 0; i = i - 1)
    begin:MUX
      mux2to1 #(N) mux (.sel(ShiftAmount[i-1]), 
                      .in1({muxOut[i][(N-1) - ((1 << i)/2):0], {((1 << i)/2){ShiftIn}}}), 
                      .in0(muxOut[i]), 
                      .y(muxOut[i-1]));
    end
endgenerate

assign Out = muxOut[0];

endmodule


// 2:1 Mux Module
module mux2to1(sel, in1, in0, y);
parameter N = 32;
input sel;
input [N-1:0] in1, in0;
output [N-1:0] y;

assign y = sel ? in1 : in0;

endmodule
