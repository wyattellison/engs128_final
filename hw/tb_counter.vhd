--ENGS128
--Author: Noah Dunleavy


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity Declaration
entity tb_counter is
end tb_counter;

----------------------------------------------------------------------------
architecture testbench of tb_counter is
----------------------------------------------------------------------------
-- Constants
constant CLOCK_PERIOD : time := 10ns; 


-- Signal declarations
signal clk : std_logic := '0';
signal en_i, rst_i : std_logic := '0';

----------------------------------------------------------------------------
-- Component
component counter is
    Generic(
        MAX_COUNT : integer := 20;
        COUNT_BITS : integer := 5
    );
    Port ( 
        en_i : in STD_LOGIC;
        reset_i : in STD_LOGIC;
        clk_i : in std_logic;
        count_o : out unsigned (COUNT_BITS - 1 downto 0);
        tc_o : out STD_LOGIC
    );
end component;


----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Instantiate dut
dut: counter
    Port map( 
        en_i => en_i,
        reset_i => rst_i,
        clk_i => clk,
        count_o => open,
        tc_o => open
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
    wait for CLOCK_PERIOD*10;
    en_i <= '1';
    wait for CLOCK_PERIOD*10;
    rst_i <= '1';
    wait for 5*CLOCK_PERIOD;
    rst_i <= '0';
    wait for 50*CLOCK_PERIOD;
    en_i <= '0';
    wait for CLOCK_PERIOD;
    rst_i <= '1';
    wait for CLOCK_PERIOD;
    rst_i <= '0';

    std.env.stop;
end process stim_proc;
----------------------------------------------------------------------------

end testbench;
