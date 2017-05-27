-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : s_fflopnx.vhd
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
USE ieee.std_logic_arith.ALL;

ENTITY s_fflopnx IS
  
  GENERIC (
    SIZE    : INTEGER := 16;
    RST_VAL : INTEGER := 0; 
    DELAY   : INTEGER := 2  -- number of clock for delay/pipeline
    );

  PORT (
    clk     : IN  STD_LOGIC;
    rst_n   : IN  STD_LOGIC;
    d       : IN  UNSIGNED(SIZE-1 DOWNTO 0);
    qn      : OUT UNSIGNED(SIZE-1 DOWNTO 0));

END s_fflopnx;

ARCHITECTURE behav OF s_fflopnx IS

  CONSTANT SHIFTW : INTEGER := SIZE*DELAY;

  SIGNAL shiftdat : UNSIGNED(SHIFTW-1 DOWNTO 0);
  
BEGIN  -- behav

  PROCESS (clk)
  BEGIN  -- PROCESS
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        shiftdat <= conv_unsigned(RST_VAL, shiftdat'length);
      ELSE
        shiftdat <= (shiftdat(SIZE*(DELAY-1)-1 DOWNTO 0) & d);
    END IF;
  END IF;
  END PROCESS;
  
  qn <= shiftdat(SHIFTW-1 DOWNTO SHIFTW-SIZE);
    
END behav;
