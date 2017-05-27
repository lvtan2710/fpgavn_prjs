////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : fifomem.v
// Description  : This is the wrapper of Single Dual Port RAM.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:37:31 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module fifomem
    (
     // Write
     clk,
     rst_n,
     wren,
     wadd,
     wdata,

     // Read
     radd,
     rdata
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter ADDW  = 4;             // Number of memory address bits
parameter DATW  = 8;             // Memory data word width
parameter TYPE  = "BLOCK";       // INFER, BLOCK, LUT
parameter DELAY = 1;
parameter DEPTH = 1<<ADDW;       // DEPTH = 2**ADDW

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input               wren;
input [ADDW-1:0]    wadd;
input [DATW-1:0]    wdata;
input [ADDW-1:0]    radd;
output [DATW-1:0]   rdata;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

sdp_ram
    #(
      .G_TYPE           (TYPE),
      .G_WRADDR         (ADDW),
      .G_WRWIDTH        (DATW),
      .G_WRDEPTH        (DEPTH),
      .G_PIPELINE       (DELAY)
      )
i_sdp_ram
    (
     .wclk              (clk),
     .rst_n             (rst_n),
     .clr               (1'b0),
     .clrrdy            (),
     .wen               (wren),
     .wadd              (wadd),
     .wdat              (wdata),
     .rclk              (clk),
     .radd              (radd),
     .rdat              (rdata)
     );

endmodule 
