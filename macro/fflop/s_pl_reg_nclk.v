////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : s_pl_reg_nclk.v
// Description  : This module is synchronous pipeline/delay data with n clocks..
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:26:34 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module s_pl_reg_nclk
    (
     clk,
     rst_n,
     idat,
     odat
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           SIZE     = 8;
parameter           DELAY    = 3;
parameter           RST_VAL  = {SIZE{1'b0}};
parameter           SHIFTW   = SIZE*DELAY;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [SIZE-1:0]    idat;
output [SIZE-1:0]   odat;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

generate
    begin
    if (DELAY == 0)
        begin
        assign odat = idat;
        end
    else if (DELAY == 1)
        begin
        wire [SHIFTW-1:0]  shiftdat;
        s_pl_reg #(SHIFTW, RST_VAL) pl_shiftdat(clk, rst_n, idat, shiftdat);
        assign             odat = shiftdat;
        end
    else 
        begin
        wire [SHIFTW-1:0]  shiftdat;
        s_pl_reg #(SHIFTW, RST_VAL) pl_shiftdat(clk, rst_n, {shiftdat[SIZE*(DELAY-1)-1:0], idat}, shiftdat);
        assign             odat = shiftdat[SHIFTW-1:SHIFTW-SIZE];
        end
    end
endgenerate

endmodule 
