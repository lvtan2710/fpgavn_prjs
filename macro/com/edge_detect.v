////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : edge_detect.v
// Description  : This macro is used for detect the rising edge or falling edge 
// of a signal.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:16:33 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module edge_detect
    (
     clk,
     rst_n,
     signal,
     o_edge
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_EDGE_TYPE = "RISING";   // RISING, FALLING

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input     clk;
input     rst_n;
input     signal;
output    o_edge;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg       signal1;
always @(posedge clk)
    begin
    if (!rst_n) signal1 <= 1'b0;
    else        signal1 <= signal;
    end

generate
if (G_EDGE_TYPE == "RISING")
    begin
    assign o_edge = (signal & !signal1);
    end
else // (G_EDGE_TYPE == "FALLING")
    begin
    assign o_edge = (!signal & signal1);
    end
endgenerate

endmodule 
