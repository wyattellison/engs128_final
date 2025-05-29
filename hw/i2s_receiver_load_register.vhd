----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: I2S Receiver Datapath for ENGS128 Lab 1. Doing all in one file
-- which is a little ugly, but keeping file count down
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity i2s_receiver_load_register is
    Generic (
        DATA_WIDTH : integer := 24
    );
    Port ( 
        adc_serial_data_i : in std_logic;
        lrclk_i : in std_logic;
        load_en_i : in std_logic;
        count_rst_i : in std_logic;
        bclk_i : in std_logic;
         
        left_audio_data_o : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        right_audio_data_o : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        load_done_o : out std_logic);
end i2s_receiver_load_register;

architecture Behavioral of i2s_receiver_load_register is

--Signals
signal left_data_int : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal right_data_int : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal count_int : integer range 0 to DATA_WIDTH - 1:= 0;

begin

--Processes
counter : process(bclk_i) begin
    if rising_edge(bclk_i) then
        if (count_rst_i = '1') then
            count_int <= 0;
        elsif (load_en_i = '1') then
            if (count_int = DATA_WIDTH - 1) then   --when we hit the TC
                count_int <= 0; --reset 
            else
                count_int <= count_int + 1;
            end if;
        end if;
    end if;
end process counter;
load_done_o <= '1' when (count_int >= (DATA_WIDTH - 1)) else '0';

left_reg : process(bclk_i) begin
    if rising_edge(bclk_i) then
        if (load_en_i = '1' and lrclk_i = '0') then --if enabled and bringing in left
            left_data_int <= left_data_int(DATA_WIDTH - 2 downto 0) & adc_serial_data_i; --shift in MSB first, then LSB last
        else
            left_data_int <= left_data_int; --hold data otherwise
        end if;
        
        if (lrclk_i = '1') then --swap to bringing in right, so left is done
            left_audio_data_o <= left_data_int;
        end if;
    end if;
end process left_reg;

right_reg : process(bclk_i) begin
    if rising_edge(bclk_i) then
        if (load_en_i = '1' and lrclk_i = '1') then --if enabled and bringing in right
            right_data_int <= right_data_int(DATA_WIDTH - 2 downto 0) & adc_serial_data_i; --shift in MSB first, then LSB last
        else
            right_data_int <= right_data_int; --hold data otherwise
        end if;
        
        if (lrclk_i = '0') then
            right_audio_data_o <= right_data_int;
        end if;
    end if;
end process right_reg;


end Behavioral;
