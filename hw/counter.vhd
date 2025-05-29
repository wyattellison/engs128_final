----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity counter is
    Generic(
        MAX_COUNT : integer := 720;
        COUNT_BITS : integer := 10
    );
    Port ( 
        en_i : in STD_LOGIC;
        reset_i : in STD_LOGIC;
        clk_i : in std_logic;
        count_o : out unsigned (COUNT_BITS - 1 downto 0);
        tc_o : out STD_LOGIC
    );
end counter;

architecture Behavioral of counter is

signal count_int : integer range 0 to MAX_COUNT - 1 := 0;

begin

counter : process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            count_int <= 0;
        elsif (en_i = '1') then
            if (count_int = MAX_COUNT - 1) then --
                count_int <= 0;
            else
                count_int <= count_int + 1;
            end if;
        else
            --Do nothing if not enabled or resetting
        end if;
    end if;
end process counter;
count_o <= to_unsigned(count_int, COUNT_BITS);
tc_o <= '1' when count_int = MAX_COUNT - 1 else '0';

end Behavioral;
