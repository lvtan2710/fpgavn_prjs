////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : stickyx.v
// Description  : This module is used as macro for sticky event register. This
// latch register has 2 features:
//  + Can read latch event.
//  + Write 1 to clear this event.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:09:28 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module stickyx
    (
     clk,
     rst_n,
     evnt,
     upact,
     upen,
     upws,
     uprs,
     updi,
     updo,
     upack   
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           WIDTH =8;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input [WIDTH-1:0]   evnt;
input               upact;
input               upen;
input               upws;
input               uprs;
input [WIDTH-1:0]   updi;
output [WIDTH-1:0]  updo;
output              upack;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                wr_en;
wire                rd_en;
assign              wr_en = upen & upws;
assign              rd_en = upen & uprs;

reg [WIDTH-1:0]     lat_evnt;
always @(posedge clk)
    begin
    if (!rst_n)     
        lat_evnt <= {WIDTH{1'b0}};
    else if (!upact)    
        lat_evnt <= wr_en ? updi : lat_evnt;
    else if (wr_en)
        lat_evnt <= evnt | (lat_evnt & ~updi);
    else
        lat_evnt <= evnt | lat_evnt;
    end

reg [WIDTH-1:0]     updo;
always @(posedge clk)
    begin
    if (!rst_n)     updo <= {WIDTH{1'b0}};
    else            updo <= rd_en ? lat_evnt : {WIDTH{1'b0}};
    end

//assign updo = rd_en ? lat_evnt : {WIDTH{1'b0}};

reg                 upack;
always @(posedge clk)
    begin
    if (!rst_n) upack <= 1'b0;
    else        upack <= wr_en | rd_en;
    end

endmodule 
