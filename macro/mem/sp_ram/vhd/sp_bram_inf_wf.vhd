-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : sp_bram_inf_wf.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This is the single port RAM which is implemented in Xilinx/Altera
--  Block RAM. There are 3 ways to incorporate RAM into a design:
--  + Inference
--  + Core Generator
--  + Instantiation
--  In this design, Inference method are used.
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sp_bram_inf_wf IS
  
  GENERIC (
    G_ADDR  : INTEGER := 6;
    G_WIDTH : INTEGER := 16);

  PORT (
    clk  : IN  STD_LOGIC;
    we   : IN  STD_LOGIC;
    addr : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    din  : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0));

END sp_bram_inf_wf;

ARCHITECTURE behav OF sp_bram_inf_wf IS

  CONSTANT C_DEPTH : INTEGER := 2**G_ADDR;
  TYPE ram_type IS ARRAY (C_DEPTH-1 DOWNTO 0) OF STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
  SIGNAL RAM : ram_type;
  
BEGIN  -- behav

  PROCESS (clk)
  BEGIN  -- PROCESS
    IF (rising_edge(clk)) THEN
      IF (we = '1') THEN
        RAM(conv_integer(addr)) <= din;
        dout <= din;
      ELSE
        dout <= RAM(conv_integer(addr));
      END IF;
    END IF;
  END PROCESS;

END behav;
