-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : a_dff_nclk.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is asynchronous D-flipflop which output is
-- presented after n clock delay.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY a_dff_nclk IS
  
  GENERIC (
    DELAY : INTEGER := 3);              -- Delay 3 clock cycles

  PORT (
    clk   : IN  STD_LOGIC;
    rst_n : IN  STD_LOGIC;
    d0    : IN  STD_LOGIC;
    qn    : OUT STD_LOGIC
    );

END a_dff_nclk;

ARCHITECTURE behav OF a_dff_nclk IS
  
  COMPONENT a_pl_reg
    GENERIC (
      SIZE      : NATURAL RANGE 2 TO 512;
      RST_VAL   : STD_LOGIC_VECTOR(511 DOWNTO 0)
      );
    PORT (
      clk       : IN  STD_LOGIC;
      rst_n     : IN  STD_LOGIC;
      idat      : IN  STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0);
      odat      : OUT STD_LOGIC_VECTOR(SIZE-1 DOWNTO 0)
      );
  END COMPONENT;

  COMPONENT a_dff
    GENERIC (
      RST_VAL   : STD_LOGIC := '0'
    );
    PORT (
      clk       : IN  STD_LOGIC;
      rst_n     : IN  STD_LOGIC;
      d         : IN  STD_LOGIC;
      q         : OUT STD_LOGIC
    );
  END COMPONENT;
  
  SIGNAL shift : STD_LOGIC_VECTOR(DELAY-1 DOWNTO 0);

BEGIN  -- behav

  DELAY_0: IF (DELAY = 0) GENERATE
    qn <= d0;
  END GENERATE DELAY_0;

  DELAY_1: IF (DELAY = 1) GENERATE
    d_fflop: a_dff
      GENERIC MAP (
        SIZE    => SIZE)
      PORT MAP (
        clk     => clk,
        rst_n   => rst_n,
        d       => d0,
        q       => shift
        );
    qn <= shift;
  END GENERATE DELAY_1;

  DELAY_N: IF (DELAY > 1) GENERATE
    shift: a_pl_reg
      GENERIC MAP (
        SIZE    => SIZE)
      PORT MAP (
        clk     => clk,
        rst_n   => rst_n,
        idat    => (shift(DELAY-2 DOWNTO 0) & d0),
        odat    => shift
        );
    qn <= shift(DELAY-1);
  END GENERATE DELAY_N;
  
END behav;
