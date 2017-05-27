-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : avl_slv_intf.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module convert the Avalon protocol to Local Bus
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

entity avl_slv_intf is
  
  generic (
    AVL_ADDR        : integer          := 32;  -- MAXIMUM IS 32
    AVL_DATW        : integer          := 32;  -- MAXIMUM IS 32
    AVL_SYMBOL      : integer          := 8;
    AVL_BYTEENW     : integer          := 4;
    AVL_ADBITALIGN  : integer          := 2;
    G_CPUA          : integer          := 32;
    G_CPUW          : integer          := 32;
    TIMEOUT_W       : integer          := 8;
    TIMEOUT_D       : std_logic_vector := X"CAFE_CAFE"
    );

  port (
    clk             : in std_logic;
    rst_n           : in std_logic;

    ---------------------------------------------------------------------------
    -- Avalon Interface
    ---------------------------------------------------------------------------
    aslv_addr       : in  std_logic_vector(AVL_ADDR-1 downto 0);
    aslv_wr         : in  std_logic;
    aslv_byteena    : in  std_logic_vector(AVL_BYTEENW-1 downto 0);
    aslv_wrdat      : in  std_logic_vector(AVL_DATW-1 downto 0);
    aslv_wrrespvld  : out std_logic;
    aslv_rd         : in  std_logic;
    aslv_rddat      : out std_logic_vector(AVL_DATW-1 downto 0);
    aslv_rddatvld   : out std_logic;
    aslv_resp       : out std_logic_vector(1 downto 0);
    aslv_waitreq    : out std_logic;

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
end avl_slv_intf;

architecture behav of avl_slv_intf is

  constant BASEADD_MSB : integer := AVL_ADDR-1;
  constant BASEADD_LSB : integer := AVL_ADBITALIGN;
  
  -----------------------------------------------------------------------------
  -- Intermediate Signal Delaration
  -----------------------------------------------------------------------------
  signal lat_addr_ena       : std_logic;
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
  signal cur_waitreq        : std_logic;
  signal nxt_waitreq        : std_logic;
  signal or_rdwrstb         : std_logic;
    
begin  -- behav

  ------------------------------------------------------------------------------
  -- Address & Data Write Synchroniztion
  lat_addr_ena <= aslv_wr or aslv_rd;
  syn_addr: process (clk)
  begin  -- process syn_addr
    if (rising_edge (clk)) then
      if (rst_n = '0') then
        upa <= (others => '0');
      elsif (lat_addr_ena = '1') then
        upa <= aslv_addr(BASEADD_MSB downto BASEADD_LSB);
      end if;
    end if;
  end process syn_addr;

  syn_datwr: process (clk)
  begin  -- process syn_datwr
    if (rising_edge (clk)) then
      if (rst_n = '0') then
        updi <= (others => '0');
      elsif (aslv_wr = '1') then
        updi <= aslv_wrdat;
      end if;
    end if;
  end process syn_datwr;
  
  ------------------------------------------------------------------------------
  -- Write & Read Strobe Gen
  upws     <= wr_valid;
  uprs     <= rd_valid;
  cur_upen <= upen_ws or upen_rs;
  upen     <= cur_upen;
  
  inst_rwsgen: entity work.rwsgen
    port map (clk, rst_n,
              aslv_wr, aslv_rd,
              rwaccess_ack,
              upen_ws, upen_rs,
              wr_valid, rd_valid);
  
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

  aslv_rddat <= cur_cpu_rddat;
    
  ------------------------------------------------------------------------------
  -- ACK Gen
  rwaccess_ack <= uprdy or timeout;
  inst_pl_rwaccess_ack: entity work.s_dff
    port map (clk, rst_n, rwaccess_ack, rwaccess_ack1);
  
  ------------------------------------------------------------------------------
  -- Avalon Interface Process

  -- write
  wr_rdy <= upen_ws and rwaccess_ack1;

  aslv_wrrespvld <= wr_rdy;
  
  response <= "00" when (uprdy = '0')   else
              "10" when (timeout = '1') else "00";

  inst_pl_response: entity work.s_pl_reg
    generic map (2)
    port map (clk, rst_n, response, response1);

  aslv_resp   <= response1;

  -- read
  rd_rdy <= upen_rs and rwaccess_ack1;

  aslv_rddatvld <= rd_rdy;

  or_rdwrstb  <= wr_valid or rd_valid;
  nxt_waitreq <= '0' when (rwaccess_ack = '1')  else
                 '1' when (or_rdwrstb = '1')    else cur_waitreq;
  flipflop_waitreq: entity work.s_dff
    port map (clk, rst_n, nxt_waitreq, cur_waitreq);

  aslv_waitreq <= wr_valid or rd_valid or cur_waitreq;

end behav;



