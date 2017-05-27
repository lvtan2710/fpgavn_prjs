////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : fifocvrt.v
// Description  : This is the macro of asynchronous FIFO to convert data between
// 2 clock domain.
//  + Using Gray code Counter to handle the write/read pointer
//  + Do an asynchronous comparison of pointers to generate the full & empty 
// status
//  + Embedded the dual port ram inside of FIFO..
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:38:59 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module fifocvrt
    (
     // Write 
     wclk,
     wrst_n,
     wren,
     wdata,
     wfull,

     // Read
     rclk,
     rrst_n,
     rden,
     rdata,
     rempty
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDW = 4;
parameter           DATW = 8;
parameter           TYPE = "INFER"; // Memory type: INFER, BLOCK, LUT
parameter           DELAY = 1;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
// Write
input               wclk;
input               wrst_n;
input               wren;
input [DATW-1:0]    wdata;
output              wfull;

// Read
input               rclk;
input               rrst_n;
input               rden;
output [DATW-1:0]   rdata;
output              rempty;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [ADDW-1:0]     wptr;
wire [ADDW-1:0]     rptr;
wire [ADDW-1:0]     waddr;
wire [ADDW-1:0]     raddr;

wire                afull_n;
wire                aempty_n;

async_cmp #(ADDW) async_cmp
    (
     .wrst_n        (wrst_n),
     .wptr          (wptr),
     .rptr          (rptr),
     .afull_n       (afull_n),
     .aempty_n      (aempty_n)
     );

rptr_empty #(ADDW) rptr_empty
    (
     .rclk          (rclk),
     .rrst_n        (rrst_n),
     .rden          (rden),
     .rptr          (rptr),
     .aempty_n      (aempty_n),
     .rempty        (rempty)
     );

wptr_full #(ADDW) wptr_full
    (
     .wclk          (wclk),
     .wrst_n        (wrst_n),
     .wren          (wren),
     .wptr          (wptr),
     .afull_n       (afull_n),
     .wfull         (wfull)
     );

fifomem #(ADDW, DATW, TYPE, DELAY) fifomem
    (
     // Write
     .clk           (wclk),
     .rst_n         (wrst_n),
     .wren          (wren),
     .wadd          (wptr),
     .wdata         (wdata),

     // Read
     .radd          (rptr),
     .rdata         (rdata)
     );

endmodule 
