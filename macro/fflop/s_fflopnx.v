////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : s_fflopnx.v
// Description  : This module is synchronous pipeline/delay data with n clocks.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:28:26 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module s_fflopnx
    (
     clk,
     rst_n,
     d,
     qn
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           SIZE    = 8;
parameter           RST_VAL = {SIZE{1'b0}};
parameter           DELAY   = 3;
parameter           SHIFTW  = SIZE*DELAY;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [SIZE-1:0]    d;
output [SIZE-1:0]   qn;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

generate
    begin
    if (DELAY == 0)
        begin
        assign qn = d;
        end
    else if (DELAY == 1)
        begin
        wire [SHIFTW-1:0]  shiftdat;
        s_fflopx #(SHIFTW, RST_VAL) pl_shiftdat(clk, rst_n, d, shiftdat);
        assign             qn = shiftdat;
        end
    else 
        begin
        wire [SHIFTW-1:0]  shiftdat;
        s_fflopx #(SHIFTW) pl_shiftdat(clk, rst_n, {shiftdat[SIZE*(DELAY-1)-1:0], d}, shiftdat);
        assign             qn = shiftdat[SHIFTW-1:SHIFTW-SIZE];
        end
    end
endgenerate

endmodule
