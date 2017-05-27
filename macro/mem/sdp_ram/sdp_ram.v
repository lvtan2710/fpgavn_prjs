////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : sdp_ram.v
// Description  : This IP is Simple Dual Port RAM with these features:
//  + Implemented in inferred method for both Xilinx & Altera FPGA family with
//  only 1 mode NO_CHANGE, WRITE_WIDTH = READ_WIDTH.
//  + Support implementation which using IP Cores:
//      - Block Memory Generator (Xilinx)
//          + WRITE_WIDTH = READ_WIDTH.
//          + WRITE_WIDTH # READ_WIDTH --> ratio must be 2,4,8,16,32,64.
//          + support pipline registers with configuration
//          + 1 mode: WRITE_FIRST
//      - IP Catalog which using altsyncram (Altera)
//          + WRITE_WIDTH = READ_WIDTH.
//          + WRITE_WIDTH # READ_WIDTH --> ratio must be 2,4,8,16,32,64.
//          + support pipeline registers up to 2 clock cycles
//          + 3 modes: Don't care, New data, Old data.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:44:36 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module sdp_ram
    (
     wclk,
     rst_n,
     clr,
     clrrdy,
     wen,
     wadd,
     wdat,
     rclk,
     radd,
     rdat
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_CLRENA      = `CLEAR_RAM_ENABLE;// Clear Content RAM Enable. 0: disable, 1: enable
parameter G_FAMILY      = `FPGA_FAMILY;     // XILINX, ALTERA
parameter G_DEVICE      = `FPGA_DEVICE;     // zynq, 7series, virtex7, kintex7, artix7,
                                            // Cyclone V
parameter G_TYPE        = "LUT";  // INFER, BLOCK, LUT

parameter G_WRADDR      = 10;
parameter G_WRWIDTH     = 16;
parameter G_WRDEPTH     = 2**G_WRADDR;
parameter G_RDADDR      = G_WRADDR;
parameter G_RDWIDTH     = G_WRWIDTH;
parameter G_RDDEPTH     = G_WRDEPTH;
parameter G_PIPELINE    = 1;                // Block RAM: 1 - 5, LUT: no limit
parameter G_RST_VAL     = {G_RDWIDTH{1'b0}};

// Xilinx's Attribute
parameter X_ALGORITHM   = 1;                // 0: fixed primitive, 1: Minimum area, 2: low power
parameter X_PRIM_TYPE   = 1;                // 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
parameter X_WR_MODE     = "WRITE_FIRST";    // WRITE_FIRST support; READ_FIRST, NO_CHANGE not support
parameter X_MEM_REG     = 0;
parameter X_MUX_REG     = (G_PIPELINE == 1) ? 0 : 1;
parameter X_PIPELINE    = (G_PIPELINE >= 2) ? G_PIPELINE - 2 : 0;
parameter X_PIPELINELUT = (G_PIPELINE > 1)  ? 1 : 0;

// Altera's Attribute
parameter A_REG_EN      = (G_PIPELINE == 1) ? "UNREGISTERED" : "CLOCK1";         // CLOCK1, UNREGISTERED
parameter A_PIPELINE    = (G_PIPELINE <= 2) ? 0 : G_PIPELINE - 2;
parameter A_WR_MODE     = "NEW_DATA_NO_NBE_READ"; // NEW_DATA_NO_NBE_READ (X on masked byte)
                                                  // NEW_DATA_WITH_NBE_READ (old data on masked byte)
parameter A_MAXDEPTH    = 1024;
parameter A_BRAM_TYPE   = "Auto";           // AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
// M512 blocks are not supported in true dual-port RAM mode
// MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode
parameter A_INIT_FILE   = "UNUSED"; // load file hex

parameter DELAY_CTRL    = (((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK")) ? 0            :
                           ((G_FAMILY == "XILINX") & (G_TYPE == "LUT") & (G_PIPELINE > 1)) ? (G_PIPELINE-2) :
                           ((G_FAMILY == "ALTERA") & (G_PIPELINE > 2))    ? A_PIPELINE   :
                           ((G_TYPE == "INFER") & (G_PIPELINE != 1))      ? G_PIPELINE-1 : 0);

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   wclk;
input                   rst_n;
input                   clr;
output                  clrrdy;
input                   wen;
input [G_WRADDR-1:0]    wadd;
input [G_WRWIDTH-1:0]   wdat;
input                   rclk;
input [G_RDADDR-1:0]    radd;
output [G_RDWIDTH-1:0]  rdat;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                    i_we;
wire [G_WRWIDTH-1:0]    i_di;
wire [G_WRADDR-1:0]     i_addr;

generate
    begin
    if (G_CLRENA == 1)
        begin: gen_ram_reset
        wire                clrwe;
        wire [G_WRADDR-1:0] clraddr;
        ram_rst_ctrl
            #(
              .G_ADDR       (G_WRADDR),
              .G_DEPTH      (G_WRDEPTH)
              ) i_ram_rst_ctrl
             (
              .clk          (wclk),
              .rst_n        (rst_n),
              .clrena       (clr),
              .clrrdy       (clrrdy),
              .clrwe        (clrwe),
              .clraddr      (clraddr)
              );

        assign i_we    = clrwe | wen;
        assign i_addr  = clrwe ? clraddr : wadd;
        assign i_di    = clrwe ? G_RST_VAL : wdat;
        end
    else
        begin
        assign clrrdy  = 1'b1;
        assign i_we    = wen;
        assign i_addr  = wadd;
        assign i_di    = wdat;
        end
    end
endgenerate

wire [G_RDWIDTH-1:0]    wire_rdat;

generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK"))
        begin: gen_xil_sdp_bram
        xil_sdp_bram     
            #(
              .G_WRADDR     (G_WRADDR),
              .G_WRWIDTH    (G_WRWIDTH),
              .G_WRDEPTH    (G_WRDEPTH),
              .G_RDADDR     (G_RDADDR),
              .G_RDWIDTH    (G_RDWIDTH),
              .G_RDDEPTH    (G_RDDEPTH),
              .G_DEVICE     (G_DEVICE),
              .X_ALGORITHM  (X_ALGORITHM),
              .X_PRIM_TYPE  (X_PRIM_TYPE),
              .X_WR_MODE    (X_WR_MODE),
              .X_MEM_REG    (X_MEM_REG),
              .X_MUX_REG    (X_MUX_REG),
              .X_PIPELINE   (X_PIPELINE)
              ) i_xil_sdp_bram
            (
             .clka          (wclk),
             .wea           (i_we),
             .addra         (i_addr),
             .dina          (i_di),
             .clkb          (rclk),
             .addrb         (radd),
             .doutb         (wire_rdat)
             );
        end
    else if ((G_FAMILY == "ALTERA") & (G_TYPE == "BLOCK"))
        begin: gen_alt_sdp_bram             
        alt_sdp_bram
            #(
              .G_WRADDR     (G_WRADDR),
              .G_WRWIDTH    (G_WRWIDTH),
              .G_WRDEPTH    (G_WRDEPTH),
              .G_RDADDR     (G_RDADDR),
              .G_RDWIDTH    (G_RDWIDTH),
              .G_RDDEPTH    (G_RDDEPTH),
              .G_DEVICE     (G_DEVICE),
              .A_REG_EN     (A_REG_EN),
              .A_WR_MODE    (A_WR_MODE),
              .A_MAXDEPTH   (A_MAXDEPTH),
              .A_BRAM_TYPE  (A_BRAM_TYPE),
              .A_INIT_FILE  (A_INIT_FILE)
              ) i_alt_sdp_bram
            (
             .wrclock       (wclk),
             .wren          (i_we),
             .wraddress     (i_addr),
             .data          (i_di),
             .rdclock       (rclk),
             .rdaddress     (radd),
             .q             (wire_rdat)
             );
        end
    else if ((G_FAMILY == "XILINX") & (G_TYPE == "LUT"))
        begin: gen_xil_sdp_lutram
        xil_sdp_lutram     
            #(
              .G_ADDR       (G_WRADDR),
              .G_WIDTH      (G_WRWIDTH),
              .G_DEPTH      (G_WRDEPTH),
              .G_DEVICE     (G_DEVICE),
              .X_PIPELINE   (X_PIPELINELUT)
              ) i_xil_sdp_lutram
            (
             .clk           (wclk),
             .we            (i_we),
             .a             (i_addr),
             .d             (i_di),
             .qdpo_clk      (rclk),
             .dpra          (radd),
             .qdpo          (wire_rdat)
             );
        end
    else if ((G_FAMILY == "ALTERA") & (G_TYPE == "LUT") & (A_BRAM_TYPE == "LC"))
        begin: gen_alt_sdp_lutram_lc
        alt_sdp_lutram_lc
            #(
              .G_ADDR       (G_WRADDR),
              .G_WIDTH      (G_WRWIDTH),
              .G_DEPTH      (G_WRDEPTH),
              .G_DEVICE     (G_DEVICE),
              .A_REG_EN     (A_REG_EN)
              ) i_alt_sdp_lutram_lc
            (
             .wrclock       (wclk),
             .wren          (i_we),
             .wraddress     (i_addr),
             .data          (i_di),
             .rdclock       (rclk),
             .rdaddress     (radd),
             .q             (wire_rdat)
             );
        end
    else if ((G_FAMILY == "ALTERA") & (G_TYPE == "LUT") & (A_BRAM_TYPE == "MLAB"))
        begin: gen_alt_sdp_lutram_mlab
        alt_sdp_lutram_mlab
            #(
              .G_ADDR       (G_WRADDR),
              .G_WIDTH      (G_WRWIDTH),
              .G_DEPTH      (G_WRDEPTH),
              .G_DEVICE     (G_DEVICE),
              .A_REG_EN     (A_REG_EN),
              .A_INIT_FILE  (A_INIT_FILE)
              ) i_alt_sdp_lutram_mlab
            (
             .wrclock       (wclk),
             .wren          (i_we),
             .wraddress     (i_addr),
             .data          (i_di),
             .rdclock       (rclk),
             .rdaddress     (radd),
             .q             (wire_rdat)
             );
        end
    else // (G_TYPE == "INFER")
        begin: gen_sdp_bram_inf
        sdp_bram_inf
            #(
              .ADDR         (G_WRADDR),
              .WIDTH        (G_WRWIDTH)
              ) i_sdp_bram_inf
             (
              .clka         (wclk), 
              .wea          (i_we),
              .addra        (i_addr),
              .dia          (i_di),
              .clkb         (rclk),
              .addrb        (radd),
              .dob          (wire_rdat)
              );
        end
    end
endgenerate

s_fflopnx #(G_RDWIDTH,G_RST_VAL,DELAY_CTRL) pl_wire_rdat(rclk, rst_n, wire_rdat, rdat);

endmodule 
