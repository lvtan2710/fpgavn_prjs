////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rptr_empty.v
// Description  : .
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:36:56 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rptr_empty
    (
     rclk,
     rrst_n,
     rden,
     rptr,
     aempty_n,
     rempty
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDW = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               rclk;
input               rrst_n;
input               rden;
output [ADDW-1:0]   rptr;
input               aempty_n;
output              rempty;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDW-1:0]      rptr;
reg [ADDW-1:0]      rbin;
reg                 rempty, rempty2;
wire [ADDW-1:0]     rgnext, rbnext;

//------------------------------------------------------------------------------
// Gray pointer
always @(posedge rclk or negedge rrst_n)
    begin
    if (!rrst_n)
        begin
        rbin <= 0;
        rptr <= 0;
        end
    else
        begin
        rbin <= rbnext;
        rptr <= rgnext;
        end
    end

//------------------------------------------------------------------------------
// Increment the binary count if not empty
assign rbnext = !rempty ? (rbin + rden) : rbin;
assign rgnext = (rbnext>>1) ^ rbnext;           // Binary to gray conversion

always @(posedge rclk or negedge aempty_n)
    begin
    if (!aempty_n) {rempty, rempty2} <= 2'b11;
    else           {rempty, rempty2} <= {rempty2, ~aempty_n};
    end

endmodule 
