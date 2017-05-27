////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : up_ramcfg_2r0w3x.v
// Description  : This is macro of configuration ram with these features:
//  + 2 ports read for logic engine
//  + CPU interface with up protocol
//  + External memory interface with rtlmem_2rw3x
//  + Read done after 3 clock cycle
//  + Having arbitration for engine_0 with CPU @ port A of external memory:
//      - up_ra # eng0_ra --> engine_0 priority first, cpu wait
//      - up_ra = eng0_ra --> both read ok, updo <= memdo_a
//      - up_wa = eng0_ra --> anti-conflict @ stage0, eng0_rdd <= updi3
//  + Engine_1 have full access to port B of external memory & anti conflict
//    with CPU:
//      - up_wa = eng1_ra --> anti-conflict @ stage0, eng1_rdd <= updi3
// Note:
//  + Engine active enable must have an AND logic outside of this macro.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:59:14 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module up_ramcfg_2r0w3x
    (
     clk,
     rst_n,

     // Engine Interface
     eng0_re,    // clk 0
     eng0_ra,
     eng0_rdd,   // clk 3

     eng1_re,    // clk 0
     eng1_ra,
     eng1_rdd,   // clk 3

     // CPU Interface
     upen,
     upa,
     upws,
     uprs,
     updi,
     updo,
     uprdy,
     
     // Memory Interface
     omemwe_a,
     omemad_a,
     omemdi_a,
     imemdo_a,
     
     omemwe_b,
     omemad_b,
     omemdi_b,
     imemdo_b
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
input                   eng0_re;
input [G_ADDR-1:0]      eng0_ra;
output [G_WIDTH-1:0]    eng0_rdd;

input                   eng1_re;
input [G_ADDR-1:0]      eng1_ra;
output [G_WIDTH-1:0]    eng1_rdd;

// CPU Interface
input                   upen;
input [G_ADDR-1:0]      upa;
input                   upws;
input                   uprs;
input [G_WIDTH-1:0]     updi;
output [G_WIDTH-1:0]    updo;
output                  uprdy;

// Memory Interface
output                  omemwe_a;
output [G_ADDR-1:0]     omemad_a;
output [G_WIDTH-1:0]    omemdi_a;
input [G_WIDTH-1:0]     imemdo_a;

output                  omemwe_b;
output [G_ADDR-1:0]     omemad_b;
output [G_WIDTH-1:0]    omemdi_b;
input [G_WIDTH-1:0]     imemdo_b;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire                    cpuwr, cpurd;
assign                  cpuwr = upen & upws;
assign                  cpurd = upen & uprs;

wire                    cpuwr_ok, cpurd_ok;
wire                    cpu_access_ok;
assign                  cpu_access_ok = cpuwr_ok | cpurd_ok;

wire                    nxt_cpurd_lat, cur_cpurd_lat;
assign                  nxt_cpurd_lat = (!upen    ? 1'b0 :                  // when CPU time out force deassert cpurd latch
                                         cpurd_ok ? 1'b0 :                  // cpurd_ok force deassert cpurd latch
                                         cpurd    ? 1'b1 : cur_cpurd_lat);  // assert cpurd latch when cpurd & (cpu_ra # eng_ra)

wire                    nxt_cpuwr_lat, cur_cpuwr_lat;
assign                  nxt_cpuwr_lat = (!upen    ? 1'b0 :                  // when CPU time out force deassert cpuwr latch
                                         cpuwr_ok ? 1'b0 :                  // cpuwr_ok force deassert cpuwr latch
                                         cpuwr    ? 1'b1 : cur_cpuwr_lat);  // assert cpuwr latch when cpuwr & (cpu_ra # eng_ra)

s_pl_reg #(2)           gen_cpurdwr_lat(clk, rst_n, {nxt_cpurd_lat, nxt_cpuwr_lat},
                                                    {cur_cpurd_lat, cur_cpuwr_lat});

wire                    cpurd_lat, cpuwr_lat;
assign                  cpurd_lat = cur_cpurd_lat;
assign                  cpuwr_lat = cur_cpuwr_lat;

assign                  cpuwr_ok = (cpuwr | cpuwr_lat) & ((!eng0_re) | (eng0_ra == upa));
assign                  cpurd_ok = (cpurd | cpurd_lat) & ((!eng0_re) | (eng0_ra == upa));

//------------------------------------------------------------------------------
// Port A External memory process

// Write controller
assign                  omemwe_a = cpuwr_ok;
assign                  omemdi_a = updi;

// read controller
wire                    wr0_conflict;
generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK"))
        begin
        assign          wr0_conflict = 1'b0;
        assign          eng0_rdd     = imemdo_a;
        end
    else
        begin: gen_wr0conflict
        assign          wr0_conflict = cpuwr_ok & eng0_re & (eng0_ra == upa);
        
        wire            wr0_conflict_p1, wr0_conflict_p2, wr0_conflict_p3;
        s_pl_reg #(3)   ppl_wr0_conflict(clk, rst_n, {wr0_conflict   , wr0_conflict_p1, wr0_conflict_p2},
                                                     {wr0_conflict_p1, wr0_conflict_p2, wr0_conflict_p3});
        assign          eng0_rdd = wr0_conflict_p3 ? updi : imemdo_a;
        end
    end
endgenerate

assign                  omemad_a = eng0_re ? eng0_ra : upa;

//------------------------------------------------------------------------------
// Port B External memory process

// Write controller
assign                  omemwe_b = 1'b0;
assign                  omemdi_b = {G_WIDTH{1'b0}};

// read controller
wire                    wr1_conflict;
generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK"))
        begin
        assign          wr1_conflict = 1'b0;
        assign          eng1_rdd     = imemdo_b;
        end
    else
        begin: gen_wr1conflict
        assign          wr1_conflict = cpuwr_ok & eng1_re & (eng1_ra == upa);
        
        wire            wr1_conflict_p1, wr1_conflict_p2, wr1_conflict_p3;
        s_pl_reg #(3)   ppl_wr1_conflict(clk, rst_n, {wr1_conflict   , wr1_conflict_p1, wr1_conflict_p2},
                                                     {wr1_conflict_p1, wr1_conflict_p2, wr1_conflict_p3});
        assign          eng1_rdd = wr1_conflict_p3 ? updi : imemdo_b;
        end
    end
endgenerate

assign                  omemad_b = eng1_ra;
    
//------------------------------------------------------------------------------
// Return Data for CPU
wire                    cpu_access_ok_p1, cpu_access_ok_p2, cpu_access_ok_p3;
s_pl_reg #(3)           ppl_cpu_access_ok(clk, rst_n, {cpu_access_ok,    cpu_access_ok_p1, cpu_access_ok_p2},
                                                      {cpu_access_ok_p1, cpu_access_ok_p2, cpu_access_ok_p3});

assign                  uprdy = cpu_access_ok_p3;
assign                  updo  = imemdo_a;

endmodule 
