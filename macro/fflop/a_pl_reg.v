////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : a_pl_reg.v
// Description  : This module is asynchronous pipeline register.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:32:05 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module a_pl_reg
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

always @(posedge clk or negedge rst_n)
    begin
    if (!rst_n) odat <= RST_VAL;
    else        odat <= idat;
    end
    
endmodule 
