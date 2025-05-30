--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
--Date        : Mon May 26 15:04:44 2025
--Host        : c011-01 running 64-bit major release  (build 9200)
--Command     : generate_target fft_output_to_magnitude.bd
--Design      : fft_output_to_magnitude
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity fft_output_to_magnitude is
  port (
    fft_abs_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fft_axis_data_i : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of fft_output_to_magnitude : entity is "fft_output_to_magnitude,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=fft_output_to_magnitude,x_ipVersion=1.00.a,x_ipLanguage=VHDL,numBlks=5,numReposBlks=5,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_clkrst_cnt=2,synth_mode=OOC_per_IP}";
  attribute HW_HANDOFF : string;
  attribute HW_HANDOFF of fft_output_to_magnitude : entity is "fft_output_to_magnitude.hwdef";
end fft_output_to_magnitude;

architecture STRUCTURE of fft_output_to_magnitude is
  component fft_output_to_magnitude_xlslice_0_0 is
  port (
    Din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    Dout : out STD_LOGIC_VECTOR ( 15 downto 0 )
  );
  end component fft_output_to_magnitude_xlslice_0_0;
  component fft_output_to_magnitude_xlslice_1_0 is
  port (
    Din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    Dout : out STD_LOGIC_VECTOR ( 15 downto 0 )
  );
  end component fft_output_to_magnitude_xlslice_1_0;
  component fft_output_to_magnitude_mult_gen_0_0 is
  port (
    A : in STD_LOGIC_VECTOR ( 15 downto 0 );
    B : in STD_LOGIC_VECTOR ( 15 downto 0 );
    P : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component fft_output_to_magnitude_mult_gen_0_0;
  component fft_output_to_magnitude_mult_gen_1_0 is
  port (
    A : in STD_LOGIC_VECTOR ( 15 downto 0 );
    B : in STD_LOGIC_VECTOR ( 15 downto 0 );
    P : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component fft_output_to_magnitude_mult_gen_1_0;
  component fft_output_to_magnitude_c_addsub_0_0 is
  port (
    A : in STD_LOGIC_VECTOR ( 31 downto 0 );
    B : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component fft_output_to_magnitude_c_addsub_0_0;
  signal Din_0_1 : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal c_addsub_0_S : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal mult_gen_0_P : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal mult_gen_1_P : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal xlslice_0_Dout : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal xlslice_1_Dout : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of fft_abs_o : signal is "xilinx.com:signal:data:1.0 DATA.FFT_ABS_O DATA";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of fft_abs_o : signal is "XIL_INTERFACENAME DATA.FFT_ABS_O, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 32} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type generated dependency signed format bool minimum {} maximum {}} value TRUE}}}} DATA_WIDTH 32}";
begin
  Din_0_1(31 downto 0) <= fft_axis_data_i(31 downto 0);
  fft_abs_o(31 downto 0) <= c_addsub_0_S(31 downto 0);
c_addsub_0: component fft_output_to_magnitude_c_addsub_0_0
     port map (
      A(31 downto 0) => mult_gen_0_P(31 downto 0),
      B(31 downto 0) => mult_gen_1_P(31 downto 0),
      S(31 downto 0) => c_addsub_0_S(31 downto 0)
    );
mult_gen_0: component fft_output_to_magnitude_mult_gen_0_0
     port map (
      A(15 downto 0) => xlslice_1_Dout(15 downto 0),
      B(15 downto 0) => xlslice_1_Dout(15 downto 0),
      P(31 downto 0) => mult_gen_0_P(31 downto 0)
    );
mult_gen_1: component fft_output_to_magnitude_mult_gen_1_0
     port map (
      A(15 downto 0) => xlslice_0_Dout(15 downto 0),
      B(15 downto 0) => xlslice_0_Dout(15 downto 0),
      P(31 downto 0) => mult_gen_1_P(31 downto 0)
    );
xlslice_0: component fft_output_to_magnitude_xlslice_0_0
     port map (
      Din(31 downto 0) => Din_0_1(31 downto 0),
      Dout(15 downto 0) => xlslice_0_Dout(15 downto 0)
    );
xlslice_1: component fft_output_to_magnitude_xlslice_1_0
     port map (
      Din(31 downto 0) => Din_0_1(31 downto 0),
      Dout(15 downto 0) => xlslice_1_Dout(15 downto 0)
    );
end STRUCTURE;
