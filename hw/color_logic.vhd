----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity color_logic is
    Generic (
        CURSOR_WIDTH : integer := 32 --num of bits for cursor pos
    );
    Port ( 
        x_in : in unsigned (CURSOR_WIDTH - 1 downto 0);
        y_in : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_width : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_height : in unsigned (CURSOR_WIDTH - 1 downto 0);
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0)
    );
end color_logic;

architecture Behavioral of color_logic is

signal red_int, green_int, blue_int : integer := 0;
signal dbg_x_div, dbg_y_div : integer := 0;

signal dbg_red_y, dbg_green_y, dbg_green_x, dbg_blue_x, dbg_blue_y : integer := 0;

begin

dbg_x_div <= to_integer(x_in(CURSOR_WIDTH - 1 downto 3));
dbg_y_div <= to_integer(y_in(CURSOR_WIDTH - 1 downto 2));

red_int   <= 100 + to_integer(y_in(CURSOR_WIDTH - 1 downto 2));
green_int <= 175 - dbg_y_div + dbg_x_div;
blue_int  <= 255 - dbg_y_div - dbg_x_div;

rgb_out <= std_logic_vector(to_unsigned(red_int, 8) & to_unsigned(blue_int, 8) & to_unsigned(green_int, 8));

end Behavioral;
