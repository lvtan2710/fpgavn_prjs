////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : tdp_bram_inf.v
// Description  : This is the True Dual Port RAM module. There are 3 ways to 
// implement RAM into a design:
//  + Inference
//  + Core Generator
//  + Instantiation (Macro, Primitive)
//  In this design, Inference method is used.
// 
// Limitation:
//  + Write width = Read width
//  + 1 Cycle clock latency. If need more clock latency, pipeline registers must 
// be implemented out side.
//  + Algorithm for optimal (area, performance, power) depend on setting of 
// synthesis tool.
//  + Operation mode is only NO_CHANGE.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:51:31 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module tdp_bram_inf
    (
     clka,
     wea,
     addra,
     dia,
     doa,

     clkb,
     web,
     addrb,
     dib,
     dob
     );

//////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           G_ADDR  = 6;
parameter           G_WIDTH = 16;

localparam          G_DEPTH = 2**G_ADDR;
         
////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                clka;
input                wea;
input [G_ADDR-1:0]   addra;
input [G_WIDTH-1:0]  dia;
output [G_WIDTH-1:0] doa;

input                clkb;
input                web;
input [G_ADDR-1:0]   addrb;
input [G_WIDTH-1:0]  dib;
output [G_WIDTH-1:0] dob;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [G_WIDTH-1:0]    RAM[G_DEPTH-1:0];
reg [G_WIDTH-1:0]    doa, dob;

always @(posedge clka)
    begin
    if (wea) RAM[addra] <= dia;
    doa <= RAM[addra];
    end

always @(posedge clkb)
    begin
    if (web) RAM[addrb] <= dib;
    dob <= RAM[addrb];
    end

endmodule 
