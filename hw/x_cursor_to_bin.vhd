----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dun;eavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity x_cursor_to_bin is
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
end x_cursor_to_bin;

architecture Behavioral of x_cursor_to_bin is

constant NUM_BINS : integer := 2 ** NUM_BIN_BITS;

signal fft_bin_int : unsigned(NUM_BIN_BITS - 1 downto 0) := (others => '0');

begin

dbg_bin_o <= fft_bin_int;
fft_bin_int <= cursor_x_i(NUM_BIN_BITS + 1 downto 2); --divde by 4 to get bin, then LSB

process (fft_bin_int) begin
    is_valid_x_o <= '0';
    fft_bin_o <= (others => '0');
    if (fft_bin_int < NUM_BINS) then
        fft_bin_o <= fft_bin_int;
        is_valid_x_o <= '1';
    end if;
end process;


end Behavioral;
