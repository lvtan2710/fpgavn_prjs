////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : fwft_fifox.v
// Description  : This module is First Word Fall Through FIFO.
// The difference between standard FIFO and FWFT FIFO are the first byte
// written into the FIFO immediately appears on the output. Allowing you to
// read the first byte without pulsing the Read Enable signal first..
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:37:10 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module fwft_fifox
    (
     clk,
     rst_n,
     fifowr,
     fifodin,
     fiford,
     fifodout,
     notempty,
     fifofull
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDR  = 4;
parameter           WIDTH = 8;
parameter           DEPTH = 2**ADDR;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input               fifowr;
input [WIDTH-1:0]   fifodin;
input               fiford;
output [WIDTH-1:0]  fifodout;
output              notempty;
output              fifofull;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [WIDTH-1:0]     memfifo[DEPTH-1:0];
reg [ADDR:0]        fifo_len;
reg [ADDR-1:0]      wr_cnt;

wire                fifoempt;
assign              fifoempt = (fifo_len == {1'b0, {ADDR{1'b0}}});
assign              notempty = (!fifoempt);

wire                fifo_full;
assign              fifo_full = fifo_len[ADDR];
assign              fifofull = fifo_full;

wire [ADDR-1:0]     rd_cnt;
assign              rd_cnt = wr_cnt - fifo_len[ADDR-1:0];

wire                wrstrobe, rdstrobe;
assign              wrstrobe = fifowr & (!fifo_full);
assign              rdstrobe = fiford & notempty;

always @(posedge clk)
    begin
    if (!rst_n)         wr_cnt <= {ADDR{1'b0}};
    else if (wrstrobe)  wr_cnt <= wr_cnt + 1'b1;
    end

always @(posedge clk)
    begin
    if (!rst_n)     fifo_len <= {1'b0, {ADDR{1'b0}}};
    else
        case {rdstrobe, wrstrobe}
            2'b01:  fifo_len <= fifo_len + 1'b1;
            2'b10:  fifo_len <= fifo_len - 1'b1;
            default: fifo_len <= fifo_len;
        endcase
    end

integer     i;
always @(posedge clk)
    begin
    if(!rst_n) for(i=0; i<DEPTH; i=i+1) memfifo[i] <= {WIDTH{1'b0}};
    else if (wrstrobe) memfifo[wr_cnt] <= fifodin;
    end

assign fifodout = memfifo[rd_cnt];

endmodule 
