////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rise_detect.v
// Description  : This macro is used for detect the rising edge of a signal.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:13:15 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rise_detect
    (
     clk,
     rst_n,
     signal,
     o_rise
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter               WIDTH = 8;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;
input [WIDTH-1:0]       signal;
output [WIDTH-1:0]      o_rise;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [WIDTH-1:0]         signal1;
always @(posedge clk)
    begin
    if (!rst_n) signal1 <= {WIDTH{1'b0}};
    else        signal1 <= signal;
    end

assign o_rise = signal & (~signal1);

endmodule 
