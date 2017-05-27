////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rtlmem_2r2w_3x.v
// Description  : Wrapper of memory 2 port read, 2 port write:
//  + 2 Port read, write access: 
//  + Data of each port read/write after 3 clock cycles.
//  + Note: 2r2w3x --> first 2 indicates 2 port read, second 2 indicates 2 port
//  write, 3 indicates cycle delay.
//          This wrapper does not support type LUT.
//  + Just only support Inferred, Block IP.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:53:36 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rtlmem_2r2w_3x
    (
     clk2x,
     rst2x_n,
     
     clk1x,
     rst1x_n,
     clren,
     clrrdy,
     
     //-------------------------------------------------------------------------
     // Synchronous with clk1x domain
     // port 1
     mem1_we,
     mem1_wa,
     mem1_di,

     mem1_re,
     mem1_ra,
     mem1_do,

     // port 2
     mem2_we,
     mem2_wa,
     mem2_di,

     mem2_re,
     mem2_ra,
     mem2_do
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_TYPE        = "BLOCK";
parameter G_WRADDR      = 10;
parameter G_WRWIDTH     = 16;
parameter G_WRDEPTH     = 2**G_WRADDR;
parameter G_RDADDR      = G_WRADDR;
parameter G_RDWIDTH     = G_WRWIDTH;
parameter G_RDDEPTH     = G_WRDEPTH;
parameter G_RST_VAL     = {G_RDWIDTH{1'b0}};

// Xilinx's Attribute
parameter X_ALGORITHM   = 1;            // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;            // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512

// Altera's Attribute
parameter A_MAXDEPTH    = 0;            // 0 (auto), 128, 256, 512, 1024, 2048, 4096
parameter A_BRAM_TYPE   = "AUTO";       // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
parameter A_INIT_FILE   = "UNUSED";

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk2x;
input                   rst2x_n;

input                   clk1x;
input                   rst1x_n;
input                   clren;
output                  clrrdy;

//------------------------------------------------------------------------------
// Synchronous with clk1x domain
// port 1
input                   mem1_we;
input [G_WRADDR-1:0]    mem1_wa;
input [G_WRWIDTH-1:0]   mem1_di;

input                   mem1_re;
input [G_RDADDR-1:0]    mem1_ra;
output [G_RDWIDTH-1:0]  mem1_do;

// port 2
input                   mem2_we;
input [G_WRADDR-1:0]    mem2_wa;
input [G_WRWIDTH-1:0]   mem2_di;

input                   mem2_re;
input [G_RDADDR-1:0]    mem2_ra;
output [G_RDWIDTH-1:0]  mem2_do;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation




endmodule 
