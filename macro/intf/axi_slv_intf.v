////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : axi_slv_intf.v
// Description  : This is AXI4-Lite Slave Interface which convert the AXI4-Lite
//  Bus to Microprocessor Interface.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:41:45 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module axi_slv_intf
    (
     clk,
     rst_n,

     //-------------------------------------------------------------------------
     // AXI4-Lite Slave Interface
     //-------------------------------------------------------------------------
     // Write Address Channel
     s_axi_awaddr,
     s_axi_awvalid,
     s_axi_awready,
     // Write Data Channel
     s_axi_wdata,
     s_axi_wstrb,
     s_axi_wvalid,
     s_axi_wready,
     // Write Response Channel
     s_axi_bresp,
     s_axi_bvalid,
     s_axi_bready,
     // Read Address Channel
     s_axi_araddr,
     s_axi_arvalid,
     s_axi_arready,
     // Read Data Channel
     s_axi_rdata,
     s_axi_rresp,
     s_axi_rvalid,
     s_axi_rready,

     //-------------------------------------------------------------------------
     // Local Processor Interface
     //-------------------------------------------------------------------------
     upa,
     upen,
     upws,
     uprs,
     updi,
     updo,
     uprdy
     ); 

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter               AXI_ADDR        = 32;
parameter               AXI_DATW        = 32;                   // Maximum is 32
parameter               AXI_SYMBOL      = 8;
parameter               AXI_STROBE      = AXI_DATW/AXI_SYMBOL;  // This signal is not used. The AXI4 Lite assumes that all byte lanes are active.
parameter               AXI_ADBITALIGN  = fclog2(AXI_STROBE);

parameter               G_CPUA          = AXI_ADDR-AXI_ADBITALIGN;
parameter               G_CPUW          = AXI_DATW;

localparam              TIMEOUT_W       = 8;
localparam              TIMEOUT_D       = 32'hCAFE_CAFE;
localparam              BASEADD_MSB     = AXI_ADDR-1;
localparam              BASEADD_LSB     = AXI_ADBITALIGN;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;

//------------------------------------------------------------------------------
// AXI4-Lite Interface
//------------------------------------------------------------------------------
// Write Address Channel
input [AXI_ADDR-1:0]    s_axi_awaddr;
input                   s_axi_awvalid;
output                  s_axi_awready;
// Write Data Channel
input [AXI_DATW-1:0]    s_axi_wdata;
input [AXI_STROBE-1:0]  s_axi_wstrb;
input                   s_axi_wvalid;
output                  s_axi_wready;
// Write Response Channel
output [1:0]            s_axi_bresp;
output                  s_axi_bvalid;
input                   s_axi_bready;
// Read Address Channel
input [AXI_ADDR-1:0]    s_axi_araddr;
input                   s_axi_arvalid;
output                  s_axi_arready;
// Read Data Channel
output [AXI_DATW-1:0]   s_axi_rdata;
output [1:0]            s_axi_rresp;
output                  s_axi_rvalid;
input                   s_axi_rready;

//------------------------------------------------------------------------------
// Local Processor Interface
//------------------------------------------------------------------------------
output [G_CPUA-1:0]     upa;
output                  upen;
output                  upws;
output                  uprs;
output [G_CPUW-1:0]     updi;
input [G_CPUW-1:0]      updo;
input                   uprdy;

//-----------------------------------------------------------------------------
// Functions
//-----------------------------------------------------------------------------
//Ceiling of LOG2 function
function integer clog2;
  input integer a;
  for (clog2=0; a>0; clog2=clog2+1) a=a>>1;
endfunction
function integer fclog2;
  input integer a;
  fclog2 = clog2(2**clog2(a-1)-1);
endfunction

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

//------------------------------------------------------------------------------
// Address & Data Write
// AXI will keep address and data until ready/response asserted
assign                  upa  = (s_axi_arvalid ? s_axi_araddr[BASEADD_MSB:BASEADD_LSB] : s_axi_awaddr[BASEADD_MSB:BASEADD_LSB]);
assign                  updi = s_axi_wdata;

