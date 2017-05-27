////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : sp_bram_inf.v
// Description  : This is the single port RAM which is implemented in Xilinx/Altera 
// Block RAM. There are 3 ways to incorporate RAM into a design:
//  + Inference
//  + Core Generator
//  + Instantiation
//  In this design, Inference method are used.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:49:59 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module sp_bram_inf
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
parameter           G_MODE  = "NO_CHANGE";   // READ_FIRST, WRITE_FIRST, NO_CHANGE

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                clk;
input                we;
input [G_ADDR-1:0]   addr;
input [G_WIDTH-1:0]  din;
output [G_WIDTH-1:0] dout;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

generate
    begin
    if (G_MODE == "READ_FIRST")
        sp_bram_inf_rf #(G_ADDR, G_WIDTH) sp_bram_inf_rf(clk, we, addr, din, dout);
    else if (G_MODE == "WRITE_FIRST")
        sp_bram_inf_wf #(G_ADDR, G_WIDTH) sp_bram_inf_wf(clk, we, addr, din, dout);
    else // (G_MODE == "NO_CHANGE")
        sp_bram_inf_nc #(G_ADDR, G_WIDTH) sp_bram_inf_nc(clk, we, addr, din, dout);
    end 
endgenerate

endmodule 
