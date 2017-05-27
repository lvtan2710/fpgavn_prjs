////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : ram_rst_ctrl.v
// Description  : .
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:55:57 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module ram_rst_ctrl
    (
     clk,
     rst_n,
     clrena,
     clrrdy,
     clrwe,
     clraddr
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter G_ADDR  = 8;
parameter G_DEPTH = {1'b1, {G_ADDR{1'b0}}};

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input               clrena;
output              clrrdy;
output              clrwe;
output [G_ADDR-1:0] clraddr;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [G_ADDR-1:0]    count;
always @(posedge clk)
    begin
    if (!rst_n)         count <= {G_ADDR{1'b0}};
    else if (clrena)    count <= {G_ADDR{1'b0}};
    else                count <= clrrdy ? count : count + 1'b1;
    end

assign clraddr = count;

reg    clrwe;
always @(posedge clk)
    begin
    if (!rst_n)         clrwe <= 1'b0;
    else if (clrena)    clrwe <= 1'b1;
    else                clrwe <= (count == G_DEPTH-1) ? 1'b0 : clrwe;
    end

assign clrrdy = !clrwe;

endmodule 
