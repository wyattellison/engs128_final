----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: Datapath (shift reg+counter) for I2S Transmitter
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity i2s_transmitter_shift_register is
    Generic (
        DATA_WIDTH : integer := 24
    );
    Port (
        left_audio_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        right_audio_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        bclk_i : in std_logic;
        lrclk_i : in std_logic;
        shift_en_i : in std_logic;
        load_en_i : in std_logic;
        count_rst_i : in std_logic;
        
        dac_serial_data_o : out std_logic;
        count_tc_o : out std_logic
    );
end i2s_transmitter_shift_register;

architecture Behavioral of i2s_transmitter_shift_register is

--Signals
signal audio_data_int : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal to_shift_data_int : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal count_int : integer range 0 to DATA_WIDTH - 1 := 0;


begin
--Processes

counter : process(bclk_i) begin
    if falling_edge(bclk_i) then
        if (count_rst_i = '1') then
            count_int <= 0;
        elsif (shift_en_i = '1') then
            if (count_int = DATA_WIDTH - 1) then   --when we hit the TC
                count_int <= 0; --reset 
            else
                count_int <= count_int + 1;
            end if;
        end if;
    end if;
end process counter;
count_tc_o <= '1' when (count_int >= (DATA_WIDTH - 1)) else '0';

shifter : process(bclk_i) begin
    if falling_edge(bclk_i) then
        if (load_en_i = '1') then
            to_shift_data_int <= audio_data_int;
        elsif (shift_en_i = '1') then
            to_shift_data_int <= to_shift_data_int(DATA_WIDTH - 2 downto 0) & to_shift_data_int(DATA_WIDTH - 1);
        else
            to_shift_data_int <= to_shift_data_int;
        end if;
    end if;
end process shifter;
dac_serial_data_o <= to_shift_data_int(DATA_WIDTH - 1); --drive out the MSB
audio_data_int <= left_audio_data_i when (lrclk_i = '0') else right_audio_data_i; --select which audio we are porting in (internal signal)

end Behavioral;
