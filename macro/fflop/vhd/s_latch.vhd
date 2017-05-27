-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : s_latch.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is Latch Register.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY s_latch IS
  
  GENERIC (
    SIZE    : INTEGER := 8;
    RST_VAL : INTEGER := 0
    );

  PORT (
    clk   : IN  STD_LOGIC;                   -- system clock
    rst_n : IN  STD_LOGIC;                   -- reset
    ena   : IN  STD_LOGIC;                   -- enable signal
    idat  : IN  UNSIGNED(SIZE-1 DOWNTO 0);   -- input data
    odat  : OUT UNSIGNED(SIZE-1 DOWNTO 0));  -- output data

END s_latch;

ARCHITECTURE behav OF s_latch IS
      
 BEGIN  -- behav

  PROCESS (clk)
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        odat <= conv_unsigned(RST_VAL, odat'length);
      ELSIF (ena = '1') THEN
        odat <= idat;
      END IF;
    END IF;
  END PROCESS;

END behav;
