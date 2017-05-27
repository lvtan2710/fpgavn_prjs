-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : sdp_ram.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This is Simple Dual Port RAM with these features:
--  + Support Inferred RAM with write & read access after 1 clock cycle
--  + support implementation using IP Cores of :
--      - Block Memory Generator (Xilinx)
--      - IP Catalog which using altsyncram (Altera)\
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

ENTITY sdp_bram IS
  
  GENERIC (
    G_CLRENA    : INTEGER := 0;         -- Clear Content RAM Enable. 0: disable, 1: enable
    G_FAMILY    : STRING  := "XILINX";  -- XILINX, ALTERA
    G_DEVICE    : STRING  := "zynq";    -- zynq, 7series, virtex7, kintex7, artix7,
                                        -- Cyclone V
    G_TYPE      : STRING  := "INFER";   -- INFER, BLOCK, LUT

    G_WRADDR    : INTEGER := 10;
    G_WRWIDTH   : INTEGER := 16;
    G_WRDEPTH   : INTEGER := 1024;
    G_RDADDR    : INTEGER := 10;
    G_RDWIDTH   : INTEGER := 16;
    G_RDDEPTH   : INTEGER := 1024;
    G_RST_VAL   : INTEGER := 0;         -- Reset value for RAM (note: range -2,147,483,647 to +2,147,483,647)
    
    -- Xilinx's Attributes
    X_ALGORITHM : INTEGER := 1;         -- 0: fixed primitive, 1: Minimum area, 2: low power
    X_PRIM_TYPE : INTEGER := 1;         -- 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
    X_WR_MODE   : STRING  := "NO_CHANGE";  -- WRITE_FIRST, READ_FIRST, NO_CHANGE
    X_MEM_REG   : INTEGER := 0;
    X_MUX_REG   : INTEGER := 0;
    X_PIPELINE  : INTEGER := 0;
    
    -- Altera's Attributes
    A_REG_EN    : STRING  := "CLOCK1";  -- CLOCK1, UNREGISTERED
    A_WR_MODE   : STRING  := "NEW_DATA_WITH_NBE_READ";   -- NEW_DATA_NO_NBE_READ (X on masked byte), DONT_CARE
                                                         -- NEW_DATA_WITH_NBE_READ (old data on masked byte)
    A_MAXDEPTH  : INTEGER := 1024;
    A_BRAM_TYPE : STRING  := "Auto"     -- Auto, M10K, M9K,
    );
  PORT (
    wclk        : IN  STD_LOGIC;
    rst_n       : IN  STD_LOGIC;
    clr         : IN  STD_LOGIC;
    clrrdy      : OUT STD_LOGIC;
    wen         : IN  STD_LOGIC;
    wadd        : IN  STD_LOGIC_VECTOR(G_WRADDR-1 DOWNTO 0);
    wdat        : IN  STD_LOGIC_VECTOR(G_WRWIDTH-1 DOWNTO 0);
    rclk        : IN  STD_LOGIC;
    radd        : IN  STD_LOGIC_VECTOR(G_RDADDR-1 DOWNTO 0);
    rdat        : OUT STD_LOGIC_VECTOR(G_RDWIDTH-1 DOWNTO 0)
    );
    
END sdp_bram;

