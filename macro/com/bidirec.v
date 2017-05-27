////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : bidirec.v
// Description  : This macro is a clocked bidirectional pin in Verilog. The value
// of OE determines whether bidir is an input, feeding in inp, or a tri-state,
// driving out the value b.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:19:26 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module bidirec
    (
     clk,
     oe,
     inp,
     outp,
     bidir
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           SIZE = 8;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input [SIZE-1:0]    oe;
input [SIZE-1:0]    inp;
output [SIZE-1:0]   outp;
inout [SIZE-1:0]    bidir;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [SIZE-1:0]      a, b;

genvar n;
generate
    for (n = 0; n < SIZE; n = n + 1)
        begin: tristate
        assign bidir[n] = oe[n] ? a[n] : 1'bz;
        assign outp[n]  = b[n];
        end
endgenerate

integer        i;
always @(posedge clk)
    begin
    for (i = 0; i < SIZE; i = i + 1)
        begin
        b[i] <= bidir[i];
        a[i] <= inp[i];
        end
    end

endmodule 
