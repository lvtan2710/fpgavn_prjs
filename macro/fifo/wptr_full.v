////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : wptr_full.v
// Description  : .
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:36:28 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module wptr_full
    (
     wclk,
     wrst_n,
     wren,
     wptr,
     afull_n,
     wfull
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter           ADDW = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               wclk;
input               wrst_n;
input               wren;
output [ADDW-1:0]   wptr;
input               afull_n;
output              wfull;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDW-1:0]      wptr, wbin;
reg                 wfull, wfull2;
wire [ADDW-1:0]     wgnext, wbnext;

//------------------------------------------------------------------------------
// Gray pointer
always @(posedge wclk or negedge wrst_n)
    begin
    if (!wrst_n)
        begin
        wbin <= 0;
        wptr <= 0;
        end
    else
        begin
        wbin <= wbnext;
        wptr <= wgnext;
        end
    end

//------------------------------------------------------------------------------
// Increment the binary count if not full
assign wbnext = (!wfull) ? (wbin + wren) : wbin;
assign wgnext = (wbnext>>1) ^ wbnext;           // Binary to gray conversion

always @(posedge wclk or negedge wrst_n or negedge afull_n)
    begin
    if (!wrst_n)        {wfull, wfull2} <= 2'b00;
    else if (!afull_n)  {wfull, wfull2} <= 2'b11;
    else                {wfull, wfull2} <= {wfull2, ~afull_n};
    end

endmodule 
