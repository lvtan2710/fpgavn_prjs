-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : axi_slv_intf.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module convert the AXI4 Lite protocol to Local Bus
-- Processor Interface.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

entity axi_slv_intf is
  
  generic (
    AXI_ADDR        : integer          := 32;  -- MAXIMUM IS 32
    AXI_DATW        : integer          := 32;  -- MAXIMUM IS 32
    AXI_SYMBOL      : integer          := 8;
    AXI_STROBE      : integer          := 4;
    AXI_ADBITALIGN  : integer          := 2;
    G_CPUA          : integer          := 32;
    G_CPUW          : integer          := 32;
    TIMEOUT_W       : integer          := 8;
    TIMEOUT_D       : std_logic_vector := X"CAFE_CAFE"
    );

  port (
    clk             : in std_logic;
    rst_n           : in std_logic;

    ---------------------------------------------------------------------------
    -- AXI4-Lite Interface
    ---------------------------------------------------------------------------
    -- Write Address Channel
    s_axi_awaddr    : in  std_logic_vector(AXI_ADDR-1 downto 0);
    s_axi_awvalid   : in  std_logic;
    s_axi_awready   : out std_logic;
    -- Write Data Channel
    s_axi_wdata     : in  std_logic_vector(AXI_DATW-1 downto 0);
    s_axi_wstrb     : in  std_logic_vector(AXI_STROBE-1 downto 0);
    s_axi_wvalid    : in  std_logic;
    s_axi_wready    : out std_logic;
    -- Write Response Channel
    s_axi_bresp     : out std_logic_vector(1 downto 0);
    s_axi_bvalid    : out std_logic;
    s_axi_bready    : in  std_logic;
    -- Read Address Channel
    s_axi_araddr    : in  std_logic_vector(AXI_ADDR-1 downto 0);
    s_axi_arvalid   : in  std_logic;
    s_axi_arready   : out std_logic;
    -- Read Data Channel
    s_axi_rdata     : out std_logic_vector(AXI_DATW-1 downto 0);
    s_axi_rresp     : out std_logic_vector(1 downto 0);
    s_axi_rvalid    : out std_logic;
    s_axi_rready    : in  std_logic;

    ---------------------------------------------------------------------------
    -- Local Processor Interface
    ---------------------------------------------------------------------------
    upa             : out std_logic_vector(G_CPUA-1 downto 0);
    upen            : out std_logic;
    upws            : out std_logic;
    uprs            : out std_logic;
    updi            : out std_logic_vector(G_CPUW-1 downto 0);
    updo            : in  std_logic_vector(G_CPUW-1 downto 0);
    uprdy           : in  std_logic
    );
end axi_slv_intf;

architecture behav of axi_slv_intf is

  constant BASEADD_MSB : integer := AXI_ADDR-1;
  constant BASEADD_LSB : integer := AXI_ADBITALIGN;
  
  -----------------------------------------------------------------------------
  -- Intermediate Signal Delaration
  -----------------------------------------------------------------------------
  signal wr_valid           : std_logic;
  signal rd_valid           : std_logic;
  signal cur_upen           : std_logic;
  signal rwaccess_ack       : std_logic;
  signal rwaccess_ack1      : std_logic;
  signal upen_ws, upen_rs   : std_logic;
  signal timeout            : std_logic;

  signal nxt_time_cnt , cur_time_cnt  : unsigned(TIMEOUT_W-1 downto 0);
  signal nxt_cpu_rddat, cur_cpu_rddat : std_logic_vector(G_CPUW-1 downto 0);
  signal response     , response1     : std_logic_vector(1 downto 0);
  
  signal wr_rdy, rd_rdy     : std_logic;
  signal wr_resp_vld        : std_logic;
  signal rd_resp_vld        : std_logic;
    
begin  -- behav

  ------------------------------------------------------------------------------
  -- Address & Data Write
  -- AXI will keep address and data until ready/response asserted
  upa  <= s_axi_awaddr(BASEADD_MSB downto BASEADD_LSB) when (s_axi_awvalid = '1') else
          s_axi_araddr(BASEADD_MSB downto BASEADD_LSB) when (s_axi_arvalid = '1') else (others => '0');
  updi <= s_axi_wdata;
  
  ------------------------------------------------------------------------------
  -- Write & Read Strobe Gen
  wr_valid <= s_axi_awvalid and s_axi_wvalid;
  rd_valid <= s_axi_arvalid;
  cur_upen <= wr_valid or rd_valid;
  upen     <= cur_upen;
  
  inst_rwsgen: entity work.rwsgen
    port map (clk, rst_n,
              wr_valid, rd_valid,
              rwaccess_ack,
              upen_ws, upen_rs,
              upws, uprs);
  
  ------------------------------------------------------------------------------
  -- Data MUX
  nxt_time_cnt <= (others => '0')    when (rwaccess_ack = '1') else
                  (cur_time_cnt + 1) when (cur_upen = '1')     else (others => '0');
  
  timeout_counter: process (clk)
  begin  -- process timeout_counter
    if (rising_edge (clk)) then
      if (rst_n = '0') then
        cur_time_cnt <= (others => '0');
      else
        cur_time_cnt <= nxt_time_cnt;
      end if;
    end if;
  end process timeout_counter;

  timeout <= and_reduce(std_logic_vector(cur_time_cnt));

  nxt_cpu_rddat <= updo      when (uprdy = '1')   else
                   TIMEOUT_D when (timeout = '1') else (others => '0');
  
  mux_data_out: process (clk)
  begin  -- process mux_data_out
    if (rising_edge (clk)) then
      if (rst_n = '0') then
        cur_cpu_rddat <= (others => '0');
      else
        cur_cpu_rddat <= nxt_cpu_rddat;
      end if;
    end if;
  end process mux_data_out; 
    
  ------------------------------------------------------------------------------
  -- ACK Gen
  rwaccess_ack <= uprdy or timeout;
  inst_pl_rwaccess_ack: entity work.s_dff
    port map (clk, rst_n, rwaccess_ack, rwaccess_ack1);
  
  ------------------------------------------------------------------------------
  -- AXI4Lite Interface Process

  -- write
  wr_rdy <= upen_ws and rwaccess_ack;

  s_axi_awready <= wr_rdy;
  s_axi_wready  <= wr_rdy;
  
  response <= "00" when (uprdy = '0')   else
              "10" when (timeout = '1') else "00";

  inst_pl_response: entity work.s_pl_reg
    generic map (2)
    port map (clk, rst_n, response, response1);

  s_axi_bresp   <= response1; 
  wr_resp_vld   <= rwaccess_ack1 and s_axi_bready;
  s_axi_bvalid  <= wr_resp_vld;

  -- read
  rd_rdy <= upen_rs and rwaccess_ack;

  s_axi_arready <= rd_rdy;
  s_axi_rresp   <= response;

  rd_resp_vld   <= rwaccess_ack1 and s_axi_rready;
  s_axi_rdata   <= cur_cpu_rddat;
  s_axi_rvalid  <= rd_resp_vld;  

end behav;



