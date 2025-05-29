----------------------------------------------------------------------------------
-- ENGS128
--Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity signal_delay is
    Generic(
        SIGNAL_WIDTH : integer := 1;
        DELAY_COUNT : integer := 2
    );
    Port (
        clk_i : in STD_LOGIC;
        signal_i : in std_logic_vector(SIGNAL_WIDTH - 1 downto 0);
        delay_signal_o : out std_logic_vector(SIGNAL_WIDTH - 1 downto 0)
    );
end signal_delay;

architecture Behavioral of signal_delay is

type t_mem is array (DELAY_COUNT - 1 downto 0) of std_logic_vector(SIGNAL_WIDTH - 1 downto 0);
signal delay_mem : t_mem := (others => (others => '0'));    --start the delay of all zeros

begin

delay_shift : process (clk_i) begin
    if rising_edge(clk_i) then
        shift_loop : for ndx in DELAY_COUNT - 1 downto 0 loop
            if (ndx = DELAY_COUNT - 1) then
                delay_mem(ndx) <= signal_i;
            else
                delay_mem(ndx) <= delay_mem(ndx + 1);   --shift data
            end if;
        end loop shift_loop;
    end if;
end process delay_shift;
delay_signal_o <= delay_mem(0);


end Behavioral;
