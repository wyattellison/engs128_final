----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: Clock generation for LRCLK from BCLK in I2S communication
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;


entity i2s_falling_edge_clk_gen is
    Generic ( CLK_DIV_RATIO : integer := 64);
    Port ( clk_i : in STD_LOGIC;
    
           bufg_clk_o : out STD_LOGIC;
           clk_o : out STD_LOGIC);
end i2s_falling_edge_clk_gen;

architecture Behavioral of i2s_falling_edge_clk_gen is

--Constants
constant CLK_DIV_TC : integer := integer(CLK_DIV_RATIO/2);
constant CLK_COUNT_BITS : integer := integer(ceil(log2(real(CLK_DIV_TC))));

--Signals
signal slow_clk_int : std_logic := '0';
signal clock_counter : unsigned(CLK_COUNT_BITS - 1 downto 0) := (others => '0');

begin
--Counter and slow clock assertion
clk_counter : process(clk_i) begin
    if falling_edge(clk_i) then
        if (clock_counter >= CLK_DIV_TC - 1) then
            clock_counter <= (others => '0');   --don't need/have a TC to assert
            slow_clk_int <= not(slow_clk_int);
        else
            clock_counter <= clock_counter + 1;
        end if;
    end if;
end process clk_counter;


--Buffering
slow_clk_to_bufg : BUFG
    Port map(
        I => slow_clk_int,
        
        O => bufg_clk_o
    );

--Tieing Outputs
clk_o <= slow_clk_int;

end Behavioral;
