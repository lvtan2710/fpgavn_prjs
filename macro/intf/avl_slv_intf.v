////////////////////////////////////////////////////////////////////////////////
//
// FPGAVN.COM
//
// Filename     : avl_slv_intf.v
// Description  : This is Avalon Slave Interface which convert the Avalon Bus to
//  Microprocessor Interface.
//
// Author       : fpgavn@fpgavn.com
// Created On   : Sat May 27 14:42:02 2017
// History (Date, Changed By)
//
////////////////////////////////////////////////////////////////////////////////

module avl_slv_intf
    (
     clk,
     rst_n,

     // Avalon Slave Interface
     aslv_addr,
     aslv_wr,
     aslv_byteena,
     aslv_wrdat,
     aslv_wrrespvld,
     aslv_rd,
     aslv_rddat,
     aslv_rddatvld,
     aslv_resp,
     aslv_waitreq,
     
     // Microprocessor Interface
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
parameter               AVL_ADDR        = 32;
parameter               AVL_DATW        = 32;
parameter               AVL_SYMBOL      = 8;                    // With Avalon this value is fixed to 8
parameter               AVL_BYTEENW     = AVL_DATW/AVL_SYMBOL;  // 4
parameter               AVL_ADDRUNIT    = "SYMBOL";             // SYMBOL, WORD
parameter               AVL_ADBITALIGN  = (AVL_ADDRUNIT == "WORD") ? 0 : fclog2(AVL_BYTEENW);  // 2, 2^2 = 4, Address Bit Align

parameter               G_CPUA          = AVL_ADDR-AVL_ADBITALIGN;  // 32 - 2 = 30, temp = 27
parameter               G_CPUW          = AVL_DATW;
parameter               G_BYTEENA       = AVL_BYTEENW;

localparam              TIMEOUT_W       = 8;
localparam              TIMEOUT_D       = 32'hCAFE_CAFE;
localparam              BASEADD_MSB     = AVL_ADDR-1;
localparam              BASEADD_LSB     = AVL_ADBITALIGN;
 
////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                   clk;
input                   rst_n;

// Avalon Slave Interface
input [AVL_ADDR-1:0]    aslv_addr;
input                   aslv_wr;
input [AVL_BYTEENW-1:0] aslv_byteena;
input [AVL_DATW-1:0]    aslv_wrdat;
output                  aslv_wrrespvld;
input                   aslv_rd;
output [AVL_DATW-1:0]   aslv_rddat;
output                  aslv_rddatvld;
output [1:0]            aslv_resp;
output                  aslv_waitreq;

// Microprocessor Interface
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
// Address & Data Write Synchronization
reg [G_CPUA-1:0]        upa;
always @(posedge clk)
    begin
    if (!rst_n)         upa <= {G_CPUA{1'b0}};
    else                upa <= (aslv_wr | aslv_rd) ? aslv_addr[BASEADD_MSB:BASEADD_LSB] : upa;
    end

reg [G_CPUW-1:0]        updi;
always @(posedge clk)
    begin   
    if (!rst_n)         updi <= {G_CPUW{1'b0}};
    else                updi <= aslv_wr ? aslv_wrdat : updi;
    end

//------------------------------------------------------------------------------
// Write & Read Strobe Gen
wire                    upen_ws, upen_rs;
assign                  upen = upen_ws | upen_rs;

wire                    rwaccess_ack, rwaccess_ack1;
rwsgen rwsgen
    (
     .clk               (clk),
     .rst_n             (rst_n),
     .write             (aslv_wr),
     .read              (aslv_rd),
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
    else                time_cnt <= (uprdy | timeout) ? 1'b0 :
                                    upen              ? (time_cnt + 1'b1) : {TIMEOUT_W{1'b0}};
    end

assign                  timeout = &time_cnt;

reg [G_CPUW-1:0]        cpu_rddat;  // clk 1
wire [G_CPUW-1:0]       aslv_rddat; // clk 1
always @(posedge clk)
    begin
    if (!rst_n)         cpu_rddat <= {G_CPUW{1'b0}};
    else                cpu_rddat <= uprdy   ? updo      :
                                     timeout ? TIMEOUT_D : {G_CPUW{1'b0}};
    end

assign                  aslv_rddat = cpu_rddat;

//------------------------------------------------------------------------------
// ACK Gen
assign                  rwaccess_ack = uprdy | timeout; // clk 0

s_pl_reg #(1)           pl_rwaccess_ack(clk, rst_n, rwaccess_ack , rwaccess_ack1);

assign                  aslv_rddatvld  = rwaccess_ack1 & upen_rs;
assign                  aslv_wrrespvld = rwaccess_ack1 & upen_ws;

wire [1:0]              response, response1;
assign                  response = (uprdy   ? 2'b00 : 
                                    timeout ? 2'b10 : 2'b00); // clk 0

s_pl_reg #(1*2)         pl_response(clk, rst_n, response , response1);

assign                  aslv_resp      = response1; // clk 1

reg                     waitrequest;
always @(posedge clk)
    begin
    if (!rst_n)         waitrequest <= 1'b0;
    else                waitrequest <= (rwaccess_ack) ? 1'b0 :
                                       (upws | uprs)  ? 1'b1 : waitrequest;
    end 

assign                  aslv_waitreq = (upws | uprs | waitrequest);

endmodule 
