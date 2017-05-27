-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_pl_reg.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is asynchronous pipeline register
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY a_pl_reg IS
  
  GENERIC (
    SIZE    : NATURAL RANGE 2 TO 512 := 16;                -- WIDTH of register
    RST_VAL : STD_LOGIC_VECTOR(511 DOWNTO 0) := (OTHERS => '0'));

  PORT (
    clk   : IN  STD_LOGIC;                           -- system clock
    rst_n : IN  STD_LOGIC;                           -- reset
    idat  : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);   -- input data
    odat  : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0));  -- output data

END a_pl_reg;

ARCHITECTURE behav OF a_pl_reg IS

BEGIN  -- behav

  PROCESS (clk, rst_n)
    CONSTANT RESET_VAL : STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0) := RST_VAL(SIZE-1 DOWNTO 0);
  BEGIN
    IF (rst_n = '0') THEN
      odat <= RESET_VAL;
    ELSIF (rising_edge(clk)) THEN
      odat <= idat;
    END IF;
  END PROCESS;

END behav;
