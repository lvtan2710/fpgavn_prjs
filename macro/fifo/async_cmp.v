////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : async_cmp.v
// Description  : This is asynchronous comparison module,
//  + used to compare read and write pointers to detect full & empty condition..
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:40:01 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module async_cmp
    (
     wrst_n,
     wptr,
     rptr,
     afull_n,
     aempty_n
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter   ADDW = 4;
parameter   N = ADDW-1;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input       wrst_n;
input [N:0] wptr;
input [N:0] rptr;
output      afull_n;
output      aempty_n;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg         direction;
wire        high = 1'b1;

wire        dirset_n;
assign      dirset_n = ~(   (wptr[N]^rptr[N-1]) & ~(wptr[N-1:0]^rptr[N]));
wire        dirclr_n;
assign      dirclr_n = ~((~(wptr[N]^rptr[N-1:0]) & (wptr[N-1]^rptr[N])) | ~wrst_n);

always @(posedge high or negedge dirset_n or negedge dirclr_n)
    begin
    if      (!dirclr_n) direction <= 1'b0;
    else if (!dirset_n) direction <= 1'b1;
    else                direction <= high;
    end

assign aempty_n = ~((wptr == rptr) && !direction);
assign afull_n  = ~((wptr == rptr) && direction);

endmodule 
