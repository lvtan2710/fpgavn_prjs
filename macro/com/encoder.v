////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : encoder.v
// Description  : This is the encoder from a bitmap to a number.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:15:53 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module encoder
    (
     ena,
     bitmap,
     number
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter         NUMW = 4;
parameter         BITW = 2**NUMW;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input             ena;
input [BITW-1:0]  bitmap;
output [NUMW-1:0] number;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
integer           i;
reg [NUMW-1:0]    number;
always @(ena or bitmap)
    begin
    number = {NUMW{1'b0}};
    if (ena)
        begin
        for (i = 0; i < BITW; i = i + 1)
            number = bitmap[i] ? i[NUMW-1:0] : number;
        end
    end

endmodule 
