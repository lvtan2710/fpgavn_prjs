////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : up_ramcfg_1r0w2x.v
// Description  : This is macro of configuration ram with these features:
//  + 1 port read for logic engine
//  + CPU interface with up protocol
//  + External memory interface with rtlmem_1r1w2x
//  + Read done after 2 clock cycle
//  + Having arbitration for:
//      - up_ra # eng_ra --> engine priority first, cpu wait
//      - up_ra = eng_ra --> both read ok
//      - up_wa = eng_ra --> anti-conflict @ stage0, eng_rdd <= updi2
// Note:
//  + Engine active enable must have an AND logic outside of this macro.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 15:00:13 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module up_ramcfg_1r0w2x
    (
     clk,
     rst_n,

     // Engine Interface
     eng_re,    // clk 0
     eng_ra,
     eng_rdd,   // clk 2

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
assign                  cpuwr_ok = cpuwr;

wire                    nxt_cpurd_lat, cur_cpurd_lat;
assign                  nxt_cpurd_lat = (!upen    ? 1'b0 :                  // when CPU time out force deassert cpurd latch
                                         cpurd_ok ? 1'b0 :                  // cpurd_ok force deassert cpurd latch
                                         cpurd    ? 1'b1 : cur_cpurd_lat);  // assert cpurd latch when cpurd & (cpu_ra # eng_ra)

s_dff #(0)              gen_cpurd_lat(clk, rst_n, nxt_cpurd_lat, cur_cpurd_lat);

assign                  cpurd_lat = cur_cpurd_lat;

// CPU rd ok when:
//  + cpurd & !eng_re
//  + cpurd & eng_re & (eng_ra = cpu_ra)
//  + cpurd_lat & !eng_re
//  + cpurd_lat & eng_re & (eng_ra = cpu_ra)
assign                  cpurd_ok = (cpurd | cpurd_lat) & ((eng_ra == upa) | (!eng_re)); 

//------------------------------------------------------------------------------
// External memory write process
assign                  omemwe = cpuwr_ok;
assign                  omemwa = upa;
assign                  omemdi = updi;

//------------------------------------------------------------------------------
// External memory read process
wire                    wr_conflict;

assign                  omemre = (eng_re | cpurd_ok) & (!wr_conflict);
assign                  omemra = eng_re ? eng_ra : upa;

//------------------------------------------------------------------------------
// Return Data for Engine
// Conflict happens when CPU write & engine read at same address
generate
    begin
    if ((G_FAMILY == "XILINX") & (G_TYPE == "BLOCK"))
        begin
        assign          wr_conflict = 1'b0;
        assign          eng_rdd     = imemdo;
        end
    else
        begin: gen_wrconflict
        assign          wr_conflict = cpuwr_ok & eng_re & (eng_ra == upa);
        
        wire            wr_conflict_p1, wr_conflict_p2;
        s_dff #(0)      ppl_wr_conflict1(clk, rst_n, wr_conflict, wr_conflict_p1);
        s_dff #(0)      ppl_wr_conflict2(clk, rst_n, wr_conflict_p1, wr_conflict_p2);

        assign          eng_rdd = wr_conflict_p2 ? updi : imemdo;
        end
    end
endgenerate
    
//------------------------------------------------------------------------------
// Return Data for CPU
wire                    cpu_access_ok;
assign                  cpu_access_ok = cpuwr_ok | cpurd_ok;

wire                    cpu_access_ok_p1, cpu_access_ok_p2;
s_dff #(0)              ppl_cpu_access_ok1(clk, rst_n, cpu_access_ok, cpu_access_ok_p1);
s_dff #(0)              ppl_cpu_access_ok2(clk, rst_n, cpu_access_ok_p1, cpu_access_ok_p2);

assign                  uprdy = cpu_access_ok_p2;
assign                  updo = imemdo;

endmodule 
