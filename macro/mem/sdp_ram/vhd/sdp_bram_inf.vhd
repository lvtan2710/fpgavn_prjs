-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : sdp_bram_inf.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This is the simple dual port RAM which is implemented in 3 ways:
--  + Inference
--  + Core Generator
--  + Instantiation (Macro, Primitive)
--  In this design, Inference method is used.
--
-- Limitation:
--  + Write width = Read width
--  + 1 Cycle clock latency. If need more clock latency, pipeline registers must 
-- be implemented out side.
--  + Algorithm for optimal (area, performance, power) depend on setting of 
-- synthesis tool.
--  + Operation mode is only NO_CHANGE
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sdp_bram_inf IS
  
  GENERIC (
    G_ADDR  : INTEGER := 8;
    G_WIDTH : INTEGER := 32);

  PORT (
    clka    : IN  STD_LOGIC;
    wea     : IN  STD_LOGIC;
    addra   : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    dia     : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    clkb    : IN  STD_LOGIC;
    addrb   : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    dob     : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0));

END sdp_bram_inf;

ARCHITECTURE behav OF sdp_bram_inf IS

  CONSTANT C_DEPTH : INTEGER := 2**G_ADDR;
  TYPE ram_type IS ARRAY (C_DEPTH-1 DOWNTO 0) OF STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
  SIGNAL RAM : ram_type;
  
BEGIN  -- behav

  PROCESS (clka)
  BEGIN  -- PROCESS
    IF (rising_edge(clka)) THEN
      IF (wea = '1') THEN
        RAM(conv_integer(addra)) <= dia;
      END IF;
    END IF;
  END PROCESS;

  PROCESS (clkb)
  BEGIN  -- PROCESS
    IF (rising_edge(clkb)) THEN
      dob <= RAM(conv_integer(addrb));
    END IF;
  END PROCESS;

END behav;

