-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : sp_ram.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This IP is Single Port RAM with these features:
--  + Implemented in Inferred method for both Xilinx & Altera FPGA Family with 
--    3 modes:
--      - WRITE_FIRST
--      - READ_FIRST
--      - NO_CHANGE (default)
--      _ Write & read after 1 clock cycle
--  + Support implementation which using IP Cores:
--      - Block Memory Generator (Xilinx)
--      - IP Catalog which using altsyncram (Altera)
--  + WRITE_WIDTH = READ_WIDTH (If user need different WIDTH, Xilinx can support
--    and user must design by different module)
--  + Xilinx can add 2 clock cycles and Altera add 1 clock cycle at the output.
--  + Altera IP Core has 3 write modes which depend on type of memory (p12,13 
--    user guide) but in Single Port RAM, new data flows through to output:
--      - Don't care
--      - New data
--      - Old data
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author		Description
-- 2017-05-27  1.0      LE VAN TAN	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.numeric_std.ALL;

ENTITY sp_ram IS
  
  GENERIC (
    G_CLRENA    : INTEGER := 0;         -- Clear Content RAM Enable. 0: disable, 1: enable
    G_FAMILY    : STRING  := "XILINX";  -- XILINX, ALTERA
    G_DEVICE    : STRING  := "zynq";    -- zynq, 7series, virtex7, kintex7, artix7,
                                        -- Cyclone V
    
    G_TYPE      : STRING  := "INFER";   -- INFER(default), BLOCK, LUT
    G_ADDR      : INTEGER := 10;
    G_WIDTH     : INTEGER := 16;
    G_DEPTH     : INTEGER := 1024;
    G_RST_VAL   : INTEGER := 0;         -- Reset value for RAM (note: range -2,147,483,647 to +2,147,483,647)
    
    -- Xilinx's Attributes
    X_ALGORITHM : INTEGER := 1;         -- 0: fixed primitive, 1: Minimum area, 2: low power
    X_PRIM_TYPE : INTEGER := 1;         -- 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
    X_WR_MODE   : STRING  := "NO_CHANGE";   -- WRITE_FIRST, READ_FIRST, NO_CHANGE
    X_MEM_REG   : INTEGER := 0;
    X_MUX_REG   : INTEGER := 0;
    X_PIPELINE  : INTEGER := 0;

    -- Altera's Attributes
    A_REG_EN    : STRING  := "CLOCK0";      -- CLOCK0, UNREGISTERED
    A_WR_MODE   : STRING  := "DONT_CARE ";  -- DONT_CARE(default)
                                            -- NEW_DATA_NO_NBE_READ (X on masked byte),
                                            -- OLD_DATA (support for BRAM)
    A_MAXDEPTH  : INTEGER := 1024;
    A_BRAM_TYPE : STRING  := "AUTO"    -- AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
                                       -- M512 blocks are not supported in true dual-port RAM mode
                                       -- MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode 
    );
  PORT (
    clk         : IN  STD_LOGIC;
    rst_n       : IN  STD_LOGIC;
    clr         : IN  STD_LOGIC;
    clrrdy      : OUT STD_LOGIC;
    we          : IN  STD_LOGIC;
    addr        : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    din         : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    dout        : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
    );

END sp_ram;

ARCHITECTURE behav OF sp_ram IS

  CONSTANT C_RST_VAL : STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0) := conv_std_logic_vector(G_RST_VAL, G_WIDTH);
  SIGNAL i_we   : STD_LOGIC := '0';
  SIGNAL i_di   : STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
  SIGNAL i_addr : STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);

  SIGNAL clrwe   : STD_LOGIC;
  SIGNAL clraddr : STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  COMPONENT ram_rst_ctrl IS
    GENERIC (
      G_ADDR    : INTEGER := 8;
      G_DEPTH   : INTEGER := 256
      );
    PORT (
      clk       : IN  STD_LOGIC;
      rst_n     : IN  STD_LOGIC;
      clrena    : IN  STD_LOGIC;
      clrrdy    : OUT STD_LOGIC;
      clrwe     : OUT STD_LOGIC;
      clraddr   : OUT STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0)
      );
  END COMPONENT ram_rst_ctrl;
    
  COMPONENT sp_bram_inf IS
    GENERIC (
      G_ADDR    : INTEGER := 6;
      G_WIDTH   : INTEGER := 16;
      G_MODE    : STRING  := "NO_CHANGE" -- READ_FIRST, WRITE_FIRST, NO_CHANGE
      );     
    PORT (
      clk       : IN  STD_LOGIC;
      we        : IN  STD_LOGIC;
      addr      : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
      din       : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      dout      : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
      );
  END COMPONENT sp_bram_inf;

  COMPONENT xil_sp_bram IS
    GENERIC (
      G_ADDR      : INTEGER := 10;
      G_WIDTH     : INTEGER := 16;
      G_DEPTH     : INTEGER := 1024;
      G_DEVICE    : STRING  := "zynq";
      X_ALGORITHM : INTEGER := 1;
      X_PRIM_TYPE : INTEGER := 1;
      X_WR_MODE   : STRING  := "WRITE_FIRST";
      X_MEM_REG   : INTEGER := 0;
      X_MUX_REG   : INTEGER := 0;
      X_PIPELINE  : INTEGER := 0
      );
    PORT (
      clka      : IN  STD_LOGIC;
      wea       : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra     : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
      dina      : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      douta     : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
      );
  END COMPONENT xil_sp_bram;

  COMPONENT alt_sp_bram IS
    GENERIC (
      G_ADDR      : INTEGER := 11;
      G_WIDTH     : INTEGER := 32;
      G_DEPTH     : INTEGER := 2048;
      G_DEVICE    : STRING  := "Cyclone V";
      A_REG_EN    : STRING  := "CLOCK0";  -- CLOCK0, UNREGISTERED
      A_WR_MODE   : STRING  := "NEW_DATA_NO_NBE_READ"; -- DONT_CARE, NEW_DATA_NO_NBE_READ
      A_MAXDEPTH  : INTEGER := 1024;
      A_BRAM_TYPE : STRING  := "AUTO"   -- AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
                                        -- M512 blocks are not supported in true dual-port RAM mode
                                        -- MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode 
      );
    PORT (
      address	: IN  STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
      clock	    : IN  STD_LOGIC  := '1';
      data	    : IN  STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
      wren	    : IN  STD_LOGIC ;
      q		    : OUT STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0)
      );    
  END COMPONENT alt_sp_bram;

  COMPONENT xil_sp_lutram IS
    GENERIC (
      G_ADDR      : INTEGER := 7;
      G_WIDTH     : INTEGER := 16;
      G_DEPTH     : INTEGER := 128;
      G_DEVICE    : STRING  := "zynq";
      X_PIPELINE  : INTEGER := 0
      );
    PORT (
      clk       : IN  STD_LOGIC;
      we        : IN  STD_LOGIC;
      a         : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
      d         : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      qspo      : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
      );
  END COMPONENT xil_sp_lutram;

  COMPONENT alt_sp_lutram IS
    GENERIC (
      G_ADDR      : INTEGER := 7;
      G_WIDTH     : INTEGER := 16;
      G_DEPTH     : INTEGER := 128;
      G_DEVICE    : STRING  := "Cyclone V";
      A_REG_EN    : STRING  := "CLOCK0";      -- CLOCK0, UNREGISTERED
      A_WR_MODE   : STRING  := "DONT_CARE"    -- DONT_CARE(default), NEW_DATA_NO_NBE_READ
      );
    PORT (
      address	: IN  STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
      clock	    : IN  STD_LOGIC  := '1';
      data	    : IN  STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
      wren	    : IN  STD_LOGIC ;
      q		    : OUT STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0)
      );    
  END COMPONENT alt_sp_lutram;
  
