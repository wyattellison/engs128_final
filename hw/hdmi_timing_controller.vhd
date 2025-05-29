----------------------------------------------------------------------------------
-- ENGS128 - HDMI Timing Controller
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity hdmi_timing_controller is
    Generic (
        --Horizontal pixel widths
        PIXEL_HBP : integer := 220;
        PIXEL_HACT : integer := 1280;   --monitor raw width
        PIXEL_HFP : integer := 110;
        PIXEL_HSYNC : integer := 40;
        --Vertical pixel widths
        PIXEL_VBP : integer := 20;
        PIXEL_VACT : integer := 720;   --monitor raw width
        PIXEL_VFP : integer := 5;
        PIXEL_VSYNC : integer := 5;
        --Number of bits
        NUM_H_BITS : integer := 11; --number of bits to span w horizontally
        NUM_V_BITS : integer := 10    --to span  window y
    );
    Port (
       pixel_clk_i : in STD_LOGIC;
       pixel_x_o : out std_logic_vector(NUM_H_BITS - 1 downto 0);  --make them the right size to span positions
       pixel_y_o : out std_logic_vector(NUM_V_BITS - 1 downto 0);
       hsync_o : out std_logic;
       vsync_o : out std_logic
   );
end hdmi_timing_controller;

architecture Behavioral of hdmi_timing_controller is

--Constants
constant Dx : integer := PIXEL_HBP + PIXEL_HACT + PIXEL_HFP + PIXEL_HSYNC;
constant Dy : integer := PIXEL_VBP + PIXEL_VACT + PIXEL_VFP + PIXEL_VSYNC;

--Signals
signal cursor_x_int : integer range 0 to Dx - 1 := 0;
signal cursor_y_int : integer range 0 to Dy - 1 := 0;

signal TC_x : std_logic := '0';

signal is_active_x : std_logic := '0';  --flag the tracks if we are in active plane
signal is_active_y : std_logic := '0';

begin

--Counters
x_counter : process (pixel_clk_i) begin
    if rising_edge(pixel_clk_i) then
        if (cursor_x_int = Dx - 1) then
            cursor_x_int <= 0;    --reset if we entered at max count
        else
            cursor_x_int <= cursor_x_int + 1;   --increment count
            if (cursor_x_int = Dx - 2) then --if we entered 1 from max (so we have now counted to max)
                TC_x <= '1';    --TC flag
            else
                TC_x <= '0'; --if not maxed out
            end if;
        end if;
    end if;
end process x_counter;
is_active_x <= '1' when ((PIXEL_HBP - 1) < cursor_x_int) AND (cursor_x_int < (PIXEL_HBP + PIXEL_HACT)) else '0';    --if we are past the back porch, but before front

y_counter : process (pixel_clk_i) begin
    if rising_edge(pixel_clk_i) then
        if (TC_x = '1') then    --y counting only happens when x pixel is at end
            if (cursor_y_int = Dy - 1) then
                cursor_y_int <= 0;
            else
                cursor_y_int <= cursor_y_int + 1; --do not care about a TC flag here
            end if;
        end if;
    end if;
end process y_counter;
is_active_y <= '1' when ((PIXEL_VBP - 1) < cursor_y_int) AND (cursor_y_int < (PIXEL_VBP + PIXEL_VACT)) else '0';

--Output logic
--[TODO] make sync when in sync window, and adjust out to eb all pixels
hsyc_o <= is_active_x;
pixel_x_o <= cursor_x_int;

vsync_o <= is_active_y;
pixel_y_o <= cursor_y_int;


end Behavioral;
