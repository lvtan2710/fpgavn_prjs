////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : sp_bram_inf_rf.v
// Description  : This is the single port RAM which is implemented in Xilinx/ALtera
//  Block RAM. There are 3 ways to incorporate RAM into a design:
//  + Inference
//  + Core Generator
//  + Instantiation
//  In this design, Inference method are used.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:49:17 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module sp_bram_inf_rf
    (
     clk,
     we,
     addr,
     din,
     dout
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           G_ADDR  = 6;
parameter           G_WIDTH = 16;
localparam          G_DEPTH = 2**G_ADDR;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                clk;
input                we;
input [G_ADDR-1:0]   addr;
input [G_WIDTH-1:0]  din;
output [G_WIDTH-1:0] dout;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [G_WIDTH-1:0]    dout;
reg [G_WIDTH-1:0]    RAM[G_DEPTH-1:0];

always @(posedge clk)
    begin
    if (we) RAM[addr] <= din;
    dout <= RAM[addr];
    end
    
endmodule 
