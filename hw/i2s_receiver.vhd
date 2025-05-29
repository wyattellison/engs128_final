----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S receiver for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (
        adc_serial_data_i     : in std_logic;
        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0)
		);  
end i2s_receiver;
----------------------------------------------------------------------------
architecture Behavioral of i2s_receiver is

--Signals
signal load_en_int : std_logic := '0';
signal count_rst_int : std_logic := '0';
signal load_done_int : std_logic := '0';

--Components
component i2s_receiver_controller is
    Generic (
        DATA_WIDTH : integer := AC_DATA_WIDTH
    );
    Port (
        lrclk_i : in std_logic;
        bclk_i : in std_logic;
        load_done_i : in std_logic;
        
        load_en_o : out std_logic;
        count_rst_o : out std_logic
    );
end component;

component i2s_receiver_load_register is
    Generic (
        DATA_WIDTH : integer := AC_DATA_WIDTH
    );
    Port ( 
        adc_serial_data_i : in std_logic;
        lrclk_i : in std_logic;
        load_en_i : in std_logic;
        count_rst_i : in std_logic;
        bclk_i : in std_logic;
         
        left_audio_data_o : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        right_audio_data_o : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        load_done_o : out std_logic
    );
end component;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
rx_controller : i2s_receiver_controller 
    Port map(
        lrclk_i => lrclk_i,
        bclk_i => bclk_i,
        load_done_i => load_done_int, 
           
        load_en_o => load_en_int,
        count_rst_o => count_rst_int
    );
    
load_register :  i2s_receiver_load_register 
    Port map( 
        adc_serial_data_i => adc_serial_data_i,
        lrclk_i => lrclk_i,
        load_en_i  => load_en_int,
        count_rst_i => count_rst_int,
        bclk_i => bclk_i,
         
        left_audio_data_o => left_audio_data_o,
        right_audio_data_o => right_audio_data_o,
        load_done_o => load_done_int
    );
---------------------------------------------------------------------------- 
end Behavioral;