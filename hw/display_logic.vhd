----------------------------------------------------------------------------------
--  ENGS128 - Display Logic
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity display_logic is
    Generic (
        PIXEL_V : integer := 720;
        PIXEL_H : integer := 1280;
        
        --Number of bits
        NUM_H_BITS : integer := 11; --number of bits to span the active window horizontally
        NUM_V_BITS : integer := 10;    --to span active window y
        NUM_FFT_BINS_BITS : integer := 8;    --also signal amplitude bit number
        
        --Shifting values to center items and keep us in base 2
        DEAD_VERT : integer := 104;  --monitor height / 2, then difference to nearest base 2 number (down)
        DEAD_HORIZ : integer := 128;    --monitor width /2  difference to nearest base 2
        DEAD_PIXEL_AMP : integer := 4   --how tall we want 'dead' signals (the left and right bars) to be
    );
    Port (
        pixel_clk : in std_logic;
        pixel_x_i : in unsigned(NUM_H_BITS - 1 downto 0);
        pixel_y_i : in unsigned(NUM_V_BITS - 1 downto 0);
        left_amp_i : in unsigned(NUM_FFT_BINS_BITS - 1 downto 0);
        right_amp_i : in unsigned(NUM_FFT_BINS_BITS - 1 downto 0);
        freq_bin_o : out unsigned(NUM_FFT_BINS_BITS - 1 downto 0);
        red_o : out std_logic_vector(7 downto 0);
        green_o : out std_logic_vector(7 downto 0);
        blue_o : out std_logic_vector(7 downto 0)
    );    
end display_logic;

architecture Behavioral of display_logic is

constant NUM_ACTIVE_V_BITS : integer := integer(ceil(log2(real(PIXEL_V - (DEAD_VERT*2))))); --(defaut: 9) number of bits that make up our active central plane
--constant NUM_ACTIVE_H_BITS : integer := integer(ceil(log2(real(PIXEL_H - (DEAD_HORIZ*2))))); --(default: 10)
constant PIXEL_H_CENTER : unsigned := to_unsigned(PIXEL_V / 2, NUM_V_BITS - 1);  --(default: 360) center is height divided by two (loses a bit)

signal is_top_half : std_logic := '1';  --whether it is top half of screen or bottom
signal signal_amp_int : unsigned(NUM_FFT_BINS_BITS - 1 downto 0) := (others => '0');
signal norm_signal_amp_int : unsigned(NUM_ACTIVE_V_BITS - 1 downto 0) := (others => '0');  --normalize amplitude to screen height
signal red_int, green_int, blue_int : std_logic_vector(7 downto 0) := (others => '0');


begin
is_top_half <= '1' when pixel_y_i < PIXEL_H_CENTER else '0';
signal_amp_int <= left_amp_i when is_top_half = '0' else right_amp_i;

amp_scale : process (signal_amp_int) begin
    if NUM_ACTIVE_V_BITS > NUM_FFT_BINS_BITS then
        norm_signal_amp_int <= signal_amp_int * (2 ** (NUM_ACTIVE_V_BITS - NUM_FFT_BINS_BITS));
    elsif NUM_ACTIVE_V_BITS < NUM_FFT_BINS_BITS then
        norm_signal_amp_int <= signal_amp_int / (2 ** (NUM_FFT_BINS_BITS - NUM_ACTIVE_V_BITS));
    else
        norm_signal_amp_int <= signal_amp_int;
    end if;
    --Scale the signal amp as needed. From FFT we can get max the number of bins, and we want that to be able to fill our height
    --Also want to handle if we are scaling up or down
end process amp_scale;

--Color writing process/logic
red_int <= std_logic_vector(to_unsigned(255 * to_integer(pixel_y_i) / PIXEL_V, 8));   --map the y value to the red value (down is more red)
green_int <= std_logic_vector(to_unsigned(128 - (128 * to_integer(pixel_y_i) / PIXEL_V) + (128 * to_integer(pixel_x_i) / PIXEL_H), 8)); --top right full -> bottom left none
blue_int <= std_logic_vector(to_unsigned(255 - (128 * to_integer(pixel_y_i) / PIXEL_V) - (128 * to_integer(pixel_x_i) / PIXEL_H), 8)); --top left full -> bottom right none

write_colors : process (pixel_clk) begin
    if rising_edge(pixel_clk) then
        --default black (maybe change for debugging
        red_o <= (others => '0');
        green_o <= (others => '0');
        blue_o <= (others => '0');
        --First check if we are in a deadzone
        if ( (pixel_x_i < DEAD_HORIZ) or (pixel_x_i > (PIXEL_H - DEAD_HORIZ) )) then  --we are to the left of our 'drawing range' or right
            if ( (pixel_x_i < PIXEL_H_CENTER + DEAD_PIXEL_AMP) and (pixel_x_i > PIXEL_H_CENTER - DEAD_PIXEL_AMP) ) then
                red_o <= red_int;
                green_o <= green_int;
                blue_o <= blue_int;
            end if;
        else    --we are in the drawing range
            if (is_top_half = '1') then --if we are on top half (right audio)
                if (PIXEL_H_CENTER - pixel_y_i < norm_signal_amp_int) then
                    red_o <= red_int;
                    green_o <= green_int;
                    blue_o <= blue_int;
                end if;
            else    --bottom is left audio
                if (pixel_y_i - PIXEL_H_CENTER < norm_signal_amp_int) then
                    red_o <= red_int;
                    green_o <= green_int;
                    blue_o <= blue_int;
                end if;
            end if;
        end if;
    end if;
end process write_colors;

end Behavioral;
