-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : fifo_le_1x.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This is a normal FIFO module:
--  + the memory is implemented by LE
--  + read, write after 1 clock cycle
--  + support informations: fifo length, fifo flush, full, empty
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY fifo_le_1x IS
  
  GENERIC (
    ADDR  : INTEGER := 4;
    WIDTH : INTEGER := 8);

  PORT (
    clk      : IN  STD_LOGIC;                          -- system clock
    rst_n    : IN  STD_LOGIC;                          -- reset
    fifowr   : IN  STD_LOGIC;                          -- write strobe
    fifodin  : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); -- Data input
    fiford   : IN  STD_LOGIC;                          -- read strobe
    fifodout : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); -- Data output
    fifolen  : OUT STD_LOGIC_VECTOR(ADDR DOWNTO 0);    -- fifo length
    notempty : OUT STD_LOGIC;                          -- Status of empty
    fifofull : OUT STD_LOGIC;                          -- Status of full
    fifoflsh : IN  STD_LOGIC);  -- flush signal to reset all entries of fifo

END fifo_le_1x;

ARCHITECTURE behav OF fifo_le_1x IS

  CONSTANT DEPTH : INTEGER := 2**ADDR;
  
  -- Memory declaration
  TYPE fifo_memory IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  -- Memory declaration
  SIGNAL memfifo    : fifo_memory;
  
  SIGNAL fifo_len   : STD_LOGIC_VECTOR(ADDR   DOWNTO 0);
  SIGNAL wr_cnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL rd_cnt     : STD_LOGIC_VECTOR(ADDR-1 DOWNTO 0);
  SIGNAL wrstrobe   : STD_LOGIC;
  SIGNAL rdstrobe   : STD_LOGIC;
  SIGNAL rdwrstrobe : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL fifo_full  : STD_LOGIC;
  SIGNAL fifoempt   : STD_LOGIC;
  SIGNAL fifo_dout  : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
  
BEGIN  -- behav

  ------------------------------------------------------------------------------
  -- Control Logic
  ------------------------------------------------------------------------------
  fifoempt   <= '1' WHEN (fifo_len = 0) ELSE '0';
  fifo_full  <= fifo_len(ADDR);
  wrstrobe   <= fifowr AND (NOT fifo_full);
  rdstrobe   <= fiford AND (NOT fifoempt);
  rdwrstrobe <= (rdstrobe & wrstrobe);

  -- Read pointer control
  rd_cnt    <= wr_cnt - fIFo_len(ADDR-1 DOWNTO 0);

  -- Write pointer control
  PROCESS (clk)
  BEGIN  
    IF rising_edge(clk) THEN
      IF (rst_n = '0') THEN
        wr_cnt <= (OTHERS => '0');
      ELSIF (fifoflsh = '1') THEN
        wr_cnt <= (OTHERS => '0');
      ELSIF (wrstrobe  = '1') THEN
        wr_cnt <= wr_cnt + 1;
      END IF;
    END IF;       
  END PROCESS;

  -- FIFO Length control
  PROCESS (clk)
  BEGIN  
    IF rising_edge(clk) THEN
      IF (rst_n = '0') THEN
        fifo_len <= (OTHERS => '0');
      ELSIF (fifoflsh = '1') THEN
        fifo_len <= (OTHERS => '0');
      else
        CASE (rdwrstrobe) IS
          WHEN "01" =>
            fifo_len <= fifo_len + 1;
          WHEN "10" =>
            fifo_len <= fifo_len - 1;
          WHEN OTHERS =>
            fifo_len <= fifo_len;
        END case;          
      END IF;
    END IF;
  END PROCESS;

  ------------------------------------------------------------------------------
  -- Access Memory
  ------------------------------------------------------------------------------
  -- Write data to memory
  PROCESS (clk)
  BEGIN  
    IF rising_edge(clk) THEN
      IF (rst_n = '0') THEN
        memfifo <= (OTHERS => (OTHERS => '0'));  -- Reset all entries
      ELSIF (wrstrobe = '1') THEN
        memfifo(conv_integer(wr_cnt)) <= fifodin;
      END IF;
    END IF;
  END PROCESS;
  
  -- Read data from memory
  PROCESS (clk)
  BEGIN  
    IF rising_edge(clk) THEN
      IF (rst_n = '0') THEN
        fifo_dout <= (OTHERS => '0');
      ELSIF (rdstrobe = '1') THEN
        fifo_dout <= memfifo(conv_integer(rd_cnt));
      END IF;
    END IF;
  END PROCESS;

  ------------------------------------------------------------------------------
  -- Connect to output ports
  ------------------------------------------------------------------------------
  notempty  <= NOT fifoempt;
  fifofull  <= fifo_full;
  fifolen   <= fifo_len;
  fifodout  <= fifo_dout;
  
END behav;