ARCHITECTURE behav OF sdp_bram IS
  
  CONSTANT C_RST_VAL : STD_LOGIC_VECTOR(G_WRWIDTH-1 DOWNTO 0) := conv_std_logic_vector(G_RST_VAL, G_WRWIDTH);
  SIGNAL i_we        : STD_LOGIC := '0';
  SIGNAL i_di        : STD_LOGIC_VECTOR(G_WRWIDTH-1 DOWNTO 0);
  SIGNAL i_addr      : STD_LOGIC_VECTOR(G_WRADDR-1 DOWNTO 0);

  SIGNAL clrwe       : STD_LOGIC;
  SIGNAL clraddr     : STD_LOGIC_VECTOR(G_WRADDR-1 DOWNTO 0);
  
  -----------------------------------------------------------------------------
  -- Component Declaration
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

  COMPONENT sdp_bram_inf IS
    GENERIC (
    G_ADDR      : INTEGER := 8;
    G_WIDTH     : INTEGER := 32
    );

  PORT (
    clka        : IN  STD_LOGIC;
    wea         : IN  STD_LOGIC;
    addra       : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    dia         : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    clkb        : IN  STD_LOGIC;
    addrb       : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    dob         : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
    );
  END COMPONENT sdp_bram_inf;
  
  COMPONENT alt_sdp_bram IS
    GENERIC (
    G_WRADDR    : INTEGER := 10;
    G_WRWIDTH   : INTEGER := 32;
    G_WRDEPTH   : INTEGER := 1024;
    G_RDADDR    : INTEGER := 10;
    G_RDWIDTH   : INTEGER := 32;
    G_RDDEPTH   : INTEGER := 1024;
    G_DEVICE    : STRING  := "Cyclone V";
    
    A_REG_EN    : STRING  := "CLOCK1";  -- CLOCK1, UNREGISTERED
    A_WR_MODE   : STRING  := "NEW_DATA_NO_NBE_READ"; -- DONT_CARE, NEW_DATA_NO_NBE_READ
    A_MAXDEPTH  : INTEGER := 1024;
    A_BRAM_TYPE : STRING  := "Auto"     -- Auto, M10K, M9K, 
    );
    
  PORT	(
    data	    : IN STD_LOGIC_VECTOR (G_WRWIDTH-1 DOWNTO 0);
    rdaddress	: IN STD_LOGIC_VECTOR (G_RDADDR-1 DOWNTO 0);
    rdclock		: IN STD_LOGIC ;
    wraddress	: IN STD_LOGIC_VECTOR (G_WRADDR-1 DOWNTO 0);
    wrclock		: IN STD_LOGIC  := '1';
    wren		: IN STD_LOGIC  := '0';
    q		    : OUT STD_LOGIC_VECTOR (G_RDWIDTH-1 DOWNTO 0)
	);
  END COMPONENT alt_sdp_bram;

  COMPONENT xil_sdp_bram IS
    GENERIC (
    G_WRADDR    : INTEGER := 10;
    G_WRWIDTH   : INTEGER := 16;
    G_WRDEPTH   : INTEGER := 1024;
    G_RDADDR    : INTEGER := 10;
    G_RDWIDTH   : INTEGER := 16;
    G_RDDEPTH   : INTEGER := 1024;
    G_DEVICE    : STRING  := "zynq";

    X_ALGORITHM : INTEGER := 1;
    X_PRIM_TYPE : INTEGER := 1;
    X_WR_MODE   : STRING  := "WRITE_FIRST";
    X_MEM_REG   : INTEGER := 0;
    X_MUX_REG   : INTEGER := 0;
    X_PIPELINE  : INTEGER := 0
    );
  
  PORT (
    clka        : IN STD_LOGIC;
    wea         : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra       : IN STD_LOGIC_VECTOR(G_WRADDR-1 DOWNTO 0);
    dina        : IN STD_LOGIC_VECTOR(G_WRWIDTH-1 DOWNTO 0);
    clkb        : IN STD_LOGIC;
    addrb       : IN STD_LOGIC_VECTOR(G_RDADDR-1 DOWNTO 0);
    doutb       : OUT STD_LOGIC_VECTOR(G_RDWIDTH-1 DOWNTO 0)
  );
  END COMPONENT xil_sdp_bram;

  COMPONENT alt_sdp_lutram_lc IS
    GENERIC (
    G_ADDR      : INTEGER := 10;
    G_WIDTH     : INTEGER := 32;
    G_DEPTH     : INTEGER := 1024;
    G_DEVICE    : STRING  := "Cyclone V";
    A_REG_EN    : STRING  := "UNREGISTERED"
    );
    
  PORT	(
    data	    : IN STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
    rdaddress	: IN STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
    rdclock		: IN STD_LOGIC;
    wraddress	: IN STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
    wrclock		: IN STD_LOGIC;
    wren		: IN STD_LOGIC;
    q		    : OUT STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0)
	);
  END COMPONENT alt_sdp_lutram_lc;

  COMPONENT alt_sdp_lutram_mlab IS
    GENERIC (
    G_ADDR      : INTEGER := 10;
    G_WIDTH     : INTEGER := 32;
    G_DEPTH     : INTEGER := 1024;
    G_DEVICE    : STRING  := "Cyclone V";
    A_REG_EN    : STRING  := "UNREGISTERED"
    );
    
  PORT	(
    data	    : IN STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
    rdaddress	: IN STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
    rdclock		: IN STD_LOGIC;
    wraddress	: IN STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
    wrclock		: IN STD_LOGIC;
    wren		: IN STD_LOGIC;
    q		    : OUT STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0)
	);
  END COMPONENT alt_sdp_lutram_mlab;

  COMPONENT xil_sdp_lutram IS
    GENERIC (
    G_ADDR      : INTEGER := 10;
    G_WIDTH     : INTEGER := 16;
    G_DEPTH     : INTEGER := 1024;
    G_DEVICE    : STRING  := "zynq";
    X_PIPELINE  : INTEGER := 0
    );
  
  PORT (
    clk         : IN STD_LOGIC;
    we          : IN STD_LOGIC;
    a           : IN STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    d           : IN STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
    qdpo_clk    : IN STD_LOGIC;
    dpra        : IN STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
    qdpo        : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
  );
  END COMPONENT xil_sdp_lutram;

