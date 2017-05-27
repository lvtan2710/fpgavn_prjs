////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : fifoflush.v
// Description  : This module is the FIFO Controller with flushing which handles
// the write, read pointers, status signals such as full, empty. The memory of
// FIFO is outside which connect directly with this controller.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:38:40 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module fifoflush
    (
     clk,
     rst_n,

     // FIFO Control Interface
     fiford,
     fifowr,
     fifoflsh,
     fifofull,
     notempty,
     fifolen,

     // FIFO Memory Interface
     mem_wr,
     mem_wa,
     mem_rd,
     mem_ra
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDR = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;

// FIFO Control Interface
input               fiford;
input               fifowr;
input               fifoflsh;
output              fifofull;
output              notempty;
output [ADDR:0]     fifolen;

// FIFO Memory Interface
output              mem_wr;
output [ADDR-1:0]   mem_wa;
output              mem_rd;
output [ADDR-1:0]   mem_ra;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDR:0]        fifo_len;
reg [ADDR-1:0]      wrcnt;
wire [ADDR-1:0]     rdcnt;

wire                fifoempt;
assign              fifoempt = (fifo_len == {1'b0, {ADDR{1'b0}}});
assign              notempty = (!fifoempt);

assign              fifofull = fifo_len[ADDR];
assign              fifolen  = fifo_len;

assign              mem_wr   = fifowr & (!fifofull);
assign              mem_rd   = fiford & notempty;

assign              rd_cnt   = wr_cnt - fifo_len[ADDR-1:0];
assign              mem_ra   = rd_cnt;

always @(posedge clk)
    begin
    if (!rst_)          wr_cnt <= {ADDR{1'b0}};
    else if (fifoflsh)  wr_cnt <= {ADDR{1'b0}};
    else if (mem_wr)    wr_cnt <= wr_cnt  + 1'b1;
    end

always @(posedge clk)
    begin
    if (!rst_)          fifo_len  <= {1'b0,{ADDR{1'b0}}};
    else if (fifoflsh)  fifo_len  <= {1'b0,{ADDR{1'b0}}};
    else
        case({mem_rd, mem_wr})
            2'b01: fifo_len <= fifo_len + 1'b1;
            2'b10: fifo_len <= fifo_len - 1'b1;
            default: fifo_len <= fifo_len;
        endcase
    end
                    
endmodule 
