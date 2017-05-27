////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rtlmem_1r1w1x.v
// Description  : Wrapper of memory 1 port read, 1 port write, pipeline 1 cycle:
//  + write and read can access simutaneously
//  + Data read after 1 clock cycle
//  + Support 3 type of RAM: Inferred, Block, LUT.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:55:33 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rtlmem_1r1w1x
    (
     wclk,
     rst_n,
     
     // Clear content RAM
     clren,
     clrrdy,

     // Write port
     memwe,
     memwa,
     memdi,

     // Read port
     rclk,
     memre,
     memra,
     memdo   
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
input                   wclk;
input                   rst_n;

// Clear content RAM
input                   clren;
output                  clrrdy;

// Write port
input                   memwe;
input [G_WRADDR-1:0]    memwa;
input [G_WRWIDTH-1:0]   memdi;

// Read port
input                   rclk;
input                   memre;
input [G_RDADDR-1:0]    memra;
output [G_RDWIDTH-1:0]  memdo;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [G_RDWIDTH-1:0]    wire_do;
`ifdef RTL_MEM_SIM
reg                     memre1;
always @(posedge rclk)
    begin
    if (!rst_n) memre1 <= 1'b0;
    else        memre1 <= memre;
    end

assign memdo = memre1 ? wire_do : {G_RDWIDTH{1'b0}};  // if not read, data is zero for easy debug
`else
assign memdo = wire_do;
`endif

sdp_ram
    #(
      .G_TYPE           (G_TYPE),
      .G_WRADDR         (G_WRADDR),
      .G_WRWIDTH        (G_WRWIDTH),
      .G_WRDEPTH        (G_WRDEPTH),
      .G_RDADDR         (G_RDADDR),
      .G_RDWIDTH        (G_RDWIDTH),
      .G_RDDEPTH        (G_RDDEPTH),
      .G_PIPELINE       (1),
      .G_RST_VAL        (G_RST_VAL),

      .X_ALGORITHM      (X_ALGORITHM),
      .X_PRIM_TYPE      (X_PRIM_TYPE),
      .X_WR_MODE        ("WRITE_FIRST"),

      .A_WR_MODE        ("NEW_DATA_NO_NBE_READ"),
      .A_MAXDEPTH       (A_MAXDEPTH),
      .A_BRAM_TYPE      (A_BRAM_TYPE),
      .A_INIT_FILE      (A_INIT_FILE)
      )
i_sdp_ram
    (
     .wclk              (wclk),
     .rst_n             (rst_n),
     .clr               (clren),
     .clrrdy            (clrrdy),
     .wen               (memwe),
     .wadd              (memwa),
     .wdat              (memdi),
     .rclk              (rclk),
     .radd              (memra),
     .rdat              (wire_do)
     );

endmodule 
