-- megafunction wizard: %RAM: 1-PORT%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altsyncram 

-- ============================================================
-- File Name: alt_sp_bram.vhd
-- Megafunction Name(s):
-- 			altsyncram
--
-- Simulation Library Files(s):
-- 			altera_mf
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 15.0.0 Build 145 04/22/2015 SJ Web Edition
-- ************************************************************


--Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, the Altera Quartus II License Agreement,
--the Altera MegaCore Function License Agreement, or other 
--applicable license agreement, including, without limitation, 
--that your use is for the sole purpose of programming logic 
--devices manufactured by Altera and sold by Altera or its 
--authorized distributors.  Please refer to the applicable 
--agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY alt_sp_bram IS
  
  GENERIC (
    G_ADDR      : INTEGER := 11;
    G_WIDTH     : INTEGER := 32;
    G_DEPTH     : INTEGER := 2048;
    G_DEVICE    : STRING  := "Cyclone V";
    A_REG_EN    : STRING  := "CLOCK0";  -- CLOCK0, UNREGISTERED
    A_WR_MODE   : STRING  := "DONT_CARE"; -- DONT_CARE(default), NEW_DATA_NO_NBE_READ, OLD_DATA
    A_MAXDEPTH  : INTEGER := 0;
    A_BRAM_TYPE : STRING  := "AUTO"     -- AUTO, M512, M4K, M-RAM, MLAB, M9K, M144K, M10K, M20K, LC
                                        -- M512 blocks are not supported in true dual-port RAM mode
                                        -- MLAB blocks are not supported in simple dual-port RAM mode with mixed-width port feature, true dual-port RAM mode, and dual-port ROM mode 
    );
  PORT (
    address	: IN  STD_LOGIC_VECTOR (G_ADDR-1 DOWNTO 0);
    clock	: IN  STD_LOGIC  := '1';
    data	: IN  STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
    wren	: IN  STD_LOGIC ;
    q		: OUT STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0));
  
END alt_sp_bram;


ARCHITECTURE SYN OF alt_sp_bram IS

  SIGNAL    sub_wire0	: STD_LOGIC_VECTOR (G_WIDTH-1 DOWNTO 0);
  
BEGIN
	q(G_WIDTH-1 DOWNTO 0)    <= sub_wire0(G_WIDTH-1 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		clock_enable_input_a            => "BYPASS",
		clock_enable_output_a           => "BYPASS",
		intended_device_family          => G_DEVICE,
		lpm_hint                        => "ENABLE_RUNTIME_MOD=NO",
		lpm_type                        => "altsyncram",
        maximum_depth                   => A_MAXDEPTH,
		numwords_a                      => G_DEPTH,
		operation_mode                  => "SINGLE_PORT",
		outdata_aclr_a                  => "NONE",
		outdata_reg_a                   => A_REG_EN,
		power_up_uninitialized          => "FALSE",
        ram_block_type                  => A_BRAM_TYPE,
		read_during_write_mode_port_a   => A_WR_MODE,
		widthad_a                       => G_ADDR,
		width_a                         => G_WIDTH,
		width_byteena_a                 => 1
	)
	PORT MAP (
		address_a   => address,
		clock0      => clock,
		data_a      => data,
		wren_a      => wren,
		q_a         => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
-- Retrieval info: PRIVATE: AclrAddr NUMERIC "0"
-- Retrieval info: PRIVATE: AclrByte NUMERIC "0"
-- Retrieval info: PRIVATE: AclrData NUMERIC "0"
-- Retrieval info: PRIVATE: AclrOutput NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_ENABLE NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
-- Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
-- Retrieval info: PRIVATE: Clken NUMERIC "0"
-- Retrieval info: PRIVATE: DataBusSeparated NUMERIC "1"
-- Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
-- Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_A"
-- Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
-- Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
-- Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
-- Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
-- Retrieval info: PRIVATE: MIFfilename STRING ""
-- Retrieval info: PRIVATE: NUMWORDS_A NUMERIC "1024"
-- Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
-- Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_PORT_A NUMERIC "2"
-- Retrieval info: PRIVATE: RegAddr NUMERIC "1"
-- Retrieval info: PRIVATE: RegData NUMERIC "1"
-- Retrieval info: PRIVATE: RegOutput NUMERIC "0"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
-- Retrieval info: PRIVATE: SingleClock NUMERIC "1"
-- Retrieval info: PRIVATE: UseDQRAM NUMERIC "1"
-- Retrieval info: PRIVATE: WRCONTROL_ACLR_A NUMERIC "0"
-- Retrieval info: PRIVATE: WidthAddr NUMERIC "10"
-- Retrieval info: PRIVATE: WidthData NUMERIC "16"
-- Retrieval info: PRIVATE: rden NUMERIC "0"
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: CONSTANT: CLOCK_ENABLE_INPUT_A STRING "BYPASS"
-- Retrieval info: CONSTANT: CLOCK_ENABLE_OUTPUT_A STRING "BYPASS"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
-- Retrieval info: CONSTANT: LPM_HINT STRING "ENABLE_RUNTIME_MOD=NO"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
-- Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "1024"
-- Retrieval info: CONSTANT: OPERATION_MODE STRING "SINGLE_PORT"
-- Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "NONE"
-- Retrieval info: CONSTANT: OUTDATA_REG_A STRING "UNREGISTERED"
-- Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
-- Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_PORT_A STRING "DONT_CARE"
-- Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "10"
-- Retrieval info: CONSTANT: WIDTH_A NUMERIC "16"
-- Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
-- Retrieval info: USED_PORT: address 0 0 10 0 INPUT NODEFVAL "address[9..0]"
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT VCC "clock"
-- Retrieval info: USED_PORT: data 0 0 16 0 INPUT NODEFVAL "data[15..0]"
-- Retrieval info: USED_PORT: q 0 0 16 0 OUTPUT NODEFVAL "q[15..0]"
-- Retrieval info: USED_PORT: wren 0 0 0 0 INPUT NODEFVAL "wren"
-- Retrieval info: CONNECT: @address_a 0 0 10 0 address 0 0 10 0
-- Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: @data_a 0 0 16 0 data 0 0 16 0
-- Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
-- Retrieval info: CONNECT: q 0 0 16 0 @q_a 0 0 16 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram.bsf TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram_inst.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL alt_sp_bram_syn.v TRUE
-- Retrieval info: LIB_FILE: altera_mf

