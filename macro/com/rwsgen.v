////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rwsgen.v
// Description  : This macro is read write strobe generator compatible with
// Avalon & AXI interface. This module will assert 1 cycle clock for read/write 
// signal.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:11:34 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rwsgen
    (
     clk,
     rst_n,

     // AXI/Avalon Interface
     write,
     read,

     // Microprocessor Interface
     uprdy,
     upen_ws,
     upen_rs,
     upws,
     uprs
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input       clk;
input       rst_n;

// AXI/Avalon Interface
input       write;
input       read;

// Microprocessor Interface
input       uprdy;
output      upen_ws;
output      upen_rs;
output      upws;
output      uprs;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

wire        write1, read1;
s_pl_reg #(2) pl_rdwr(clk, rst_n, {write, read}, {write1, read1});

reg         rd_busy;
always @(posedge clk)
    begin
    if (!rst_n) rd_busy <= 1'b0;
    else        rd_busy <= (uprdy ? 1'b0 :
                            read  ? 1'b1 : rd_busy);
    end

reg         wr_busy;
always @(posedge clk)
    begin
    if (!rst_n) wr_busy <= 1'b0;
    else        wr_busy <= (uprdy  ? 1'b0 :
                            write  ? 1'b1 : wr_busy);
    end

wire        rd_busy1, wr_busy1;
s_pl_reg #(2) pl_rdwrbusy(clk, rst_n, {rd_busy, wr_busy}, {rd_busy1, wr_busy1});

wire        rise_rd_busy, rise_wr_busy;
assign      rise_rd_busy = rd_busy & (~rd_busy1);
assign      rise_wr_busy = wr_busy & (~wr_busy1);

assign      upws = rise_wr_busy & write1;
assign      uprs = rise_rd_busy & read1;

assign      upen_ws = (wr_busy | wr_busy1);
assign      upen_rs = (rd_busy | rd_busy1);

endmodule 
