////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : tdp_ram.v
// Description  : This IP is True Dual Port RAM with these features:
//  + Implemented in inferred method for both Xilinx & Altera FPGA family with
//  only 1 mode NO_CHANGE, WRITE_WIDTH = READ_WIDTH.
//  + Support implementation which using IP Cores:
//      - Block Memory Generator (Xilinx)
//          + WRITE_WIDTH = READ_WIDTH.
//          + WRITE_WIDTH # READ_WIDTH --> ratio must be 2,4,8,16,32,64.
//          + support pipline registers with configuration
//          + 3 modes: WRITE_FIRST, READ_FIRST, NO_CHANGE (default)
//      - IP Catalog which using altsyncram (Altera)
//          + WRITE_WIDTH = READ_WIDTH.
//          + WRITE_WIDTH # READ_WIDTH --> ratio must be 2,4,8,16,32,64.
//          + support pipeline registers up to 2 clock cycles
//          + 3 modes: Don't care, New data, Old data
// 
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:51:08 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module tdp_ram
    (
     clk_a,
     rst_n,
     clr,
     clrrdy,
     wen_a,
     add_a,
     wdat_a,
     rdat_a,
     
     clk_b,
     wen_b,
     add_b,
     wdat_b,
     rdat_b
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_CLRENA      = `CLEAR_RAM_ENABLE;// Clear Content RAM Enable. 0: disable, 1: enable
parameter G_FAMILY      = `FPGA_FAMILY;     // XILINX, ALTERA
parameter G_DEVICE      = `FPGA_DEVICE;     // zynq, 7series, virtex7, kintex7, artix7,
                                            // Cyclone V
parameter G_TYPE        = "BLOCK";  // INFER, BLOCK
parameter X_BLKVER      = 20;               //`BLOCK_VERSION;   // 20, 30

parameter G_ADDR_A      = 10;
parameter G_WIDTH_A     = 16;
parameter G_DEPTH_A     = 2**G_ADDR_A;
parameter G_ADDR_B      = G_ADDR_A;
parameter G_WIDTH_B     = G_WIDTH_A;
parameter G_DEPTH_B     = G_DEPTH_A;
parameter G_PIPELINE    = 1;                // Block RAM: 1 - 5, LUT: no limit
parameter G_RST_VAL     = {G_WIDTH_A{1'b0}};
parameter G_COMMONCLK   = 0;

// Xilinx's Attribute
parameter X_ALGORITHM   = 1;            // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;            // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
parameter X_WR_MODE     = "WRITE_FIRST";// WRITE_FIRST, READ_FIRST, NO_CHANGE
parameter X_MEM_REG     = 0;
parameter X_MUX_REG     = (G_PIPELINE == 1) ? 0 : 1;
parameter X_PIPELINE    = (G_PIPELINE >= 2) ? G_PIPELINE - 2 : 0;
parameter X_PIPELINELUT = (G_PIPELINE > 1)  ? 1 : 0;

// Altera's Attribute
parameter A_REG_EN_A    = (G_PIPELINE == 1) ? "UNREGISTERED" : "CLOCK0";// CLOCK0, UNREGISTERED; Source Clock for port A
parameter A_REG_EN_B    = (G_PIPELINE == 1) ? "UNREGISTERED" : "CLOCK1";// CLOCK1, UNREGISTERED; Source Clock for port B
parameter A_PIPELINE    = (G_PIPELINE <= 2) ? 0 : G_PIPELINE - 2;
parameter A_WR_MODE     = "NEW_DATA_NO_NBE_READ";   // NEW_DATA_NO_NBE_READ (X on masked byte)
                                                  // NEW_DATA_WITH_NBE_READ (old data on masked byte)
parameter A_MAXDEPTH    = 1024;
parameter A_BRAM_TYPE   = "AUTO";       // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
parameter A_INIT_FILE   = "UNUSED";     // load file hex

parameter DELAY_CTRL    = (((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK")) ? 0            :
                           ((G_FAMILY == "XILINX") & (G_TYPE == "LUT") & (G_PIPELINE > 1)) ? (G_PIPELINE-2) :
                           ((G_FAMILY == "ALTERA") & (G_PIPELINE > 2))    ? A_PIPELINE   :
                           ((G_TYPE == "INFER") & (G_PIPELINE != 1))      ? G_PIPELINE-1 : 0);

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk_a;
input                   rst_n;
input                   clr;
output                  clrrdy;
input                   wen_a;
input [G_ADDR_A-1:0]    add_a;
input [G_WIDTH_A-1:0]   wdat_a;
output [G_WIDTH_A-1:0]  rdat_a;

input                   clk_b;
input                   wen_b;
input [G_ADDR_B-1:0]    add_b;
input [G_WIDTH_B-1:0]   wdat_b;
output [G_WIDTH_B-1:0]  rdat_b;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                    i_we;
wire [G_WIDTH_A-1:0]    i_di;
wire [G_ADDR_A-1:0]     i_addr;

generate
    begin
    if (G_CLRENA == 1)
        begin: gen_ram_reset
        wire                clrwe;
        wire [G_ADDR_A-1:0] clraddr;
        ram_rst_ctrl
            #(
              .G_ADDR       (G_ADDR_A),
              .G_DEPTH      (G_DEPTH_A)
              ) i_ram_rst_ctrl
             (
              .clk          (clk_a),
              .rst_n        (rst_n),
              .clrena       (clr),
              .clrrdy       (clrrdy),
              .clrwe        (clrwe),
              .clraddr      (clraddr)
              );

        assign i_we    = clrwe | wen_a;
        assign i_addr  = clrwe ? clraddr    : add_a;
        assign i_di    = clrwe ? G_RST_VAL  : wdat_a;
        end
    else
        begin
        assign clrrdy  = 1'b1;
        assign i_we    = wen_a;
        assign i_addr  = add_a;
        assign i_di    = wdat_a;
        end
    end
endgenerate

wire [G_WIDTH_A-1:0]    wire_rdat_a;
wire [G_WIDTH_B-1:0]    wire_rdat_b;

generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK"))
        begin: gen_xil_tdp_bram
        xil_tdp_bram     
            #(
              .G_ADDR_A     (G_ADDR_A),
              .G_WIDTH_A    (G_WIDTH_A),
              .G_DEPTH_A    (G_DEPTH_A),
              .G_ADDR_B     (G_ADDR_B),
              .G_WIDTH_B    (G_WIDTH_B),
              .G_DEPTH_B    (G_DEPTH_B),
              .G_DEVICE     (G_DEVICE),
              .G_COMMONCLK  (G_COMMONCLK),
              //.X_BLKVER     (X_BLKVER),
              .X_ALGORITHM  (X_ALGORITHM),
              .X_PRIM_TYPE  (X_PRIM_TYPE),
              .X_WR_MODE    (X_WR_MODE),
              .X_MEM_REG    (X_MEM_REG),
              .X_MUX_REG    (X_MUX_REG),
              .X_PIPELINE   (X_PIPELINE)
              ) i_xil_tdp_bram
            (
             .clka          (clk_a),
             .wea           (i_we),
             .addra         (i_addr),
             .dina          (i_di),
             .douta         (wire_rdat_a),
             .clkb          (clk_b),
             .web           (wen_b),
             .addrb         (add_b),
             .dinb          (wdat_b),
             .doutb         (wire_rdat_b)
             );
        end
    else if ((G_FAMILY == "ALTERA") & (G_TYPE == "BLOCK"))
        begin: gen_alt_tdp_bram
        alt_tdp_bram
            #(
              .G_ADDR_A     (G_ADDR_A),
              .G_WIDTH_A    (G_WIDTH_A),
              .G_DEPTH_A    (G_DEPTH_A),
              .G_ADDR_B     (G_ADDR_B),
              .G_WIDTH_B    (G_WIDTH_B),
              .G_DEPTH_B    (G_DEPTH_B),
              .G_DEVICE     (G_DEVICE),
              .G_COMMONCLK  (G_COMMONCLK),
              .A_REG_EN_A   (A_REG_EN_A),
              .A_REG_EN_B   (A_REG_EN_B),
              .A_WR_MODE    (A_WR_MODE),
              .A_MAXDEPTH   (A_MAXDEPTH),
              .A_BRAM_TYPE  (A_BRAM_TYPE),
              .A_INIT_FILE  (A_INIT_FILE)
              ) i_alt_tdp_bram
            (
             .inclock       (clk_a),
             .wren_a        (i_we),
             .address_a     (i_addr),
             .data_a        (i_di),
             .q_a           (wire_rdat_a),
             .outclock      (clk_b),
             .wren_b        (wen_b),
             .address_b     (add_b),
             .data_b        (wdat_b),
             .q_b           (wire_rdat_b)
             );
        end
    else // if (G_IMPL_TYPE == "INFER")
        begin: gen_tdp_bram_inf
        tdp_bram_inf
            #(
              .G_ADDR       (G_ADDR_A),
              .G_WIDTH      (G_WIDTH_A)
              ) i_tdp_bram_inf
             (
              .clka         (clk_a), 
              .wea          (i_we),
              .addra        (i_addr),
              .dia          (i_di),
              .doa          (wire_rdat_a),
              .clkb         (clk_b),
              .web          (wen_b),
              .addrb        (add_b),
              .dib          (wdat_b),
              .dob          (wire_rdat_b)
              );
        end
    end
endgenerate

s_fflopnx #(G_WIDTH_A,{G_WIDTH_A{1'b0}},DELAY_CTRL) pl_wire_rdata(clk_a, rst_n, wire_rdat_a, rdat_a);
s_fflopnx #(G_WIDTH_B,{G_WIDTH_B{1'b0}},DELAY_CTRL) pl_wire_rdatb(clk_b, rst_n, wire_rdat_b, rdat_b);

endmodule 
