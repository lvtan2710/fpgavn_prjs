-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : stickyx.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This module is used as macro for sticky event register. This
-- latch register has 2 features:
--  + Can read latch event.
--  + Write 1 to clear this event
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY stickyx IS
  
  GENERIC (
    WIDTH : INTEGER := 8);

  PORT (
    clk      : IN  STD_LOGIC;
    rst_n    : IN  STD_LOGIC;
    evnt     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
    upact    : IN  STD_LOGIC;
    upen     : IN  STD_LOGIC;
    upws     : IN  STD_LOGIC;
    uprs     : IN  STD_LOGIC;
    updi     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
    updo     : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
    upack    : OUT STD_LOGIC);

END stickyx;

ARCHITECTURE behav OF stickyx IS

  -----------------------------------------------------------------------------
  -- Signal Delaration
  -----------------------------------------------------------------------------
  SIGNAL wr_en, rd_en : STD_LOGIC;
  SIGNAL latch_event  : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  
BEGIN  -- behav
  
  wr_en <= upen AND upws;
  rd_en <= upen AND uprs;
  
  latch_evnt_pro: PROCESS (clk)
  BEGIN  -- process latch_evnt_pro
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        latch_event <= (OTHERS => '0');
      ELSIF (upact = '0') THEN
        IF (wr_en = '1') THEN
          latch_event <= updi;
        END IF;
      ELSIF (wr_en = '1') THEN
        latch_event <= evnt OR (latch_event AND (NOT updi));
      ELSE
        latch_event <= evnt OR latch_event;
      END IF;
    END IF;
  END PROCESS latch_evnt_pro;

  dataout_pro: PROCESS (clk)
  BEGIN  -- process dataout_pro
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        updo <= (OTHERS => '0');
      ELSIF (rd_en = '1') THEN
        updo <= latch_event;
      ELSE
        updo <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS dataout_pro;

  ack_gen_pro: PROCESS (clk)
  BEGIN  -- process ack_gen_pro
    IF (rising_edge(clk)) THEN
      IF (rst_n = '0') THEN
        upack <= '0';
      ELSE
        upack <= wr_en OR rd_en;
      END IF;
    END IF;
  END PROCESS ack_gen_pro;

END behav;
