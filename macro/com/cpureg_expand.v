////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : cpureg_expand.v
// Description  : This macro is used to help cpu can access registers which has
// the larger size than 32bits. Module is using indirect mechanism to access.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:17:30 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module cpureg_expand
    (
     clk,
     rst_n,

     // CPU interface for hold registers
     hold_pen, //LSB is for hold #0
     upws,
     uprs,
     updi,
     uprdy,
     updo,  

     // cpu bus expansion interface
     // connect to internal expansion cpu bus
     updi_e,
     uprdy_e,
     updo_e
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter               BUSWIDTH = 128; //MUST > 32

parameter               BUSB = (BUSWIDTH > ((BUSWIDTH/32)*32))? (BUSWIDTH/32) : (BUSWIDTH/32 -1);

parameter               HOLDW    = BUSWIDTH - 32;
parameter               HOLDWTMP = BUSB*32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;

input [BUSB-1:0]        hold_pen;
input                   upws;
input                   uprs;
input [31:0]            updi;
output                  uprdy;
output [31:0]           updo;

output [BUSWIDTH-1:0]   updi_e;
input                   uprdy_e;
input [BUSWIDTH-1:0]    updo_e;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

reg [HOLDW-1:0]        hold_reg;
integer                i,j;

reg [HOLDWTMP-1:0]     hold_tmp1;
always @ (hold_pen or updi or hold_reg)
    begin
    hold_tmp1 = hold_reg;   
    for (i=0;i<BUSB;i=i+1)
        begin
        if (hold_pen[i])
            begin
            for (j=0;j<32;j=j+1) hold_tmp1[i*32+j] = updi[j];
            end
        end
    end

wire uprs_l;
s_lat_reg #(1) flxuprs_l 
    (clk, rst_n, uprs||upws||uprdy, (uprdy ? 1'b0 : uprs), uprs_l);

wire uprs_en = uprs_l || uprs;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n) hold_reg <= {HOLDW{1'b0}};
    else
        begin
        if (uprdy_e && uprs_en) hold_reg <= updo_e[BUSWIDTH-1:32];
        else if ((|hold_pen) & upws)
            begin
            hold_reg <= hold_tmp1;          
            end
        else hold_reg <= hold_reg;      
        end
    end

wire [BUSWIDTH-1:0]   updi_e;
assign                updi_e        = {hold_reg,updi};

wire                  uprdy_hold;
assign                uprdy_hold    = (|hold_pen) & (upws|uprs);

wire [HOLDWTMP-1:0]   hold_tmp2     = hold_reg;

reg [31:0]            updo_hold;
always @ (hold_pen or hold_tmp2)
    begin
    updo_hold = 32'd0;
    if (|hold_pen)
        begin
        for (i=0;i<BUSB;i=i+1)
                begin
                if (hold_pen[i])
                    begin
                    for (j=0;j<32;j=j+1) updo_hold[j] = hold_tmp2[i*32+j];
                    end
                end
        end    
    end

wire                  uprdy;
wire [31:0]           updo;

assign                uprdy = uprdy_hold | uprdy_e;

assign                updo  = (|hold_pen) ? updo_hold : updo_e[31:0];

endmodule 
