-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_pl_reg_nclk.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is asynchronous pipeline/delay data with n clocks.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY a_pl_reg_nclk IS
  
  GENERIC (
    SIZE  : NATURAL RANGE 2 TO 512 := 16;
    DELAY : INTEGER := 3);              -- number of clock for delay/pipeline

  PORT (
    clk   : IN  STD_LOGIC;
    rst_n : IN  STD_LOGIC;
    idat  : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
    odat  : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0));

END a_pl_reg_nclk;

ARCHITECTURE behav OF a_pl_reg_nclk IS

  COMPONENT a_pl_reg
    GENERIC (
      SIZE      : NATURAL RANGE 2 TO 512;
      RST_VAL   : STD_LOGIC_VECTOR(511 DOWNTO 0)
      );
    PORT (
      clk       : IN  STD_LOGIC;
      rst_n     : IN  STD_LOGIC;
      idat      : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
      odat      : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
      );
  END COMPONENT;
 
  CONSTANT SHIFTW : INTEGER := SIZE*DELAY;
  SIGNAL shiftdat : STD_LOGIC_VECTOR(SHIFTW-1 DOWNTO 0);
  
BEGIN  -- behav

  DELAY_0: IF (DELAY = 0) GENERATE
    odat <= idat;
  END GENERATE DELAY_0;
  
  DELAY_1: IF (DELAY = 1) GENERATE
    reg_pipeline_1: a_pl_reg
      GENERIC MAP (
        SIZE    => SIZE)
      PORT MAP (
        clk     => clk,
        rst_n   => rst_n,
        idat    => idat,
        odat    => shiftdat);
    odat <= shiftdat;
  END GENERATE DELAY_1;

  DELAY_N: IF (DELAY > 1) GENERATE
    reg_pipeline_n: a_pl_reg
      GENERIC MAP (
        SIZE    => SIZE)
      PORT MAP (
        clk     => clk,
        rst_n   => rst_n,
        idat    => (shiftdat(SIZE*(DELAY-1)-1 DOWNTO 0) & idat),
        odat    => shiftdat);
    odat <= shiftdat(SHIFTW-1 DOWNTO SHIFTW-SIZE);
  END GENERATE DELAY_N;
    
END behav;
