-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : s_lat_reg.vhd
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

ENTITY s_lat_reg IS
  
  GENERIC (
    SIZE    : NATURAL RANGE 2 TO 512;
    RST_VAL : STD_LOGIC_VECTOR(511 DOWNTO 0) := (OTHERS => '0'));

  PORT (
    clk   : IN  STD_LOGIC;                           -- system clock
    rst_n : IN  STD_LOGIC;                           -- reset
    ena   : IN  STD_LOGIC;                           -- enable signal
    idat  : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);   -- input data
    odat  : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0));  -- output data

END s_lat_reg;

ARCHITECTURE behav OF s_lat_reg IS
      
 BEGIN  -- behav

  PROCESS (clk, rst_n)
    CONSTANT RESET_VAL : STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0) := RST_VAL(SIZE-1 DOWNTO 0);  -- Reset Value
  BEGIN  -- process
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        odat <= RESET_VAL;
      ELSIF (ena = '1') THEN
        odat <= idat;
      END IF;
    END IF;
  END PROCESS;

END behav;
