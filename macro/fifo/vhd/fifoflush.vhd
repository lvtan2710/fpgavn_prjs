-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : fifoflush.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is the FIFO Controller with flushing which handles
-- the write, read pointers, status signals such as full, empty. The memory of
-- FIFO is outside which connect directly with this controller.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY fifoflush IS
  
  GENERIC (
    ADDR     : INTEGER := 4);

  PORT (
    clk      : IN  STD_LOGIC;
    rst_n    : IN  STD_LOGIC;

    -- FIFO Control Interface
    fiford   : IN  STD_LOGIC;
    fifowr   : IN  STD_LOGIC;
    fifoflsh : IN  STD_LOGIC;
    fifofull : OUT STD_LOGIC;
    notempty : OUT STD_LOGIC;
    fifolen  : OUT STD_LOGIC_VECTOR(ADDR DOWNTO 0);

    -- FIFO Memory Interface
    mem_wr   : OUT STD_LOGIC;
    mem_wa   : OUT STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
    mem_rd   : OUT STD_LOGIC;
    mem_ra   : OUT STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0));

END fifoflush;

ARCHITECTURE behav OF fifoflush IS
  
  SIGNAL fifoempt  : STD_LOGIC := '0';
  SIGNAL fifo_len  : STD_LOGIC_VECTOR(ADDR DOWNTO 0);
  SIGNAL fifo_full : STD_LOGIC := '0';
  SIGNAL wrcnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL rdcnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL rd_wr     : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  
BEGIN  -- behav

  fifoempt  <= '1' WHEN (fifo_len = (OTHERS => '0')) ELSE '0';
  notempty  <= NOT fifoempt;
  fifo_full <= '1' WHEN (fifo_len(ADDR) = '1') ELSE '0';
  fifofull  <= fifo_full;
  fifolen   <= fifo_len;
  
  mem_wr    <= fifowr AND (NOT fifo_full);
  mem_rd    <= fiford AND notempty;
  rd_wr     <= (mem_rd & mem_wr);
  
  rdcnt     <= wrcnt - fifo_len(ADDR-1 DOWNTO 0);
  mem_wa    <= wrcnt;
  mem_ra    <= rdcnt;
  
  wrcnt_pro: PROCESS (clk)
  BEGIN  -- PROCESS
    IF (rising_edge(clk)) THEN
      IF rst_n = '0' THEN
        wrcnt <= (OTHERS => '0');
      ELSIF (fifoflsh = '1') THEN
        wrcnt <= (OTHERS => '0');
      ELSIF (mem_wr = '1')
        wrcnt <= wrcnt + 1;
      END
  END PROCESS;

  fifolen_pro: PROCESS (clk)
  BEGIN  -- PROCESS fifolen_pro
    IF (rising_edge(clk)) THEN
      IF rst_n = '0' THEN
        fifo_len <= (OTHERS => '0');
      ELSIF (fifoflsh = '1') THEN
        fifo_len <= (OTHERS => '0');
      ELSE
        CASE (rd_wr) IS
          WHEN "01" => fifo_len <= fifo_len + 1;
          WHEN "10" => fifo_len <= fifo_len - 1;
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS fifolen_pro;

END behav;
