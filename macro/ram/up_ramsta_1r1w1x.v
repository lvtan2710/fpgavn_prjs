////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : up_ramsta_1r1w1x.v
// Description  : This is macro of status ram with these features:
//  + 1 port read, 1 port write for logic engine
//  + CPU interface with up protocol
//  + External memory interface with rtlmem_1r1w1x
//  + Read& write done after 1 clock cycle
//  + Having arbitration for:
//      1 up_ra # eng_ra # eng_wa --> 2 engine priority first, cpu wait
//      2 up_wa # eng_ra # eng_wa --> 2 engine priority first, cpu wait
//      3 up_wa = eng_ra # eng_wa --> 2 engine priority first, cpu wait
//      4 up_ra = eng_ra # eng_wa --> cpu read ok, engine read ok
//      5 up_wa = eng_wa # eng_ra --> cpu write ok, engine not write, read ok
//      6 up_ra = eng_wa # eng_ra --> engine read & write ok, cpu wait
//
//      7 up_ra # eng_wa = eng_ra --> anti-conflict, eng_rdd <= eng_wrd,cpu wait
//      8 up_wa # eng_wa = eng_ra --> anti-conflict, eng_rdd <= eng_wrd,cpu wait
//      9 up_wa = eng_wa = eng_ra or
//     10 up_wa = eng_ra = eng_wa --> cpu write ok, engine not write, 
//                                    anti-conflict, eng_rdd <= updi
//     11 up_ra = eng_wa = eng_ra or
//     12 up_ra = eng_ra = eng_wa --> cpu read ok, not read mem & 
//                                    anti-conflict, updo = eng_rdd <= eng_wrd
//
// Note:
//  + Engine active enable must have an AND logic outside of this macro.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:58:56 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module up_ramsta_1r1w1x
    (
     clk,
     rst_n,

     // Engine Interface
     eng_we,    // clk 0
     eng_wa,
     eng_wrd,
     
     eng_re,    // clk 0
     eng_ra,
     eng_rdd,   // clk 1

     // CPU Interface
     upen,
     upa,
     upws,
     uprs,
     updi,
     updo,
     uprdy,
     
     // Memory Interface
     omemwe,
     omemwa,
     omemdi,
     omemre,
     omemra,
     imemdo
     );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter               G_FAMILY = `FPGA_FAMILY;     // XILINX, ALTERA
parameter               G_DEVICE = `FPGA_DEVICE;     // zynq, 7series, virtex7, kintex7, artix7,
                                                     // Cyclone V
parameter               G_TYPE   = "BLOCK";  // INFER, BLOCK, LUT

parameter               G_ADDR  = 10;
parameter               G_WIDTH = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;

// Engine Interface
input                   eng_we;
input [G_ADDR-1:0]      eng_wa;
input [G_WIDTH-1:0]     eng_wrd;

input                   eng_re;
input [G_ADDR-1:0]      eng_ra;
output [G_WIDTH-1:0]    eng_rdd;

// CPU Interface
input                   upen;
input [G_ADDR-1:0]      upa;
input                   upws;
input                   uprs;
input [G_WIDTH-1:0]     updi;
output [G_WIDTH-1:0]    updo;
output                  uprdy;

// Memory Interface
output                  omemwe;
output [G_ADDR-1:0]     omemwa;
output [G_WIDTH-1:0]    omemdi;
output                  omemre;
output [G_ADDR-1:0]     omemra;
input [G_WIDTH-1:0]     imemdo;
                    
////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                    cpuwr, cpurd;
assign                  cpuwr = upen & upws;
assign                  cpurd = upen & uprs;

wire                    cpuwr_ok, cpurd_ok;
wire                    nxt_cpurd_lat, cur_cpurd_lat,
                        nxt_cpuwr_lat, cur_cpuwr_lat;