BEGIN  -- behav

  -- RESET RAM
  gen_ram_reset: IF (G_CLRENA = 1) GENERATE
    inst_ram_rst_ctrl : ram_rst_ctrl
      GENERIC MAP (
        G_ADDR      => G_WRADDR,
        G_DEPTH     => G_WRDEPTH)
      PORT MAP (
        clk         => wclk,
        rst_n       => rst_n,
        clrena      => clr,
        clrrdy      => clrrdy,
        clrwe       => clrwe,
        clraddr     => clraddr);

    i_we    <= clrwe OR wen;
    i_addr  <= clraddr WHEN (clrwe = '1') ELSE wadd;
    i_di    <= C_RST_VAL WHEN (clrwe = '1') ELSE wdat;
  END GENERATE gen_ram_reset;

  no_gen_ram_rst_ctrl: IF (G_CLRENA = 0) GENERATE
    clrrdy  <= '1';
    i_we    <= wen;
    i_addr  <= wadd;
    i_di    <= wdat;
  END GENERATE no_gen_ram_rst_ctrl;

  -- Instantiate Block RAM
  gen_sdp_bram_inf: IF (G_TYPE = "INFER") GENERATE
    inst_sdp_bram_inf: sdp_bram_inf
      GENERIC MAP (
        G_ADDR      => G_WRADDR,
        G_WIDTH     => G_WRWIDTH)
      PORT MAP (
        clka        => wclk,
        wea         => i_we,
        addra       => i_addr,
        dia         => i_di,
        clkb        => rclk,
        addrb       => radd,
        dob         => rdat);
  END GENERATE gen_sdp_bram_inf;

  gen_xil_sdp_bram: IF ((G_FAMILY = "XILINX") AND (G_TYPE = "BLOCK")) GENERATE
    inst_xil_sdp_bram: xil_sdp_bram    -- ENTITY work.
      GENERIC MAP (
        G_WRADDR    => G_WRADDR,
        G_WRWIDTH   => G_WRWIDTH,
        G_WRDEPTH   => G_WRDEPTH,
        G_RDADDR    => G_RDADDR,
        G_RDWIDTH   => G_RDWIDTH,
        G_RDDEPTH   => G_RDDEPTH,
        G_DEVICE    => G_DEVICE,

        X_ALGORITHM => X_ALGORITHM,
        X_PRIM_TYPE => X_PRIM_TYPE,
        X_WR_MODE   => X_WR_MODE,
        X_MEM_REG   => X_MEM_REG,
        X_MUX_REG   => X_MUX_REG,
        X_PIPELINE  => X_PIPELINE)
      PORT MAP (
        clka        => wclk,
        wea(0)      => i_we,
        addra       => i_addr,
        dina        => i_di,
        clkb        => rclk,
        addrb       => radd,
        doutb       => rdat);      
  END GENERATE gen_xil_sdp_bram;

  gen_alt_sdp_bram: IF ((G_FAMILY = "ALTERA") AND (G_TYPE = "BLOCK")) GENERATE
    inst_alt_sdp_bram: alt_sdp_bram
      GENERIC MAP (
        G_WRADDR    => G_WRADDR,
        G_WRWIDTH   => G_WRWIDTH,
        G_WRDEPTH   => G_WRDEPTH,
        G_RDADDR    => G_RDADDR,
        G_RDWIDTH   => G_RDWIDTH,
        G_RDDEPTH   => G_RDDEPTH,
        G_DEVICE    => G_DEVICE,
        
        A_REG_EN    => A_REG_EN,
        A_WR_MODE   => A_WR_MODE,
        A_MAXDEPTH  => A_MAXDEPTH,
        A_BRAM_TYPE => A_BRAM_TYPE)
      PORT MAP (
        wrclock     => wclk,
        wren        => i_we,
        wraddress   => i_addr,
        data        => i_di,
        rdclock     => rclk,
        rdaddress   => radd,
        q           => rdat);
  END GENERATE gen_alt_sdp_bram;

  gen_xil_sdp_lutram: IF ((G_FAMILY = "XILINX") AND (G_TYPE = "LUT")) GENERATE
    inst_xil_sdp_lutram: xil_sdp_lutram    -- ENTITY work.
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        X_PIPELINE  => X_PIPELINE)
      PORT MAP (
        clk         => wclk,
        we          => i_we,
        a           => i_addr,
        d           => i_di,
        qdpo_clk    => rclk,
        dpra        => radd,
        qdpo        => rdat);      
  END GENERATE gen_xil_sdp_lutram;

  gen_alt_sdp_lutram_lc: IF ((G_FAMILY = "ALTERA") AND (G_TYPE = "LUT") AND (A_BRAM_TYPE = "LC") GENERATE
    inst_alt_sdp_lutram_lc: alt_sdp_lutram_lc
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        A_REG_EN    => A_REG_EN)
      PORT MAP (
        wrclock     => wclk,
        wren        => i_we,
        wraddress   => i_addr,
        data        => i_di,
        rdclock     => rclk,
        rdaddress   => radd,
        q           => rdat);
  END GENERATE gen_alt_sdp_lutram_lc;

  gen_alt_sdp_lutram_mlab: IF ((G_FAMILY = "ALTERA") AND (G_TYPE = "LUT") AND (A_BRAM_TYPE = "MLAB") GENERATE
    inst_alt_sdp_lutram_mlab: alt_sdp_lutram_mlab
      GENERIC MAP (
        G_ADDR      => G_ADDR,
        G_WIDTH     => G_WIDTH,
        G_DEPTH     => G_DEPTH,
        G_DEVICE    => G_DEVICE,
        A_REG_EN    => A_REG_EN)
      PORT MAP (
        wrclock     => wclk,
        wren        => i_we,
        wraddress   => i_addr,
        data        => i_di,
        rdclock     => rclk,
        rdaddress   => radd,
        q           => rdat);
  END GENERATE gen_alt_sdp_lutram_mlab;
  
END behav;
