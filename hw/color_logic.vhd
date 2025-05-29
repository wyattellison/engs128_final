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
        X_CURSOR_WIDTH : integer := 11; --num of bits for cursor pos
        Y_CURSOR_WIDTH : integer := 10
    );
    Port ( 
        x_in : in unsigned (X_CURSOR_WIDTH - 1 downto 0);
        y_in : in unsigned (Y_CURSOR_WIDTH - 1 downto 0);
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0)
    );
end color_logic;

architecture Behavioral of color_logic is

signal red_int, green_int, blue_int : std_logic_vector(7 downto 0) := (others => '0');

begin


red_int <= std_logic_vector(75 + y_in(Y_CURSOR_WIDTH - 1 downto 2));  --divide it by four
green_int <= std_logic_vector(175 - y_in(Y_CURSOR_WIDTH - 1 downto 3) + x_in(X_CURSOR_WIDTH - 1 downto 4)); --div row by 8, col by 16
blue_int <= std_logic_vector(255 - y_in(Y_CURSOR_WIDTH - 1 downto 3) + x_in(X_CURSOR_WIDTH - 1 downto 4)); --div row by 16, col by 16


rgb_out <= red_int & green_int & blue_int;

end Behavioral;
