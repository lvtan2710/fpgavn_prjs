////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rtlmem_2rw1x.v
// Description  : Wrapper of memory 2 port share read write:
//  + 2 Port share read, write access: when write, can't read; when read, can't 
// write..
//  + Data of each port read after 1 clock cycle.
//  + Note: 2rw1x --> first 2 indicates 2 port, 1 indicates cycle delay.
//          This wrapper does not support type LUT.
//  + Just only support Inferred, Block IP.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:53:10 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rtlmem_2rw1x
    (
     clk_a,
     rst_n,

     // Clear content RAM
     clren,
     clrrdy,

     // Memory port A interface
     memad_a,
     memwe_a,
     memdi_a,
     memre_a,
     memdo_a,

     // Memory port B interface
     clk_b,
     memad_b,
     memwe_b,
     memdi_b,
     memre_b,
     memdo_b
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_TYPE        = "BLOCK";
parameter G_ADDR_A      = 10;
parameter G_WIDTH_A     = 16;
parameter G_DEPTH_A     = 2**G_ADDR_A;
parameter G_ADDR_B      = G_ADDR_A;
parameter G_WIDTH_B     = G_WIDTH_A;
parameter G_DEPTH_B     = G_DEPTH_A;
parameter G_RST_VAL     = {G_WIDTH_A{1'b0}};
parameter G_COMMONCLK   = 0;

// Xilinx's Attribute
parameter X_ALGORITHM   = 1;            // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;            // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512

// Altera's Attribute
parameter A_MAXDEPTH    = 0;            // 0 (auto), 128, 256, 512, 1024, 2048, 4096
parameter A_BRAM_TYPE   = "AUTO";       // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
parameter A_INIT_FILE   = "UNUSED";

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk_a;
input                   rst_n;

// Clear content RAM
input                   clren;
output                  clrrdy;

// Memory port A interface
input [G_ADDR_A-1:0]    memad_a;
input                   memwe_a;
input [G_WIDTH_A-1:0]   memdi_a;
input                   memre_a;
output [G_WIDTH_A-1:0]  memdo_a;

// Memory port B interface
input                   clk_b;
input [G_ADDR_B-1:0]    memad_b;
input                   memwe_b;
input [G_WIDTH_B-1:0]   memdi_b;
input                   memre_b;
output [G_WIDTH_B-1:0]  memdo_b;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [G_WIDTH_A-1:0]    wire_do_a;
wire [G_WIDTH_B-1:0]    wire_do_b;

`ifdef RTL_MEM_SIM
reg                     memre_a1;
always @(posedge clk_a)
    begin
    if (!rst_n) memre_a1 <= 1'b0;
    else        memre_a1 <= memre_a;
    end

assign memdo_a = memre_a1 ? wire_do_a : {G_WIDTH_A{1'b0}};

reg                     memre_b1;
always @(posedge clk_b)
    begin
    if (!rst_n) memre_b1 <= 1'b0;
    else        memre_b1 <= memre_b;
    end

assign memdo_b = memre_b1 ? wire_do_b : {G_WIDTH_B{1'b0}};
`else
assign memdo_a = wire_do_a;
assign memdo_b = wire_do_a;
`endif

tdp_ram
    #(
      .G_TYPE           (G_TYPE),
      .G_ADDR_A         (G_ADDR_A),
      .G_WIDTH_A        (G_WIDTH_A),
      .G_DEPTH_A        (G_DEPTH_A),
      .G_ADDR_B         (G_ADDR_B),
      .G_WIDTH_B        (G_WIDTH_B),
      .G_DEPTH_B        (G_DEPTH_B),
      .G_RST_VAL        (G_RST_VAL),
      .G_PIPELINE       (1),
      .G_COMMONCLK      (G_COMMONCLK),

      .X_ALGORITHM      (X_ALGORITHM),
      .X_PRIM_TYPE      (X_PRIM_TYPE),
      .X_WR_MODE        ("WRITE_FIRST"),
      
      .A_WR_MODE        ("NEW_DATA_NO_NBE_READ"),
      .A_MAXDEPTH       (A_MAXDEPTH),
      .A_BRAM_TYPE      (A_BRAM_TYPE),
      .A_INIT_FILE      (A_INIT_FILE)
      )
i_tdp_ram
    (
     .clk_a             (clk_a),
     .rst_n             (rst_n),
     .clr               (clren),
     .clrrdy            (clrrdy),
     .wen_a             (memwe_a),
     .add_a             (memad_a),
     .wdat_a            (memdi_a),
     .rdat_a            (wire_do_a),
     
     .clk_b             (clk_b),
     .wen_b             (memwe_b),
     .add_b             (memad_b),
     .wdat_b            (memdi_b),
     .rdat_b            (wire_do_b)
     );

endmodule 
