-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : s_dff.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is a synchronous D-flipflop with low reset.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY s_dff IS
  
  GENERIC (
    RST_VAL : STD_LOGIC := '0');        -- Reset Value

  PORT (
    clk   : IN  STD_LOGIC;
    rst_n : IN  STD_LOGIC;
    d     : IN  STD_LOGIC;
    q     : OUT STD_LOGIC);

END s_dff;

ARCHITECTURE behav OF s_dff IS

BEGIN  -- behav

  PROCESS (clk)
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        q <= RST_VAL;
      ELSE
        q <= d;
      END IF;
    END IF;
  END PROCESS;

END behav;
	
