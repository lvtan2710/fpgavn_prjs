-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_dff.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is the Asynchronous D-flipflop with low reset.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY a_dff IS
  
  GENERIC (
    RST_VAL : STD_LOGIC := '0');              -- Reset Value

  PORT (
    clk   : IN  STD_LOGIC;              -- system clock
    rst_n : IN  STD_LOGIC;              -- reset
    d     : IN  STD_LOGIC;              -- input D
    q     : OUT STD_LOGIC);             -- ouput Q

END a_dff;

ARCHITECTURE behav OF a_dff IS

BEGIN  -- behav
  
  rtl: PROCESS (clk, rst_n)
  BEGIN  -- process rtl
    IF (rst_n = '0') THEN
      q <= RST_VAL;
    ELSIF (rising_edge(clk)) THEN
      q <= d;
    END IF;
  END PROCESS rtl;

END behav;
