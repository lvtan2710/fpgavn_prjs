-------------------------------------------------------------------------------
-- Company    : FPGAVN.COM
-- Department : FPGA Design Dept
-- Project    : 
-- File       : tdp_ram.vhd
-- Author     : LE VAN TAN
-- Email	  : fpgavn@fpgavn.com
-- Created    : 2017-05-27
-- Description: This is True Dual Port RAM with these features:
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
--
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

ENTITY tdp_bram IS
  
  GENERIC (
    G_ADDR_A    : INTEGER := 10;
    G_WIDTH_A   : INTEGER := 16;
    G_DEPTH_A   : INTEGER := 1024;
    G_ADDR_B    : INTEGER := 10;
    G_WIDTH_B   : INTEGER := 16;
    G_DEPTH_B   : INTEGER := 1024;
    G_COMMONCLK : INTEGER := 0;

    G_CLRENA    : INTEGER := 0;         -- Clear Content RAM Enable. 0: disable, 1: enable
    G_RST_VAL   : INTEGER := 0;         -- Reset value for RAM (note: range -2,147,483,647 to +2,147,483,647)
    G_FAMILY    : STRING  := "XILINX";  -- XILINX, ALTERA
    G_DEVICE    : STRING  := "zynq";    -- zynq, 7series, virtex7, kintex7, artix7,
                                        -- Cyclone V
    G_IMPL_TYPE : STRING  := "INFER";   -- INFER, IPCORE (Using macro will be implemented with individual modules)

    -- Xilinx's Attributes
    X_ALGORITHM : INTEGER := 1;         -- 0: fixed primitive, 1: Minimum area, 2: low power
    X_PRIM_TYPE : INTEGER := 1;         -- 0: 1x16k, 1: 2x8k, 2: 4x4k, 3: 9x2k, 4: 18x1k, 5: 36x512, 6: 72x512
    X_WR_MODE   : STRING  := "NO_CHANGE";  -- WRITE_FIRST, READ_FIRST, NO_CHANGE
    X_MEM_REG   : INTEGER := 0;
    X_MUX_REG   : INTEGER := 0;
    X_PIPELINE  : INTEGER := 0;
    
    -- Altera's Attributes
    A_REG_EN_A  : STRING  := "CLOCK0";  -- CLOCK0, UNREGISTERED; Source Clock for port A
    A_REG_EN_B  : STRING  := "CLOCK1";  -- CLOCK1, UNREGISTERED; Source Clock for port B
    A_WR_MODE   : STRING  := "NEW_DATA_WITH_NBE_READ";   -- NEW_DATA_NO_NBE_READ (X on masked byte), DONT_CARE
                                                         -- NEW_DATA_WITH_NBE_READ (old data on masked byte)
    A_MAXDEPTH  : INTEGER := 1024;
    A_BRAM_TYPE : STRING  := "AUTO"     -- AUTO, M10K, M9K,
    );
  PORT (
    clk_a       : IN  STD_LOGIC;
    rst_n       : IN  STD_LOGIC;
    clr         : IN  STD_LOGIC;
    clrrdy      : OUT STD_LOGIC;
    wen_a       : IN  STD_LOGIC;
    add_a       : IN  STD_LOGIC_VECTOR(G_ADDR_A-1 DOWNTO 0);
    wdat_a      : IN  STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0);
    rdat_a      : OUT STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0);
    clk_b       : IN  STD_LOGIC;
    wen_b       : IN  STD_LOGIC;
    add_b       : IN  STD_LOGIC_VECTOR(G_ADDR_B-1 DOWNTO 0);
    wdat_b      : IN  STD_LOGIC_VECTOR(G_WIDTH_B-1 DOWNTO 0);
    rdat_b      : OUT STD_LOGIC_VECTOR(G_WIDTH_B-1 DOWNTO 0)
    );

END tdp_bram;

