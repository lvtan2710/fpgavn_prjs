-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : fwft_fifox.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is First Word Fall Through FIFO.
-- The difference between standard FIFO and FWFT FIFO are the first byte
-- written into the FIFO immediately appears on the output. Allowing you to
-- read the first byte without pulsing the Read Enable signal first.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY fwft_fifox IS
  
  GENERIC (
    ADDR  : INTEGER := 4;
    WIDTH : INTEGER := 8);

  PORT (
    clk         : IN  STD_LOGIC;                           -- system clock
    rst_n       : IN  STD_LOGIC;                           -- reset
    fifowr      : IN  STD_LOGIC;                           -- write strobe
    fifodin     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  -- Data input
    fiford      : IN  STD_LOGIC;                           -- read strobe
    fifodout    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  -- Data output
    notempty    : OUT STD_LOGIC;                           -- Status of Empty
    fifofull    : OUT STD_LOGIC);                          -- Status of full

END fwft_fifox;

ARCHITECTURE behav OF fwft_fifox IS

  CONSTANT DEPTH : INTEGER := 2**ADDR;
  TYPE fifo_memory IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  SIGNAL memfifo    : fifo_memory;
  
  SIGNAL fifo_len   : STD_LOGIC_VECTOR(ADDR   DOWNTO 0);
  SIGNAL wr_cnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL rd_cnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL wrstrobe   : STD_LOGIC := '0';
  SIGNAL rdstrobe   : STD_LOGIC := '0';
  SIGNAL rdwrstrobe : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  SIGNAL fifo_full  : STD_LOGIC := '0';
  SIGNAL fifoempt   : STD_LOGIC := '1';
    
BEGIN  -- behav
  
  fifoempt  <= '1' WHEN (fifo_len = (OTHERS => '0')) ELSE '0';
  fifo_full <= fifo_len(ADDR);
  wrstrobe  <= fifowr AND (NOT fifo_full);
  rdstrobe  <= fiford AND (NOT fifoempt);
  rdwrstrobe <= (rdstrobe & wrstrobe);
  
  -- Read pointer control
  rd_cnt    <= wr_cnt - fifo_len(ADDR-1 DOWNTO 0);

  -- Write pointer control
  PROCESS (clk)
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF rst_n = '0' THEN
        wr_cnt <= (OTHERS => '0');
      ELSIF (wrstrobe  = '1') THEN
        wr_cnt <= wr_cnt + 1;
      END IF;
    END IF;       
  END PROCESS;

  -- FIFO Length control
  PROCESS (clk)
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF rst_n = '0' THEN
        fifo_len <= (OTHERS => '0');
      ELSE
        CASE (rdwrstrobe) IS
          when "01" =>
            fifo_len <= fifo_len + 1;
          when "10" =>
            fifo_len <= fifo_len - 1;
          when OTHERS =>
            fifo_len <= fifo_len;
        END case;          
      END IF;
    END IF;
  END PROCESS;
  
  -- Write data to memory
  PROCESS (clk)
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF rst_n = '0' THEN
        FOR i IN 0 TO memfifo'range LOOP
          memfifo(i) <= (OTHERS => '0');
        END LOOP;  -- i
      ELSIF wrstrobe THEN
        memfifo(conv_integer(wr_cnt)) <= fifodin;
      END IF;
    END IF;
  END PROCESS;

  -- Read data from memory
  fifodout <= memfifo(conv_integer(rd_cnt));

  -- Status
  notempty <= NOT fifoempt;
  fifofull <= fifo_full;
  
END behav;
