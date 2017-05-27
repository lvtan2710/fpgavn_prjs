-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_latch.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is Asynchronous Latch Register.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY a_latch IS
  
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

end a_latch;

ARCHITECTURE behav OF a_latch IS

BEGIN  -- behav

  PROCESS (clk, rst_n)
  BEGIN  -- PROCESS
    IF (rst_n = '0') THEN                   -- asynchronous reset (active low)
      odat <= conv_unsigned(RST_VAL, odat'length); 
    ELSIF (rising_edge(clk)) THEN           -- rising clock edge
      IF (ena = '1') THEN
        odat <= idat;
      END IF;
    END IF;
  END PROCESS;

END behav;
