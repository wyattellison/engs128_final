----------------------------------------------------------------------------------
-- ENGS128
-- Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity tb_color_logic is
end tb_color_logic;

architecture testbench of tb_color_logic is


component color_logic is
    Generic (
        X_CURSOR_WIDTH : integer := 11; --num of bits for cursor pos
        Y_CURSOR_WIDTH : integer := 10
    );
    Port ( 
        x_in : in unsigned (X_CURSOR_WIDTH - 1 downto 0);
        y_in : in unsigned (Y_CURSOR_WIDTH - 1 downto 0);
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0)
    );
end component;
constant CLOCK_PERIOD : time := 10ns; 
signal x_in : unsigned(10 downto 0) := (others => '0');
signal y_in : unsigned(9 downto 0) := (others => '0');

signal red, blue, green : std_logic_vector(7 downto 0) := (others => '0');
signal rbg : std_logic_vector(23 downto 0);

begin



dut : color_logic
    Port map(
        x_in => x_in,
        y_in => y_in,
        rgb_out => rbg
    );
    
    
red <= rbg(23 downto 16);
blue <= rbg(15 downto 8);
green <= rbg(7 downto 0);
stim_proc : process begin
    --Top Left
    x_in <= to_unsigned(0, 11);
    y_in <= to_unsigned(0, 10);
    wait for CLOCK_PERIOD;
    --Top Right
    x_in <= to_unsigned(1279, 11);
    y_in <= to_unsigned(0, 10);
    wait for CLOCK_PERIOD;
    --Bottom Left
    x_in <= to_unsigned(0, 11);
    y_in <= to_unsigned(719, 10);
    wait for CLOCK_PERIOD;
    --Bottom Right
    x_in <= to_unsigned(1279, 11);
    y_in <= to_unsigned(719, 10);
    wait for CLOCK_PERIOD;
    --Others
    x_in <= to_unsigned(100, 11);
    y_in <= to_unsigned(0, 10);
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(100, 11);
    y_in <= to_unsigned(300, 10);
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(700, 11);
    y_in <= to_unsigned(300, 10);
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(700, 11);
    y_in <= to_unsigned(700, 10);
    wait for CLOCK_PERIOD;

    std.env.stop;


end process stim_proc;


end testbench;
