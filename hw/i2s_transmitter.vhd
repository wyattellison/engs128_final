----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: I2S Transmitter for ENGS128 Lab 1
----------------------------------------------------------------------------

-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end i2s_transmitter;
----------------------------------------------------------------------------
architecture Behavioral of i2s_transmitter is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------

--Signals
signal shift_en_int : std_logic := '0';
signal load_en_int : std_logic := '0';
signal count_rst_int : std_logic := '0';
signal count_tc_int : std_logic := '0';

--Components
component i2s_transmitter_controller is
    Generic(
        DATA_WIDTH : integer := AC_DATA_WIDTH
    );
    Port(
        lrclk_i : in STD_LOGIC;
        count_tc_i : in STD_LOGIC;
        bclk_i : in std_logic;
        mclk_i : in std_logic;
           
        shift_en_o : out STD_LOGIC;
        load_en_o : out STD_LOGIC;
        count_rst_o : out STD_LOGIC
    );
end component;

component i2s_transmitter_shift_register is
    Generic(
        DATA_WIDTH : integer := AC_DATA_WIDTH
    );
    Port(
        left_audio_data_i : in std_logic_vector(AC_DATA_WIDTH - 1 downto 0);
        right_audio_data_i : in std_logic_vector(AC_DATA_WIDTH - 1 downto 0);
        bclk_i : in std_logic;
        lrclk_i : in std_logic;
        shift_en_i : in std_logic;
        load_en_i : in std_logic;
        count_rst_i : in std_logic;
        
        dac_serial_data_o : out std_logic;
        count_tc_o : out std_logic
    );
end component;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
controller : i2s_transmitter_controller 
    Port map(
        lrclk_i => lrclk_i,
        count_tc_i => count_tc_int,
        bclk_i => bclk_i,
        mclk_i => mclk_i, 
           
        shift_en_o => shift_en_int,
        load_en_o => load_en_int,
        count_rst_o => count_rst_int
    );
    

shift_register : i2s_transmitter_shift_register
    Port map(
        left_audio_data_i => left_audio_data_i,
        right_audio_data_i => right_audio_data_i,
        bclk_i => bclk_i,
        lrclk_i => lrclk_i,
        shift_en_i => shift_en_int,
        load_en_i => load_en_int,
        count_rst_i => count_rst_int,
        
        dac_serial_data_o => dac_serial_data_o,
        count_tc_o => count_tc_int
    );


---------------------------------------------------------------------------- 
end Behavioral;