assign                  nxt_cpurd_lat = (!upen    ? 1'b0 :                  // when CPU time out force deassert cpurd latch
                                         cpurd_ok ? 1'b0 :                  // cpurd_ok force deassert cpurd latch
                                         cpurd    ? 1'b1 : cur_cpurd_lat);  // assert cpurd latch when cpurd & (cpu_ra # eng_ra)
assign                  nxt_cpuwr_lat = (!upen    ? 1'b0 :
                                         cpuwr_ok ? 1'b0 :
                                         cpuwr    ? 1'b1 : cur_cpuwr_lat);

s_dff #(0)              gen_cpurd_lat(clk, rst_n, nxt_cpurd_lat, cur_cpurd_lat);
s_dff #(0)              gen_cpuwr_lat(clk, rst_n, nxt_cpuwr_lat, cur_cpuwr_lat);

wire                    cpurd_lat, cpuwr_lat;
assign                  cpurd_lat = cur_cpurd_lat;
assign                  cpuwr_lat = cur_cpuwr_lat;

assign                  cpuwr_ok = (cpuwr | cpuwr_lat) & ((eng_wa == upa) | (!eng_we));
assign                  cpurd_ok = (cpurd | cpurd_lat) & ((eng_ra == upa) | (!eng_re));

//------------------------------------------------------------------------------
// External memory write process
wire                    ram_we;
wire [G_ADDR-1:0]       ram_wa;
wire [G_WIDTH-1:0]      ram_wdat;
assign                  ram_we   = eng_we | cpuwr_ok;
assign                  ram_wa   = cpuwr_ok ? upa  : eng_wa;    // feature 5, 10: cpu write priority than engine when both are same address
assign                  ram_wdat = cpuwr_ok ? updi : eng_wrd;

assign                  omemwe   = ram_we;
assign                  omemwa   = ram_wa;
assign                  omemdi   = ram_wdat;

//------------------------------------------------------------------------------
// External memory read process
wire                    ram_re;
wire [G_ADDR-1:0]       ram_ra;
wire [G_WIDTH-1:0]      ram_rdat;
assign                  ram_re   = eng_re | cpurd_ok;
assign                  ram_ra   = eng_re ? eng_ra : upa; // engine always priority first

wire                    ram_re1;
wire [G_ADDR-1:0]       ram_ra1;
s_pl_reg #(G_ADDR+1)    pl_ram_read(clk, rst_n, {ram_re , ram_ra },
                                                {ram_re1, ram_ra1});

//------------------------------------------------------------------------------
// Return Data for Engine
wire                    wr_conflict;

generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK")) // Because only Xilinx's Block Ram already anti-conflict at stage 0
        begin
        assign          wr_conflict = 1'b0;
        assign          ram_rdat    = imemdo;
        end
    else
        begin
        assign          wr_conflict = ram_we & (ram_wa == ram_ra);

        wire            anti_stage0;  // when current write same current read
        s_dff #(0)      ppl_anti_stage0(clk, rst_n, (wr_conflict & ram_re), anti_stage0);

        wire [G_WIDTH-1:0]  ram_wdat1;
        s_pl_reg #(G_WIDTH) pl_ram_wdat(clk, rst_n, ram_wdat, ram_wdat1);
        
        assign          ram_rdat    = (anti_stage0 ? ram_wdat1 : imemdo);
        end
    end
endgenerate
        
assign                  eng_rdd     = ram_rdat;

assign                  omemre      = ram_re & (!wr_conflict);//Engine not read when current write same current read
assign                  omemra      = ram_ra;

//------------------------------------------------------------------------------
// Return Data for CPU
wire                    cpu_access_ok;
assign                  cpu_access_ok = cpuwr_ok | cpurd_ok;

wire                    cpu_access_ok_p1;
s_dff #(0)              ppl_cpu_access_ok(clk, rst_n, cpu_access_ok, cpu_access_ok_p1);

assign                  uprdy = cpu_access_ok_p1;
assign                  updo  = ram_rdat;

endmodule 
