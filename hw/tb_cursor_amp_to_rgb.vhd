----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_cursor_amp_to_rgb is
--  Port ( );
end tb_cursor_amp_to_rgb;

architecture testbench of tb_cursor_amp_to_rgb is

component cursor_amp_to_rgb is
    Generic(
        X_CURSOR_WIDTH : integer := 11; --num of bits for cursor pos
        Y_CURSOR_WIDTH : integer := 10;
        AMP_WIDTH : integer := 8;   --same as number of bits for fft bins
        AMP_NORM_WIDTH : integer := 9;  --number of bits to normalize to. 
        NUM_BINS : integer := 256;  --number of FFT bins
        PIXEL_X : integer := 1280;  --monitor width
        PIXEL_Y : integer := 720   --monitor height
    );
    Port ( 
        x_cursor_i : in unsigned (X_CURSOR_WIDTH - 1 downto 0);
        y_cursor_i : in unsigned (Y_CURSOR_WIDTH - 1 downto 0);
        is_top_i : in STD_LOGIC;
        valid_x_i : in std_logic;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0);
        dbg_n_i : in std_logic;
        
        clk_i : in std_logic
    );
end component;

signal clk, is_top_i, valid_x_i : std_logic := '0';
constant CLOCK_PERIOD : time := 10ns; 
signal x_in : unsigned(10 downto 0) := (others => '0');
signal y_in : unsigned(9 downto 0) := (others => '0');
signal amp_i : unsigned(7 downto 0) := (others => '0');
signal dbg_n_i_0 : std_logic := '1';

signal red, blue, green : std_logic_vector(7 downto 0) := (others => '0');
signal rbg : std_logic_vector(23 downto 0);

begin

red <= rbg(23 downto 16);
blue <= rbg(15 downto 8);
green <= rbg(7 downto 0);
dut : cursor_amp_to_rgb
    Port map(
        x_cursor_i => x_in,
        y_cursor_i => y_in,
        is_top_i => is_top_i,
        valid_x_i => valid_x_i,
        amp_i => amp_i,
        rgb_out => rbg,
        dbg_n_i => dbg_n_i_0,
        
        clk_i => clk
    
    );

clock_gen_process : process
begin
	clk <= '0';				    -- start low
	wait for CLOCK_PERIOD;	    -- wait for one CLOCK_PERIOD
	
	loop							-- toggle, wait half a clock period, and loop
	  clk <= not(clk);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;

is_top_i <= '1' when y_in < 360 else '0';

stim_proc : process begin
    wait for CLOCK_PERIOD/2;
    --Top Left
    x_in <= to_unsigned(0, 11); --place cursor
    y_in <= to_unsigned(0, 10);
    valid_x_i <= '1';   --say it is valid x
    amp_i <= to_unsigned(120, 8); --give a signal amo
    dbg_n_i_0 <= '1';   --do not debug
    wait for CLOCK_PERIOD;
    --Top Right
    x_in <= to_unsigned(1279, 11);
    y_in <= to_unsigned(0, 10);
    valid_x_i <= '0';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '1';   
    wait for CLOCK_PERIOD;
    --Bottom Left
    x_in <= to_unsigned(0, 11);
    y_in <= to_unsigned(719, 10);
    valid_x_i <= '1';   
    amp_i <= to_unsigned(255, 8); 
    dbg_n_i_0 <= '1'; 
    wait for CLOCK_PERIOD;
    --Bottom Right
    x_in <= to_unsigned(1279, 11);
    y_in <= to_unsigned(719, 10);
    valid_x_i <= '0';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '0'; 
    wait for CLOCK_PERIOD;
    --Others
    x_in <= to_unsigned(100, 11);
    y_in <= to_unsigned(0, 10);
    valid_x_i <= '1';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '1'; 
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(100, 11);
    y_in <= to_unsigned(300, 10);
    valid_x_i <= '1';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '1'; 
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(700, 11);
    y_in <= to_unsigned(300, 10);
    valid_x_i <= '1';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '1'; 
    wait for CLOCK_PERIOD;
    x_in <= to_unsigned(700, 11);
    y_in <= to_unsigned(700, 10);
    valid_x_i <= '1';   
    amp_i <= to_unsigned(120, 8); 
    dbg_n_i_0 <= '1'; 
    wait for CLOCK_PERIOD;

    std.env.stop;


end process stim_proc;

end testbench;
