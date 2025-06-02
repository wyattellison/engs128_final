----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity slicer_selector is
    Port ( signal_i : in unsigned (31 downto 0);
           sel_i : in STD_LOGIC_VECTOR (2 downto 0);
           signal_o : out unsigned (7 downto 0));
end slicer_selector;

architecture Behavioral of slicer_selector is

begin

amp_scale : process (sel_i, signal_i) begin
    case sel_i is
        when "000" =>
            signal_o <= signal_i(31 downto 24);
        when "001" =>
            signal_o <= signal_i(29 downto 22);
        when "010" =>
            signal_o <= signal_i(27 downto 20);
        when "011" =>
            signal_o <= signal_i(25 downto 18);
        when "100" =>
            signal_o <= signal_i(23 downto 16);
        when "101" =>
            signal_o <= signal_i(21 downto 14);
        when "110" =>
            signal_o <= signal_i(19 downto 12);
        when "111" =>
            signal_o <= signal_i(17 downto 10);
        when others =>
            signal_o <= signal_i(15 downto 8);
    end case;
end process amp_scale;


end Behavioral;
