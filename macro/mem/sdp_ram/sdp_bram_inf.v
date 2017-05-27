////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : sdp_bram_inf.v
// Description  : This is the simple dual port RAM which is implemented in Xilinx 
//  Block RAM. There are 3 ways to incorporate RAM into a design:
//  + Inference
//  + Core Generator
//  + Instantiation (Macro, Primitive)
//  In this design, Inference method is used.
//
// Limitation:
//  + Write width = Read width
//  + 1 Cycle clock latency. If need more clock latency, pipeline registers must 
// be implemented out side.
//  + Algorithm for optimal (area, performance, power) depend on setting of synthesis tool.
//  + Operation mode is only NO_CHANGE.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:44:58 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module sdp_bram_inf
    (
     clka,
     wea,       // Write enable
     addra,     // Write address
     dia,       // Write data

     clkb,
     addrb,     // Read address
     dob        // Read data
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDR  = 6;
parameter           WIDTH = 16;
         
localparam          DEPTH = 2**ADDR;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clka;
input               wea;
input [ADDR-1:0]    addra;
input [WIDTH-1:0]   dia;

input               clkb;
input [ADDR-1:0]    addrb;
output [WIDTH-1:0]  dob;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [WIDTH-1:0]     dob;
reg [WIDTH-1:0]     RAM[DEPTH-1:0];

always @(posedge clka)
    begin
    if (wea) RAM[addra] <= dia;
    end

always @(posedge clkb)
    begin
    dob <= RAM[addrb];
    end

endmodule 
