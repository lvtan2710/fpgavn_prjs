////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : a_dff_nclk.v
// Description  : This module is asynchronous D-flipflop which output is presented  
// after n clock delay.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:34:03 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module a_dff_nclk
    (
     clk,
     rst_n,
     d0,
     qn
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DELAY = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input     clk;
input     rst_n;
input     d0;
output    qn;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

generate
    begin
    if (DELAY == 0)
        begin
        assign qn = d0;
        end
    else if (DELAY == 1)
        begin
        wire shift;
        a_dff #(0) pl_shift(clk, rst_n, d0, shift);
        assign qn = shift;
        end
    else
        begin
        wire [DELAY-1:0] shift;
        a_pl_reg #(DELAY) pl_shift(clk, rst_n, {shift[DELAY-2:0], d0}, shift);
        assign qn = shift[DELAY-1];
        end
    end
endgenerate

endmodule 
