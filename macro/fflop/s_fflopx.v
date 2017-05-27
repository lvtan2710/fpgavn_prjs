////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : s_fflopx.v
// Description  : This module is synchronous flip-flop for a signal or a bus.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:28:06 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module s_fflopx
    (
     clk,
     rst_n,
     d,
     q
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           SIZE = 8;
parameter           RST_VAL = {SIZE{1'b0}};

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [SIZE-1:0]    d;
output [SIZE-1:0]   q;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [SIZE-1:0]      q;

always @(posedge clk)
    begin
    if (!rst_n) q <= RST_VAL;
    else        q <= d;
    end
    
endmodule 
