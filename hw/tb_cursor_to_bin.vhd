----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_cursor_to_bin is
--  Port ( );
end tb_cursor_to_bin;

architecture testbench of tb_cursor_to_bin is

component x_cursor_to_bin is
    Generic (
        CURSOR_WIDTH : integer := 32;
        NUM_BIN_BITS : integer := 6
    );
    Port ( 
       cursor_x_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
       fft_bin_o : out unsigned (NUM_BIN_BITS - 1 downto 0);
       is_valid_x_o : out STD_LOGIC;
       dbg_bin_o : out unsigned (NUM_BIN_BITS - 1 downto 0)
   );
end component;

constant CLOCK_PERIOD : time := 10ns; 
signal x_in : unsigned(31 downto 0) := (others => '0');
signal x_cnt : integer := 0;

begin

dut : x_cursor_to_bin
    Port map(
        cursor_x_i => x_in,
        fft_bin_o => open,
        is_valid_x_o => open,
        dbg_bin_o => open
    );

x_in <= to_unsigned(x_cnt, 32);

cnt : process begin
    x_cnt <= x_cnt + 1;
    wait for CLOCK_PERIOD;
end process;

stim_proc : process begin
    wait for 1000*CLOCK_PERIOD;
    std.env.stop;
end process stim_proc;


end testbench;
