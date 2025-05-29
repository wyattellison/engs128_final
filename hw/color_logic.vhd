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

signal red_int, green_int, blue_int : unsigned(7 downto 0) := (others => '0');
signal red_int_std, green_int_std, blue_int_std : std_logic_vector(7 downto 0) := (others => '0');

begin


red_int   <= resize(to_unsigned(75, 8) + resize(y_in(Y_CURSOR_WIDTH - 1 downto 2), 8), 8);
green_int <= resize(to_unsigned(175, 8) - resize(y_in(Y_CURSOR_WIDTH - 1 downto 3), 8) + resize(x_in(X_CURSOR_WIDTH - 1 downto 4), 8), 8);
blue_int  <= resize(to_unsigned(255, 8) - resize(y_in(Y_CURSOR_WIDTH - 1 downto 3), 8) + resize(x_in(X_CURSOR_WIDTH - 1 downto 4), 8), 8);

rgb_out <= std_logic_vector(red_int & green_int & blue_int);

end Behavioral;
