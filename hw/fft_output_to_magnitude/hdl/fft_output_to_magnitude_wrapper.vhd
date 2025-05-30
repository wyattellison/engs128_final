--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
--Date        : Mon May 26 15:04:44 2025
--Host        : c011-01 running 64-bit major release  (build 9200)
--Command     : generate_target fft_output_to_magnitude_wrapper.bd
--Design      : fft_output_to_magnitude_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity fft_output_to_magnitude_wrapper is
  port (
    fft_abs_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fft_axis_data_i : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
end fft_output_to_magnitude_wrapper;

architecture STRUCTURE of fft_output_to_magnitude_wrapper is
  component fft_output_to_magnitude is
  port (
    fft_abs_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fft_axis_data_i : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component fft_output_to_magnitude;
begin
fft_output_to_magnitude_i: component fft_output_to_magnitude
     port map (
      fft_abs_o(31 downto 0) => fft_abs_o(31 downto 0),
      fft_axis_data_i(31 downto 0) => fft_axis_data_i(31 downto 0)
    );
end STRUCTURE;
