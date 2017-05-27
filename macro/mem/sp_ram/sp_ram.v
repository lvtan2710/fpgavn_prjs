////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : sp_ram.v
// Description  : This IP is Single Port RAM with these features:
//  + Implemented in Inferred method for both Xilinx & Altera FPGA Family with 
//    3 modes:
//      - WRITE_FIRST
//      - READ_FIRST
//      - NO_CHANGE (default)
//      _ Write & read after 1 clock cycle
//  + Support implementation which using IP Cores:
//      - Block Memory Generator (Xilinx)
//      - IP Catalog which using altsyncram (Altera)
//  + WRITE_WIDTH = READ_WIDTH (If user need different WIDTH, Xilinx can support
//    and user must design by different module)
//  + Xilinx can add 2 clock cycles and Altera add 1 clock cycle at the output.
//  + Altera IP Core has 3 write modes which depend on type of memory (p12,13 
//    user guide) but in Single Port RAM, new data flows through to output:
//      - Don't care
//      - New data
//      - Old data
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:46:57 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module sp_ram
    (
     clk,
     rst_n,
     clr,
     clrrdy,
     we,
     addr,
     din,
     dout
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_CLRENA      = `CLEAR_RAM_ENABLE;// Clear Content RAM Enable. 0: disable, 1: enable
parameter G_FAMILY      = `FPGA_FAMILY;     // XILINX, ALTERA
parameter G_DEVICE      = `FPGA_DEVICE;     // zynq, 7series: virtex7, kintex7, artix7,
                                            // Cyclone V

parameter G_TYPE        = "INFER";          // INFER(default), BLOCK, LUT
parameter G_ADDR        = 10;
parameter G_WIDTH       = 16;
parameter G_DEPTH       = 2**G_ADDR;
parameter G_PIPELINE    = 1;                // From 1 to n cycles
parameter G_RST_VAL     = {G_WIDTH{1'b0}};

// Xilinx's Attributes
parameter X_ALGORITHM   = 1;                // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;                // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
parameter X_WR_MODE     = "NO_CHANGE";      // WRITE_FIRST, READ_FIRST, NO_CHANGE
parameter X_MEM_REG     = 0;
parameter X_MUX_REG     = (G_PIPELINE == 1) ? 0 : 1;
parameter X_PIPELINE    = (G_PIPELINE >= 2) ? G_PIPELINE - 2 : 0;
parameter X_PIPELINELUT = (G_PIPELINE > 1)  ? 1 : 0;

// Altera's Attributes
parameter A_REG_EN      = (G_PIPELINE == 1) ? "UNREGISTERED" : "CLOCK0";     // CLOCK0, UNREGISTERED
parameter A_PIPELINE    = (G_PIPELINE <= 2) ? 0 : G_PIPELINE - 2;
parameter A_WR_MODE     = "DONT_CARE";  // DONT_CARE (default),
                                        // NEW_DATA_NO_NBE_READ (X on masked byte),
                                        // OLD_DATA (support for BRAM)
parameter A_MAXDEPTH    = 0;            // 0 (auto), 128, 256, 512, 1024, 2048, 4096
parameter A_BRAM_TYPE   = "AUTO";       // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
// M512 blocks are not supported in true dual-port RAM mode
// MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode
parameter A_INIT_FILE   = "UNUSED";

parameter DELAY_CTRL    = (((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK")) ? 0            :
                           ((G_FAMILY == "XILINX") & (G_TYPE == "LUT") & (G_PIPELINE > 1)) ? (G_PIPELINE-2) :
                           ((G_FAMILY == "ALTERA") & (G_PIPELINE > 2))    ? A_PIPELINE   :
                           ((G_TYPE == "INFER") & (G_PIPELINE != 1))      ? G_PIPELINE-1 : 0);

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                clk;
input                rst_n;
input                clr;
output               clrrdy;
input                we;
input [G_ADDR-1:0]   addr;
input [G_WIDTH-1:0]  din;
output [G_WIDTH-1:0] dout;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                 i_we;
wire [G_WIDTH-1:0]   i_di;
wire [G_ADDR-1:0]    i_addr;

generate
    begin
    if (G_CLRENA == 1)
        begin: gen_ram_reset
        wire                clrwe;
        wire [G_ADDR-1:0]   clraddr;
        ram_rst_ctrl
            #(
              .G_ADDR   (G_ADDR),
              .G_DEPTH  (G_DEPTH)
              ) ram_rst_ctrl
             (
              .clk      (clk),
              .rst_n    (rst_n),
              .clrena   (clr),
              .clrrdy   (clrrdy),
              .clrwe    (clrwe),
              .clraddr  (clraddr)
              );

        assign i_we    = clrwe | we;
        assign i_addr  = clrwe ? clraddr : addr;
        assign i_di    = clrwe ? G_RST_VAL : din;
        end
    else
        begin
        assign clrrdy  = 1'b1;
        assign i_we    = we;
        assign i_addr  = addr;
        assign i_di    = din;
        end
    end
endgenerate

wire [G_WIDTH-1:0]   wire_dout;

generate
    begin
    if ((G_TYPE == "BLOCK") & (G_FAMILY == "XILINX"))
        begin: gen_xil_sp_bram
        xil_sp_bram     
            #(
              .G_ADDR       (G_ADDR),
              .G_WIDTH      (G_WIDTH),
              .G_DEPTH      (G_DEPTH),
              .G_DEVICE     (G_DEVICE),
              .X_ALGORITHM  (X_ALGORITHM),
              .X_PRIM_TYPE  (X_PRIM_TYPE),
              .X_WR_MODE    (X_WR_MODE),
              .X_MEM_REG    (X_MEM_REG),
              .X_MUX_REG    (X_MUX_REG),
              .X_PIPELINE   (X_PIPELINE)
              )
        xil_sp_bram
            (
             .clka          (clk),
             .wea           (i_we),
             .addra         (i_addr),
             .dina          (i_di),
             .douta         (wire_dout)
             );
        end
    else if ((G_TYPE == "BLOCK") &  (G_FAMILY == "ALTERA"))
        begin: gen_alt_sp_bram
        alt_sp_bram
            #(
              .G_ADDR       (G_ADDR),
              .G_WIDTH      (G_WIDTH),
              .G_DEPTH      (G_DEPTH),
              .G_DEVICE     (G_DEVICE),
              .A_REG_EN     (A_REG_EN),
              .A_WR_MODE    (A_WR_MODE),
              .A_MAXDEPTH   (A_MAXDEPTH),
              .A_BRAM_TYPE  (A_BRAM_TYPE),
              .A_INIT_FILE  (A_INIT_FILE)
              )
        alt_sp_bram
            (
             .clock         (clk),
             .wren          (i_we),
             .address       (i_addr),
             .data          (i_di),
             .q             (wire_dout)
             );
        end
    else if ((G_TYPE == "LUT") &  (G_FAMILY == "XILINX"))
        begin: gen_xil_sp_lutram
        xil_sp_lutram     
            #(
              .G_ADDR       (G_ADDR),
              .G_WIDTH      (G_WIDTH),
              .G_DEPTH      (G_DEPTH),
              .G_DEVICE     (G_DEVICE),
              .X_PIPELINE   (X_PIPELINELUT)
              )
        xil_sp_lutram
            (
             .clk           (clk),
             .we            (i_we),
             .a             (i_addr),
             .d             (i_di),
             .qspo          (wire_dout)
             );     
        end
    else if ((G_TYPE == "LUT") &  (G_FAMILY == "ALTERA"))
        begin: gen_alt_sp_lutram
        alt_sp_lutram
            #(
              .G_ADDR       (G_ADDR),
              .G_WIDTH      (G_WIDTH),
              .G_DEPTH      (G_DEPTH),
              .G_DEVICE     (G_DEVICE),
              .A_REG_EN     (A_REG_EN),
              .A_WR_MODE    (A_WR_MODE),
              .A_INIT_FILE  (A_INIT_FILE)
              )
        alt_sp_lutram
            (
             .clock         (clk),
             .wren          (i_we),
             .address       (i_addr),
             .data          (i_di),
             .q             (wire_dout)
             );
        end
    else    // (G_TYPE == "INFER")
        begin: gen_sp_bram_inf
        sp_bram_inf #(G_ADDR, G_WIDTH, X_WR_MODE) sp_bram_inf(clk, i_we, i_addr, i_di, wire_dout);
        end
    end
endgenerate

s_fflopnx #(G_WIDTH,G_RST_VAL,DELAY_CTRL) pl_wire_rdat(clk, rst_n, wire_dout, dout);

endmodule 
