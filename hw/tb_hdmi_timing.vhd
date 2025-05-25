----------------------------------------------------------------------------------
-- ENGS128 - HDMI Timing Testing
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity tb_hdmi_timing is
end tb_hdmi_timing;

architecture testbench of tb_hdmi_timing is
constant PIXEL_HBP : integer := 30;
constant PIXEL_HACT : integer := 1280;   --monitor raw width
constant PIXEL_HFP : integer := 30;
constant PIXEL_HSYNC : integer := 100;
constant Dx : integer := PIXEL_HBP + PIXEL_HACT + PIXEL_HFP + PIXEL_HSYNC;
        --Vertical pixel widths  
constant PIXEL_VBP : integer := 20;
constant PIXEL_VACT : integer := 720;   --monitor raw width
constant PIXEL_VFP : integer := 20;
constant PIXEL_VSYNC : integer := 100;
constant Dy : integer := PIXEL_VBP + PIXEL_VACT + PIXEL_VFP + PIXEL_VSYNC;
        --Number of bits
constant NUM_H_BITS : integer := 11; --number of bits to span the active window horizontally
constant NUM_V_BITS : integer := 10;
constant PIXEL_CLK_FREQ : integer := Dx * Dy * 60;  --60Hz framrate
constant PIXEL_CLK_PERIOD : time :=13.45ns; --wanted to generic it, but goofy and unecessary tbh

signal pixel_clk : std_logic := '0';

component hdmi_timing_controller is
    Generic (
        --Horizontal pixel widths
        PIXEL_HBP : integer := PIXEL_HBP;
        PIXEL_HACT : integer := PIXEL_HACT;   --monitor raw width
        PIXEL_HFP : integer := PIXEL_HFP;
        PIXEL_HSYNC : integer := PIXEL_HSYNC;
        --Vertical pixel widths
        PIXEL_VBP : integer := PIXEL_VBP;
        PIXEL_VACT : integer := PIXEL_VACT;   --monitor raw width
        PIXEL_VFP : integer := PIXEL_VFP;
        PIXEL_VSYNC : integer := PIXEL_VSYNC;
        --Number of bits
        NUM_H_BITS : integer := NUM_H_BITS; --number of bits to span the active window horizontally
        NUM_V_BITS : integer := NUM_V_BITS    --to span active window y
    );
    Port (
       pixel_clk_i : in STD_LOGIC;
       pixel_x_o : out std_logic_vector(NUM_H_BITS - 1 downto 0);  --make them the right size to span positions
       pixel_y_o : out std_logic_vector(NUM_V_BITS - 1 downto 0);
       x_active : out std_logic;
       y_active : out std_logic
   );
end component;

begin

dut : hdmi_timing_controller
    Port map(
       pixel_clk_i => pixel_clk,
       pixel_x_o => open,  --make them the right size to span positions
       pixel_y_o => open,
       x_active => open,
       y_active => open
    );

clk_gen : process begin
    wait for PIXEL_CLK_PERIOD/2;		-- wait for half a clock period
	loop							-- toggle, and loop
	  pixel_clk <= not(pixel_clk);
	  wait for PIXEL_CLK_PERIOD/2;
	end loop;

end process;    


end testbench;