ARCHITECTURE behav OF tdp_bram IS

  CONSTANT C_RST_VAL : STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0) := conv_std_logic_vector(G_RST_VAL, G_WIDTH_A);

  SIGNAL i_we   : STD_LOGIC;
  SIGNAL i_di   : STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0);
  SIGNAL i_addr : STD_LOGIC_VECTOR(G_ADDR_A-1 DOWNTO 0);

  SIGNAL clrwe  : STD_LOGIC;
  SIGNAL clraddr : STD_LOGIC_VECTOR(G_ADDR_A-1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Component Declaration
  -----------------------------------------------------------------------------
  COMPONENT ram_rst_ctrl IS
    GENERIC (
      G_ADDR      : INTEGER := 8;
      G_DEPTH     : INTEGER := 256
      );

    PORT (
      clk         : IN  STD_LOGIC;
      rst_n       : IN  STD_LOGIC;
      clrena      : IN  STD_LOGIC;
      clrrdy      : OUT STD_LOGIC;
      clrwe       : OUT STD_LOGIC;
      clraddr     : OUT STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0)
      );
  END COMPONENT ram_rst_ctrl;
  
  COMPONENT tdp_bram_inf IS
    GENERIC (
      G_ADDR      : INTEGER := 10;
      G_WIDTH     : INTEGER := 32
      );
    PORT (
      clka        : IN  STD_LOGIC;
      wea         : IN  STD_LOGIC;
      addra       : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
      dia         : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      doa         : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      clkb        : IN  STD_LOGIC;
      web         : IN  STD_LOGIC;
      addrb       : IN  STD_LOGIC_VECTOR(G_ADDR-1 DOWNTO 0);
      dib         : IN  STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0);
      dob         : OUT STD_LOGIC_VECTOR(G_WIDTH-1 DOWNTO 0)
      );
  END COMPONENT tdp_bram_inf;

  COMPONENT alt_tdp_bram IS
    GENERIC (
      G_ADDR_A    : INTEGER := 10;
      G_WIDTH_A   : INTEGER := 16;
      G_DEPTH_A   : INTEGER := 1024;
      G_ADDR_B    : INTEGER := 10;
      G_WIDTH_B   : INTEGER := 16;
      G_DEPTH_B   : INTEGER := 1024;
      G_DEVICE    : STRING  := "zynq";
      G_COMMONCLK : INTEGER := 0;

      A_REG_EN_A  : STRING  := "CLOCK0";  -- CLOCK0, UNUSED
      A_REG_EN_B  : STRING  := "CLOCK1";  -- CLOCK0, CLOCK1, UNUSED
      A_WR_MODE   : STRING  := "NEW_DATA_NO_NBE_READ"; -- DONT_CARE, NEW_DATA_NO_NBE_READ
      A_MAXDEPTH  : INTEGER := 1024;
      A_BRAM_TYPE : STRING  := "AUTO"     -- AUTO, M10K, M9K, 
      );
    PORT (
      address_a	  : IN STD_LOGIC_VECTOR (G_ADDR_A-1 DOWNTO 0);
      address_b	  : IN STD_LOGIC_VECTOR (G_ADDR_B-1 DOWNTO 0);
      data_a	  : IN STD_LOGIC_VECTOR (G_WIDTH_A-1 DOWNTO 0);
      data_b	  : IN STD_LOGIC_VECTOR (G_WIDTH_B-1 DOWNTO 0);
      inclock	  : IN STD_LOGIC  := '1';
      outclock	  : IN STD_LOGIC;
      wren_a	  : IN STD_LOGIC  := '0';
      wren_b	  : IN STD_LOGIC  := '0';
      q_a		  : OUT STD_LOGIC_VECTOR (G_WIDTH_A-1 DOWNTO 0);
      q_b		  : OUT STD_LOGIC_VECTOR (G_WIDTH_B-1 DOWNTO 0)
      );
  END COMPONENT alt_tdp_bram;

  COMPONENT xil_tdp_bram IS
    GENERIC (
      G_ADDR_A    : INTEGER := 10;
      G_WIDTH_A   : INTEGER := 16;
      G_DEPTH_A   : INTEGER := 1024;
      G_ADDR_B    : INTEGER := 10;
      G_WIDTH_B   : INTEGER := 16;
      G_DEPTH_B   : INTEGER := 1024;
      G_DEVICE    : STRING  := "zynq";
      G_COMMONCLK : INTEGER := 0;

      X_ALGORITHM : INTEGER := 1;
      X_PRIM_TYPE : INTEGER := 1;
      X_WR_MODE   : STRING  := "WRITE_FIRST";
      X_MEM_REG   : INTEGER := 0;
      X_MUX_REG   : INTEGER := 0;
      X_PIPELINE  : INTEGER := 0
      );
    PORT (
      clka        : IN  STD_LOGIC;
      wea         : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra       : IN  STD_LOGIC_VECTOR(G_ADDR_A-1 DOWNTO 0);
      dina        : IN  STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0);
      douta       : OUT STD_LOGIC_VECTOR(G_WIDTH_A-1 DOWNTO 0);
      clkb        : IN  STD_LOGIC;
      web         : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
      addrb       : IN  STD_LOGIC_VECTOR(G_ADDR_B-1 DOWNTO 0);
      dinb        : IN  STD_LOGIC_VECTOR(G_WIDTH_B-1 DOWNTO 0);
      doutb       : OUT STD_LOGIC_VECTOR(G_WIDTH_B-1 DOWNTO 0)
      );
  END COMPONENT xil_tdp_bram;

