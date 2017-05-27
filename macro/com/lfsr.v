////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : lfsr.v
// Description  : .
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:15:29 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module lfsr
    (
     clk,
     rst_n,
     ena,
     idat,
     odat
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DATW      = 8;        // Size of bus data in and out
parameter POLYLEN   = 5'd31;    // length of the polynomial (= number of shift register stages)
parameter POLYTAP   = 5'd28;    // intermediate stage that is xor-ed with the last stage to generate to next prbs bit
parameter CHK_MODE  = 0;        // 0: generate, 1: monitor

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
input               ena;
input  [DATW-1:0]   idat;
output [DATW-1:0]   odat;

reg [DATW-1:0]      odat;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [1:POLYLEN]     prbs_reg = {POLYLEN{1'b1}};
wire [1:POLYLEN]    prbs_pat[DATW:0];
wire [DATW-1:0]     xor_a, xor_b;
wire [DATW:1]       prbs_msb;

assign              prbs_pat[0] = prbs_reg;

genvar i;
generate for (i = 0; i < DATW; i = i + 1)
    begin
    assign xor_a[i] = prbs_pat[i][POLYTAP] ^ prbs_pat[i][POLYLEN];  // iprbs[POLYTAP] ^ iprbs[POLYLEN]
    assign xor_b[i] = xor_a[i] ^ idat[i];   // insert error or check data
    assign prbs_msb[i+1] = (CHK_MODE == 0) ? xor_a[i] : idat[i];
    assign prbs_pat[i+1] = {prbs_msb[i+1], prbs_pat[i][1:POLYLEN-1]};
    end
endgenerate

always @(posedge clk)
    begin
    if (!rst_n)
        begin
        odat        <= {DATW{1'b1}};
        prbs_reg    <= {POLYLEN{1'b1}};
        end
    else if (ena)
        begin
        odat        <= xor_b;
        prbs_reg    <= prbs_pat[DATW];
        end
    end

endmodule 
