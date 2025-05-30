----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity cursor_amp_to_rgb is
    Generic(
        AMP_WIDTH : integer := 8;   --same as number of bits for fft bins
        AMP_NORM_WIDTH : integer := 9;  --number of bits to normalize to. 
        CURSOR_WIDTH : integer := 32
    );
    Port ( 
        x_cursor_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
        y_cursor_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_height : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_width : in unsigned (CURSOR_WIDTH - 1 downto 0);
        is_top_i : in STD_LOGIC;
        valid_x_i : in std_logic;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        dbg_i : in std_logic;
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0);
        
        clk_i : in std_logic
    );
end cursor_amp_to_rgb;

architecture Behavioral of cursor_amp_to_rgb is

--Constants

signal norm_signal_amp_int : unsigned(AMP_NORM_WIDTH - 1 downto 0) := (others => '0');  --normalize amplitude to screen height
signal is_black : std_logic := '1';
signal draw_pixel : std_logic := '0';
   
signal rgb_int : std_logic_vector(23 downto 0) := (others => '1');  --to start, debug to white

component color_logic is
    Generic (
        CURSOR_WIDTH : integer := CURSOR_WIDTH --num of bits for cursor pos
    );
    Port ( 
        x_in : in unsigned (CURSOR_WIDTH - 1 downto 0);
        y_in : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_width : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_height : in unsigned (CURSOR_WIDTH - 1 downto 0);
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0)
    );
end component;

begin
--Make color selector
color_select : color_logic
    Port map(
        x_in => x_cursor_i,
        y_in => y_cursor_i,
        monitor_width => monitor_width,
        monitor_height => monitor_height,
        rgb_out => rgb_int
    );

--Create internal norm signal
amp_scale : process (amp_i) begin
    if AMP_NORM_WIDTH > AMP_WIDTH then --if I want it to be wider than the input amplitude
        norm_signal_amp_int(AMP_NORM_WIDTH - 1 downto AMP_NORM_WIDTH - AMP_WIDTH) <= amp_i; --scale it up
    elsif AMP_NORM_WIDTH < AMP_WIDTH then   --if I need it to be narrower
        norm_signal_amp_int <= amp_i(AMP_WIDTH - 1 downto AMP_WIDTH - AMP_NORM_WIDTH); --scale it down (drop LSB)
    else
        norm_signal_amp_int <= amp_i;   --if perfect match, just keep
    end if;
end process amp_scale;

--Check if should be black
check_black : process (y_cursor_i, is_top_i, valid_x_i, norm_signal_amp_int) 
    variable effective_amp : unsigned(AMP_NORM_WIDTH - 1 downto 0); --the effective ampltiude to display
begin
    --Decide which amp we are using
    if (valid_x_i = '0') then
        effective_amp := to_unsigned(5, AMP_NORM_WIDTH);  --hard code, just how many pixels tall a dead x is
    else
        effective_amp := norm_signal_amp_int;
    end if;
    
    --Check the amps
    if (is_top_i = '1') then  --if on top half (y cursor is less than mid)
        if (monitor_height(CURSOR_WIDTH -1 downto 1) - y_cursor_i < effective_amp) then --if the y cursor is closer to midline than amp calls for
            is_black <= '0';
        else
            is_black <= '1';
        end if;  
    else
        if (y_cursor_i - monitor_height(CURSOR_WIDTH -1 downto 1) < effective_amp) then --if the y cursor is closer to midline than amp calls for
            is_black <= '0';
        else
            is_black <= '1';
        end if;
    end if;
end process check_black;
draw_pixel <= (not(is_black) or dbg_i);

--Check / assign RGB
rgb_reg : process(clk_i) begin
    if rising_edge(clk_i) then
        if (draw_pixel = '0') then    
            rgb_out <= (others => '0'); --make it black
        else
            rgb_out <= rgb_int;
        end if;
    end if;
end process rgb_reg;



end Behavioral;
