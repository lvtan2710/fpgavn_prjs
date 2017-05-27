////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : pconfigx.v
// Description  : This module is used as a macro for Configuration Register.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:14:16 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module pconfigx
    (
     clk,
     rst_n,
     upen,
     upws,
     uprs,
     updi,
     updo,
     upack,
     cfg_out
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           CPUW = 8;
parameter           RST_VAL = {CPUW{1'b0}};

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input               upen;
input               upws;
input               uprs;
input [CPUW-1:0]    updi;
output [CPUW-1:0]   updo;
output              upack;
output [CPUW-1:0]   cfg_out;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [CPUW-1:0]     int_reg;
always @(posedge clk)
    begin
    if (!rst_n)     int_reg <= RST_VAL;
    else            int_reg <= (upws & upen) ? updi : int_reg;
    end

assign              cfg_out = int_reg;
assign              updo    = upen ? int_reg : {CPUW{1'b0}};

assign              upack = upen & (upws | uprs);

endmodule 
