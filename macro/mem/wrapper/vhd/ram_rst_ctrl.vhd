-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : ram_rst_ctrl.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ram_rst_ctrl IS
  
  GENERIC (
    G_ADDR  : INTEGER := 8;
    G_DEPTH : INTEGER := 256);

  PORT (
    clk    : IN  STD_LOGIC;
    rst_n  : IN  STD_LOGIC;
    clrena : IN  STD_LOGIC;
    clrrdy : OUT STD_LOGIC;
    clrwe  : OUT STD_LOGIC;
    clraddr: OUT STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0));

END ram_rst_ctrl;

ARCHITECTURE behav OF ram_rst_ctrl IS

  SIGNAL count      : STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL reg_clrwe  : STD_LOGIC;
    
BEGIN  -- behav

  PROCESS (clk)
  BEGIN  -- PROCESS
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        count <= (OTHERS => '0');
      ELSIF (clrena = '1') THEN
        count <= (OTHERS => '0');
      ELSIF (reg_clrwe = '1') THEN
        count <= count + 1;
      ELSE
        count <= count;        
      END IF;
    END IF;
  END PROCESS;

  clraddr <= count;

  PROCESS (clk)
  BEGIN  -- PROCESS
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        reg_clrwe <= '0';
      ELSIF (clrena = '1') THEN
        reg_clrwe <= '1';
      ELSIF (count = G_DEPTH-1) THEN
        reg_clrwe <= '0';
      ELSE
        reg_clrwe <= reg_clrwe;
      END IF;
    END IF;
  END PROCESS;

  clrwe  <= reg_clrwe;
  clrrdy <= NOT reg_clrwe;

END behav;
