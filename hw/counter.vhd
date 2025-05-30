----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity counter is
    Generic(
        COUNT_BITS : integer := 32
    );
    Port ( 
        en_i : in STD_LOGIC;
        reset_i : in STD_LOGIC;
        clk_i : in std_logic;
        count_o : out unsigned (COUNT_BITS - 1 downto 0)
    );
end counter;

architecture Behavioral of counter is

signal count_int : integer := 0;

begin

counter : process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            count_int <= 0;
        elsif (en_i = '1') then
            count_int <= count_int + 1;
        else
            --Do nothing if not enabled or resetting
        end if;
    end if;
end process counter;
count_o <= to_unsigned(count_int, COUNT_BITS);

end Behavioral;
