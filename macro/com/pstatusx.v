////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : pstatusx.v
// Description  : This module is used as a macro for status register with just
// able to read only. The status from engine is updated online and continuously.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:13:45 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module pstatusx
    (
     clk,
     rst_n,
     sta_in,
     sta_vld,
     upen,
     uprs,
     updo,
     upack
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           WIDTH = 8;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [WIDTH-1:0]   sta_in;
input               sta_vld;
input               upen;
input               uprs;
output [WIDTH-1:0]  updo;
output              upack;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                rd_en;
assign              rd_en = upen & uprs;

reg [WIDTH-1:0]     updo;
always @(posedge clk)
    begin
    if(!rst_n)      updo <= {WIDTH{1'b0}};
    else            updo <= sta_vld ? sta_in : updo;
    end

reg                 upack;
always @(posedge clk)
    begin
    if (!rst_n)     upack <= 1'b0;
    else            upack <= rd_en;
    end

endmodule 
