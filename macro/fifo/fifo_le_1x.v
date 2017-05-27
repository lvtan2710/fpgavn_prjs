////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : fifo_le_1x.v
// Description  :This is a normal FIFO module:
//  + the memory is implemented by LE
//  + read, write after 1 clock cycle
//  + support informations: fifo length, fifo flush, full, empty.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:39:40 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module fifo_le_1x
    (
     clk,
     rst_n,

     fifoflsh,
     fifowr,
     fifodin,
     fiford,
     fifodout,
     
     //Status
     fifolen,
     fifofull,
     fifoempt,
     notempty
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDR = 4;
parameter           WIDTH = 8;
parameter           LENGTH = 2**ADDR;
parameter           NOLATCH = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;

input               fifoflsh;
input               fifowr;
input [WIDTH-1:0]   fifodin;
input               fiford;
output [WIDTH-1:0]  fifodout;

// Status
output [ADDR-1:0]   fifolen;
output              fifofull;
output              fifoempt;
output              notempty;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [WIDTH-1:0] memfifo [LENGTH-1:0];
reg [ADDR:0]    fifo_len;
reg [ADDR-1:0]  wr_cnt;

assign          fifolen = fifo_len;

wire            fifoempt;
assign          fifoempt = (fifo_len == {1'b0, {ADDR{1'b0}}});
assign          notempty = (!fifoempt);

wire            fifofull;
assign          fifofull = fifo_len[ADDR];

wire            wrstrobe;
assign          wrstrobe = fifowr & (!fifofull);

wire            rdstrobe;
assign          rdstrobe = fiford & notempty;

wire [ADDR-1:0] rd_cnt;
assign          rd_cnt = wr_cnt - fifo_len[ADDR-1:0];

integer     i;
always @(posedge clk)
    begin
    if(!rst_n) for(i=0; i<LENGTH; i=i+1) memfifo[i] <= {WIDTH{1'b0}};
    else if(wrstrobe) memfifo[wr_cnt] <= fifodin;
    end

always @(posedge clk)
    begin
    if(!rst_n)          wr_cnt <= {ADDR{1'b0}};
    else if(wrstrobe)   wr_cnt    <= wr_cnt  + 1'b1;
    end

always @(posedge clk)
    begin
    if(!rst_n) fifo_len  <= {1'b0,{ADDR{1'b0}}};
    else if (fifoflsh)
        fifo_len <= {1'b0,{ADDR{1'b0}}};
    else
        case({rdstrobe,wrstrobe})
            2'b01: fifo_len <= fifo_len + 1'b1;
            2'b10: fifo_len <= fifo_len - 1'b1;
            default: fifo_len <= fifo_len;
        endcase
    end

reg [WIDTH-1:0]  fifodout;
always @(posedge clk)
    begin
    if(!rst_n)          fifodout <= {WIDTH{1'b0}};
    else if (rdstrobe)  fifodout <= memfifo[rd_cnt];
    else if (NOLATCH)   fifodout <= {WIDTH{1'b0}};
    end

endmodule 
