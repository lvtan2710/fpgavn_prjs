////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : rst_sync.v
// Description  : This macro is used to synchronize the asynchronous reset input.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:12:48 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module rst_sync
    (
     clk,       // destination clock
     i_rst_n,   // asynchronous reset input
     o_rst_n    // synchronous reset input
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
// delay between the de-assertion of the asynchronous and synchronous resets
parameter G_DELAY_CYCLES = 2;   // delay must be >=2 to prevent metastable output

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input     clk;
input     i_rst_n;
output    o_rst_n;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [G_DELAY_CYCLES-1:0] reset;

always @(posedge clk or negedge i_rst_n)
    begin
    if (!i_rst_n)   reset <= {G_DELAY_CYCLES{1'b0}};
    else            reset <= {reset[G_DELAY_CYCLES-2:0], 1'b1};
    end

assign o_rst_n = reset[G_DELAY_CYCLES-1];

endmodule 
