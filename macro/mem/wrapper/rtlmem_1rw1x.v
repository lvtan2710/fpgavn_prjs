////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rtlmem_1rw1x.v
// Description  : Wrapper of memory with this featureS:
//  + 1 Port share read, write access.
//  + Data read after 1 clock cycle.
//  + Note: 1rw1x --> first 1 indicates 1 port, second 1 indicates cycle delay.
//  + Support 3 type of RAM: Inferred, Block, LUT.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:54:44 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rtlmem_1rw1x
    (
     clk,
     rst_n,

     // Clear content RAM
     clren,
     clrrdy,

     // Memory interface
     memad,
     memwe,
     memdi,
     memre,
     memdo
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_TYPE        = "INFER";      // INFER(default), BLOCK, LUT
parameter G_ADDR        = 10;
parameter G_WIDTH       = 16;
parameter G_DEPTH       = 2**G_ADDR;
parameter G_RST_VAL     = {G_WIDTH{1'b0}};

// Xilinx's Attributes
parameter X_ALGORITHM   = 1;            // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;            // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512

// Altera's Attributes
parameter A_MAXDEPTH    = 0;            // 0 (auto), 128, 256, 512, 1024, 2048, 4096
parameter A_BRAM_TYPE   = "AUTO";       // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
// M512 blocks are not supported in true dual-port RAM mode
// MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode
parameter A_INIT_FILE   = "UNUSED";

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;

// Clear content RAM
input                   clren;
output                  clrrdy;

// Memory interface
input [G_ADDR-1:0]      memad;
input                   memwe;
input [G_WIDTH-1:0]     memdi;
input                   memre;
output [G_WIDTH-1:0]    memdo;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [G_WIDTH-1:0]      wire_do;

`ifdef RTL_MEM_SIM
reg                     memre1;
always @(posedge clk)
    begin
    if (!rst_n) memre1 <= 1'b0;
    else        memre1 <= memre;
    end

assign memdo = memre1 ? wire_do : {G_WIDTH{1'b0}};  // if not read, data is zero for easy debug
`else
assign memdo = wire_do;
`endif

sp_ram 
    #(
      .G_TYPE           (G_TYPE),
      .G_ADDR           (G_ADDR),
      .G_WIDTH          (G_WIDTH),
      .G_DEPTH          (G_DEPTH),
      .G_PIPELINE       (1),
      .G_RST_VAL        (G_RST_VAL),
      
      .X_ALGORITHM      (X_ALGORITHM),
      .X_PRIM_TYPE      (X_PRIM_TYPE),
      .X_WR_MODE        ("WRITE_FIRST"),
      
      .A_WR_MODE        ("DONT_CARE "),
      .A_MAXDEPTH       (A_MAXDEPTH),
      .A_BRAM_TYPE      (A_BRAM_TYPE),
      .A_INIT_FILE      (A_INIT_FILE)
      )
i_sp_ram
    (
     .clk               (clk),
     .rst_n             (rst_n),
     .clr               (clren),
     .clrrdy            (clrrdy),
     .we                (memwe),
     .addr              (memad),
     .din               (memdi),
     .dout              (wire_do)
     );

endmodule 
