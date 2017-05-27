-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : pstatusx.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is used as a macro for status register with just
-- able to read only. The status from engine is updated online and continuously
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY pstatusx IS
  
  GENERIC (
    WIDTH   : INTEGER := 8);

  PORT (
    clk     : IN  STD_LOGIC;
    rst_n   : IN  STD_LOGIC;
    sta_in  : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
    sta_vld : IN  STD_LOGIC;
    upen    : IN  STD_LOGIC;
    uprs    : IN  STD_LOGIC;
    updo    : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
    upack   : OUT STD_LOGIC);

END pstatusx;

ARCHITECTURE behav OF pstatusx IS

  -----------------------------------------------------------------------------
  -- Signal Delaration
  -----------------------------------------------------------------------------
  SIGNAL rd_en   : STD_LOGIC;
  SIGNAL sta_reg : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
BEGIN  -- behav
  rd_en <= upen AND uprs;
  
  update_status: PROCESS (clk)
  BEGIN  -- process update_status
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        sta_reg <= (OTHERS => '0');
      ELSIF (sta_vld = '1') THEN
        sta_reg <= sta_in;
      END IF;
    END IF;
  END PROCESS update_status;

  updo  <= sta_reg;
  
  ackgen_pro: PROCESS (clk)
  BEGIN  -- process data_out_pro
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        upack <= '0';
      ELSE
        upack <= rd_en;
      END IF;
    END IF;
  END PROCESS data_out_pro;
  
END behav;
