////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : s_pl_reg.v
// Description  : This module is synchronous pipeline register.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:26:56 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module s_pl_reg
    (
     clk,
     rst_n,
     idat,
     odat
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           SIZE = 8;
parameter           RST_VAL = {SIZE{1'b0}};

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [SIZE-1:0]    idat;
output [SIZE-1:0]   odat;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [SIZE-1:0]      odat;
always @(posedge clk)
    begin
    if (!rst_n)     odat <= RST_VAL;
    else            odat <= idat;
    end

endmodule 
