////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : decoder.v
// Description  : This is the decoder from a number to a bitmap.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:17:09 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module decoder
    (
     ena,
     number,
     bitmap
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter         NUMW = 4;
parameter         BITW = 2**NUMW;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input             ena;
input [NUMW-1:0]  number;
output [BITW-1:0] bitmap;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [BITW-1:0]    bitmap;
always @(ena or number)
    begin
    bitmap     = {BITW{1'b0}};
    if (ena)
        bitmap[number] = 1'b1;
    end

endmodule 