BEGIN  -- behav

  -- RESET RAM
  gen_ram_reset: IF (G_CLRENA = 1) GENERATE
    inst_ram_rst_ctrl : ram_rst_ctrl
      GENERIC MAP (
        G_ADDR      => G_ADDR_A,
        G_DEPTH     => G_DEPTH_A)
      PORT MAP (
        clk         => clk_a,
        rst_n       => rst_n,
        clrena      => clr,
        clrrdy      => clrrdy,
        clrwe       => clrwe,
        clraddr     => clraddr);

    i_we    <= clrwe OR wen_a;
    i_addr  <= clraddr WHEN (clrwe = '1') ELSE add_a;
    i_di    <= C_RST_VAL WHEN (clrwe = '1') ELSE wdat_a;
  END GENERATE gen_ram_reset;

  no_gen_ram_rst_ctrl: IF (G_CLRENA = 0) GENERATE
    clrrdy  <= '1';
    i_we    <= wen_a;
    i_addr  <= add_a;
    i_di    <= wdat_a;
  END GENERATE no_gen_ram_rst_ctrl;

  -- Instantiate Block RAM
  gen_tdp_bram_inf: IF (G_IMPL_TYPE = "INFER") GENERATE
    inst_tdp_bram_inf: tdp_bram_inf
      GENERIC MAP (
        G_ADDR      => G_ADDR_A,
        G_WIDTH     => G_WIDTH_A
        )
      PORT MAP (
        clka        => clk_a,
        wea         => i_we,
        addra       => i_addr,
        dia         => i_di,
        doa         => rdat_a,
        clkb        => clk_b,
        web         => wen_b,
        addrb       => add_b,
        dib         => wdat_b,
        dob         => rdat_b
        );
  END GENERATE gen_tdp_bram_inf;

  gen_xil_tdp_bram: IF ((G_FAMILY = "XILINX") AND (G_IMPL_TYPE = "IPCORE")) GENERATE
    inst_xil_tdp_bram: xil_tdp_bram
      GENERIC MAP (
        G_ADDR_A    => G_ADDR_A,
        G_WIDTH_A   => G_WIDTH_A,
        G_DEPTH_A   => G_DEPTH_A,
        G_ADDR_B    => G_ADDR_B,
        G_WIDTH_B   => G_WIDTH_B,
        G_DEPTH_B   => G_DEPTH_B,
        G_DEVICE    => G_DEVICE,
        G_COMMONCLK => G_COMMONCLK,

        X_ALGORITHM => X_ALGORITHM,
        X_PRIM_TYPE => X_PRIM_TYPE,
        X_WR_MODE   => X_WR_MODE,
        X_MEM_REG   => X_MEM_REG,
        X_MUX_REG   => X_MUX_REG,
        X_PIPELINE  => X_PIPELINE
        )
      PORT MAP (
        clka        => clk_a,
        wea(0)      => i_we,
        addra       => i_addr,
        dina        => i_di,
        douta       => rdat_a,
        clkb        => clk_b,
        web(0)      => wen_b,
        addrb       => add_b,
        dinb        => wdat_b,
        doutb       => rdat_b
        );      
  END GENERATE gen_xil_tdp_bram;

  gen_alt_tdp_bram: IF ((G_FAMILY = "ALTERA") AND (G_IMPL_TYPE = "IPCORE")) GENERATE
    inst_alt_tdp_bram: alt_tdp_bram
      GENERIC MAP (
        G_ADDR_A    => G_ADDR_A,
        G_WIDTH_A   => G_WIDTH_A,
        G_DEPTH_A   => G_DEPTH_A,
        G_ADDR_B    => G_ADDR_B,
        G_WIDTH_B   => G_WIDTH_B,
        G_DEPTH_B   => G_DEPTH_B,
        G_DEVICE    => G_DEVICE,
        G_COMMONCLK => G_COMMONCLK,
        
        A_REG_EN_A  => A_REG_EN_A,
        A_REG_EN_B  => A_REG_EN_B,
        A_WR_MODE   => A_WR_MODE,
        A_MAXDEPTH  => A_MAXDEPTH,
        A_BRAM_TYPE => A_BRAM_TYPE
        )
      PORT MAP (
        inclock     => clk_a,
        wren_a      => i_we,
        address_a   => i_addr,
        data_a      => i_di,
        q_a         => rdat_a,
        outclock    => clk_b,
        wren_b      => wen_b,
        address_b   => add_b,
        data_b      => wdat_b,
        q_b         => rdat_b
        );  
  END GENERATE gen_alt_tdp_bram;
  
END behav;