BEGIN  -- behav

  -- RESET RAM
  gen_ram_reset: IF (G_CLRENA = 1) GENERATE
    inst_ram_rst_ctrl : ram_rst_ctrl
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_DEPTH     => 2**G_ADDR)
      PORT MAP (
        clk         => clk,
        rst_n       => rst_n,
        clrena      => clr,
        clrrdy      => clrrdy,
        clrwe       => clrwe,
        clraddr     => clraddr);

    i_we    <= clrwe OR we;
    i_addr  <= clraddr WHEN (clrwe = '1') ELSE addr;
    i_di    <= C_RST_VAL WHEN (clrwe = '1') ELSE din;
  END GENERATE gen_ram_reset;

  no_gen_ram_rst_ctrl: IF (G_CLRENA = 0) GENERATE
    clrrdy  <= '1';
    i_we    <= we;
    i_addr  <= addr;
    i_di    <= din;
  END GENERATE no_gen_ram_rst_ctrl;
  
  -- Instantiate Block RAM
  gen_xil_sp_bram: IF ((G_FAMILY = "XILINX") AND (G_TYPE = "BLOCK")) GENERATE
    inst_xil_sp_bram: xil_sp_bram
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        X_ALGORITHM => X_ALGORITHM,
        X_PRIM_TYPE => X_PRIM_TYPE,
        X_WR_MODE   => X_WR_MODE,
        X_MEM_REG   => X_MEM_REG,
        X_MUX_REG   => X_MUX_REG,
        X_PIPELINE  => X_PIPELINE
        )
      PORT MAP (
        clka        => clk,
        wea(0)      => i_we,
        addra       => i_addr,
        dina        => i_di,
        douta       => dout);      
  END GENERATE gen_xil_sp_bram;

  gen_alt_sp_bram: IF ((G_FAMILY = "ALTERA") AND (G_TYPE = "BLOCK")) GENERATE
    inst_alt_sp_bram: alt_sp_bram
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        A_REG_EN    => A_REG_EN,
        A_WR_MODE   => A_WR_MODE,
        A_MAXDEPTH  => A_MAXDEPTH,
        A_BRAM_TYPE => A_BRAM_TYPE
        )
      PORT MAP (
        clock       => clk,
        wren        => i_we,
        address     => i_addr,
        data        => i_di,
        q           => dout);
  END GENERATE gen_alt_sp_bram;

  gen_xil_sp_lutram: IF ((G_FAMILY = "XILINX") AND (G_TYPE = "LUT")) GENERATE
    inst_xil_sp_lutram: xil_sp_lutram
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        X_PIPELINE  => X_PIPELINE
        )
      PORT MAP (
        clk         => clk,
        we          => i_we,
        a           => i_addr,
        d           => i_di,
        qspo        => dout);      
  END GENERATE gen_xil_sp_lutram;

  gen_alt_sp_lutram: IF ((G_FAMILY = "ALTERA") AND (G_TYPE = "LUT")) GENERATE
    inst_alt_sp_lutram: alt_sp_lutram
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE
        )
      PORT MAP (
        clock       => clk,
        wren        => i_we,
        address     => i_addr,
        data        => i_di,
        q           => dout);
  END GENERATE gen_alt_sp_lutram;

  gen_sp_bram_inf: IF (G_TYPE = "INFER") GENERATE
    inst_sp_bram_inf: sp_bram_inf
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_MODE      => X_WR_MODE)
      PORT MAP (
        clk         => clk,
        we          => i_we,
        addr        => i_addr,
        din         => i_di,
        dout        => dout);
  END GENERATE gen_sp_bram_inf;
  
END behav;
