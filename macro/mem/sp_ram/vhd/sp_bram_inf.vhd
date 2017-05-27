-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : sp_bram_inf.vhd
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

ENTITY sp_bram_inf IS
  
  GENERIC (
    G_ADDR  : INTEGER := 6;
    G_WIDTH : INTEGER := 16;
    G_MODE  : STRING := "NO_CHANGE");     -- READ_FIRST, WRITE_FIRST, NO_CHANGE

  PORT (
    clk  : IN  STD_LOGIC;
    we   : IN  STD_LOGIC;
    addr : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    din  : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0));

END sp_bram_inf;

ARCHITECTURE behav OF sp_bram_inf IS

BEGIN  -- behav

  gen_sp_bram_inf_rf: IF (G_MODE = "READ_FIRST") GENERATE
    sp_bram_inf_rf: ENTITY work.sp_bram_inf_rf
      GENERIC MAP (
        G_ADDR  => G_ADDR,
        G_WIDTH => G_WIDTH)
      PORT MAP (
        clk     => clk,
        we      => we,
        addr    => addr,
        din     => din,
        dout    => dout);
  END GENERATE gen_sp_bram_inf_rf;
  
  gen_sp_bram_inf_wf: IF (G_MODE = "WRITE_FIRST") GENERATE
    sp_bram_inf_wf: ENTITY work.sp_bram_inf_wf
      GENERIC MAP (
        G_ADDR  => G_ADDR,
        G_WIDTH => G_WIDTH)
      PORT MAP (
        clk     => clk,
        we      => we,
        addr    => addr,
        din     => din,
        dout    => dout);
  END GENERATE gen_sp_bram_inf_wf;
  
  gen_sp_bram_inf_nc: IF (G_MODE = "WRITE_FIRST") GENERATE
    sp_bram_inf_nc: ENTITY work.sp_bram_inf_nc
      GENERIC MAP (
        G_ADDR  => G_ADDR,
        G_WIDTH => G_WIDTH)
      PORT MAP (
        clk     => clk,
        we      => we,
        addr    => addr,
        din     => din,
        dout    => dout);
  END GENERATE gen_sp_bram_inf_nc;
  
END behav;
