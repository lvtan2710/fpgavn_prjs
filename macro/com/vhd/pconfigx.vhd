-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : pconfigx.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is used as a macro for Control Register Function
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY pconfigx IS
  
  GENERIC (
    CPUW    : NATURAL RANGE 2 TO 512 := 16;
    RST_VAL : STD_LOGIC_VECTOR(511 DOWNTO 0) := (OTHERS => '0'));

  PORT (
    clk     : IN  STD_LOGIC;
    rst_n   : IN  STD_LOGIC;
    upen    : IN  STD_LOGIC;
    upws    : IN  STD_LOGIC;
    uprs    : IN  STD_LOGIC;
    updi    : IN  STD_LOGIC_VECTOR(CPUW-1 DOWNTO 0);
    updo    : OUT STD_LOGIC_VECTOR(CPUW-1 DOWNTO 0);
    upack   : OUT STD_LOGIC;
    cfg_out : OUT STD_LOGIC_VECTOR(CPUW-1 DOWNTO 0));

END pconfigx;

ARCHITECTURE behav OF pconfigx IS

  CONSTANT RESET_VAL : STD_LOGIC_VECTOR(CPUW-1 DOWNTO 0) := RST_VAL(CPUW-1 DOWNTO 0);
  
  -----------------------------------------------------------------------------
  -- Signal Delaration
  -----------------------------------------------------------------------------
  SIGNAL wr_en   : STD_LOGIC;
  SIGNAL rd_en   : STD_LOGIC;
  SIGNAL int_reg : STD_LOGIC_VECTOR(CPUW-1 DOWNTO 0);
  
BEGIN  -- behav
  wr_en <= upws AND upen;
  rd_en <= uprs AND upen;
  
  wr_data2reg: PROCESS (clk)
  BEGIN  -- process wr_data2reg
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        int_reg <= RESET_VAL;
      ELSIF (wr_en = '1') THEN
        int_reg <= updi;
      END IF;
    END IF;
  END PROCESS wr_data2reg;

  cfg_out <= int_reg;
  updo    <= int_reg when (upen = '1') else (OTHERS => '0');
  upack   <= wr_en OR rd_en;
    
END behav;