//------------------------------------------------------------------------------
// Write & Read Strobe Gen
wire                    wr_valid;
wire                    rd_valid;
assign                  wr_valid = s_axi_awvalid & s_axi_wvalid;
assign                  rd_valid = s_axi_arvalid;
assign                  upen = wr_valid | rd_valid;

wire                    upen_ws, upen_rs;
wire                    rwaccess_ack, rwaccess_ack1;
rwsgen rwsgen
    (
     .clk               (clk),
     .rst_n             (rst_n),
     .write             (wr_valid),
     .read              (rd_valid),
     .uprdy             (rwaccess_ack),
     .upen_ws           (upen_ws),
     .upen_rs           (upen_rs),
     .upws              (upws),
     .uprs              (uprs)
     );

//------------------------------------------------------------------------------
// Data MUX
wire                    timeout;
reg [TIMEOUT_W-1:0]     time_cnt;
always @(posedge clk)
    begin
    if (!rst_n)         time_cnt <= {TIMEOUT_W{1'b0}};
    else                time_cnt <= rwaccess_ack ? {TIMEOUT_W{1'b0}}  :
                                    upen         ? (time_cnt + 1'b1) : {TIMEOUT_W{1'b0}};
    end

assign                  timeout = &time_cnt;

reg [G_CPUW-1:0]        cpu_rddat;  // clk 1
always @(posedge clk)
    begin
    if (!rst_n)         cpu_rddat <= {G_CPUW{1'b0}};
    else                cpu_rddat <= uprdy   ? updo      :
                                     timeout ? TIMEOUT_D : {G_CPUW{1'b0}};
    end

//------------------------------------------------------------------------------
// ACK Gen
assign                  rwaccess_ack = uprdy | timeout; // clk 0
s_dff                   pl_rwaccess_ack(clk, rst_n, rwaccess_ack , rwaccess_ack1);

//------------------------------------------------------------------------------
// AXI4 Lite Interface Process

// Write
wire                    wr_rdy;
assign                  wr_rdy = upen_ws & rwaccess_ack;

assign                  s_axi_awready = wr_rdy;
assign                  s_axi_wready  = wr_rdy;

wire [1:0]              response, response1;
assign                  response = (uprdy   ? 2'b00 : 
                                    timeout ? 2'b10 : 2'b00); // clk 0

s_pl_reg #(2)           pl_response(clk, rst_n, response , response1);

assign                  s_axi_bresp   = response1; // clk 1

/* -----\/----- EXCLUDED -----\/-----
reg                     wr_resp_vld;
always @(posedge clk)
    begin
    if(!rst_n)          wr_resp_vld <= 1'b0;
    else                wr_resp_vld <= rwaccess_ack & s_axi_bready;
    end
 -----/\----- EXCLUDED -----/\----- */
wire                    wr_resp_vld;
assign                  wr_resp_vld = rwaccess_ack1 & s_axi_bready;

assign                  s_axi_bvalid = wr_resp_vld;

// Read
wire                    rd_rdy;
assign                  rd_rdy = upen_rs & rwaccess_ack;

assign                  s_axi_arready = rd_rdy;
assign                  s_axi_rresp   = response;

/* -----\/----- EXCLUDED -----\/-----
reg                     rd_resp_vld;
always @(posedge clk)
    begin
    if(!rst_n)          rd_resp_vld <= 1'b0;
    else                rd_resp_vld <= rwaccess_ack & s_axi_rready;
    end
 -----/\----- EXCLUDED -----/\----- */
wire                    rd_resp_vld;
assign                  rd_resp_vld = rwaccess_ack1 & s_axi_rready;

assign                  s_axi_rdata  = cpu_rddat;
assign                  s_axi_rvalid = rd_resp_vld;

endmodule 
