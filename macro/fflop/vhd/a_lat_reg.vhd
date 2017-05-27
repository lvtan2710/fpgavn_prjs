-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_lat_reg.vhd
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

ENTITY a_lat_reg IS
  
  GENERIC (
    SIZE    : INTEGER := 8);
    --RST_VAL : STD_LOGIC_VECTOR(511 DOWNTO 0) := (OTHERS => '0'));

  PORT (
    clk   : IN  STD_LOGIC;                           -- system clock
    rst_n : IN  STD_LOGIC;                           -- reset
    ena   : IN  STD_LOGIC;                           -- enable signal
    idat  : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);   -- input data
    odat  : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0));  -- output data

end a_lat_reg;

ARCHITECTURE behav OF a_lat_reg IS

BEGIN  -- behav

  PROCESS (clk, rst_n)
    --CONSTANT RESET_VAL : STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0) := RST_VAL(SIZE-1 DOWNTO 0);  -- Reset Value
    CONSTANT RESET_VAL : STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0) := (OTHERS => '0');
  BEGIN  -- PROCESS
    IF (rst_n = '0') THEN                  -- asynchronous reset (active low)
      odat <= RESET_VAL; 
    ELSIF (rising_edge(clk)) THEN  -- rising clock edge
      IF (ena = '1') THEN
        odat <= idat;
      END IF;
    END IF;
  END PROCESS;

END behav;
