-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_fflopx.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is asynchronous flip flop for a signal or a bus.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY a_fflopx IS
  
  GENERIC (
    SIZE    : INTEGER := 16;                 -- WIDTH of register
    RST_VAL : INTEGER := 0
    );

  PORT (
    clk   : IN  STD_LOGIC;                   -- system clock
    rst_n : IN  STD_LOGIC;                   -- reset
    d     : IN  UNSIGNED(SIZE-1 DOWNTO 0);   -- input data
    q     : OUT UNSIGNED(SIZE-1 DOWNTO 0));  -- output data

END a_fflopx;

ARCHITECTURE behav OF a_fflopx IS

BEGIN  -- behav

  PROCESS (clk, rst_n)
  BEGIN
    IF (rst_n = '0') THEN
      q <= conv_unsigned(RST_VAL, q'length);
    ELSIF (rising_edge(clk)) THEN
      q <= d;
    END IF;
  END PROCESS;

END behav;
