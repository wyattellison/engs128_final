
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_delay is
end tb_delay;

architecture testbench of tb_delay is
----------------------------------------------------------------------------
-- Constants
constant CLOCK_PERIOD : time := 10ns; 


-- Signal declarations
signal clk : std_logic := '0';
signal en_i, rst_i : std_logic := '0';
signal test_signal : unsigned(7 downto 0) := (others => '0');

----------------------------------------------------------------------------
-- Component

component signal_delay is
    Generic(
        SIGNAL_WIDTH : integer := 8;
        DELAY_COUNT : integer := 4
    );
    Port (
        clk_i : in STD_LOGIC;
        signal_i : in std_logic_vector(SIGNAL_WIDTH - 1 downto 0);
        delay_signal_o : out std_logic_vector(SIGNAL_WIDTH - 1 downto 0)
    );
end component;


----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Instantiate dut
dut: signal_delay
    Port map( 
        signal_i => std_logic_vector(test_signal),
        clk_i => clk,
        delay_signal_o => open
    );
    
----------------------------------------------------------------------------------
-- Clock generation
clock_gen_process : process
begin
	clk <= '0';				    -- start low
	wait for CLOCK_PERIOD;	    -- wait for one CLOCK_PERIOD
	
	loop							-- toggle, wait half a clock period, and loop
	  clk <= not(clk);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;
   

stim_proc : process begin
    wait for CLOCK_PERIOD*0.5;
    test_signal <= to_unsigned(0, 8);
    wait for CLOCK_PERIOD;
    test_signal <= to_unsigned(1, 8);
    wait for CLOCK_PERIOD;
    test_signal <= to_unsigned(2, 8);
    wait for CLOCK_PERIOD;
    test_signal <= to_unsigned(3, 8);
    wait for CLOCK_PERIOD;
    test_signal <= to_unsigned(4, 8);
    wait for CLOCK_PERIOD*5;
    test_signal <= to_unsigned(5, 8);
    wait for CLOCK_PERIOD*10;

    std.env.stop;
end process stim_proc;
----------------------------------------------------------------------------

end testbench;