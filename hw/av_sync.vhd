----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity av_sync is
    Generic(
        CURSOR_WIDTH : integer := 32;
        AMP_WIDTH : integer := 8;   --same as number of bits for fft bins
        AMP_NORM_WIDTH : integer := 9  --number of bits to normalize to. 
    );
    Port ( 
        active_video_i : in STD_LOGIC;
        hsync_i : in STD_LOGIC;
        vsync_i : in STD_LOGIC;
        fsync_i : in STD_LOGIC;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        pixel_clk_i : in STD_LOGIC;
        dbg_i : in std_logic_vector(3 downto 0);
        lr_fft_o : out STD_LOGIC;
        fft_bin_o : out unsigned (AMP_WIDTH - 1 downto 0);
        active_video_o : out STD_LOGIC;
        hsync_o : out STD_LOGIC;
        vsync_o : out STD_LOGIC;
        fsync_o : out STD_LOGIC;
        rgb_o : out STD_LOGIC_VECTOR (23 downto 0);
        
        dbg_cursor_x_o : out unsigned (CURSOR_WIDTH - 1 downto 0);
        dbg_cursor_y_o : out unsigned (CURSOR_WIDTH - 1 downto 0);
        dbg_height_o : out unsigned (CURSOR_WIDTH - 1 downto 0);
        dbg_width_o : out unsigned (CURSOR_WIDTH - 1 downto 0);
        dbg_bin_o : out unsigned(AMP_WIDTH - 1 downto 0);
        dbg_valid_x : out std_logic
    );
end av_sync;

architecture Behavioral of av_sync is
--Inernal Components
component counter is
    Generic(
        COUNT_BITS : integer := CURSOR_WIDTH
    );
    Port ( 
        en_i : in STD_LOGIC;
        reset_i : in STD_LOGIC;
        clk_i : in std_logic;
        count_o : out unsigned (COUNT_BITS - 1 downto 0)
    );
end component;

component signal_delay is
    Generic(
        SIGNAL_WIDTH : integer := 1;
        DELAY_COUNT : integer := 2
    );
    Port (
        clk_i : in STD_LOGIC;
        signal_i : in std_logic_vector(SIGNAL_WIDTH -1 downto 0);
        delay_signal_o : out std_logic_vector(SIGNAL_WIDTH -1 downto 0)
    );
end component;

component cursor_amp_to_rgb is
    Generic(
        AMP_WIDTH : integer := AMP_WIDTH;   --same as number of bits for fft bins
        AMP_NORM_WIDTH : integer := AMP_NORM_WIDTH;  --number of bits to normalize to. 
        CURSOR_WIDTH : integer := CURSOR_WIDTH
    );
    Port ( 
        x_cursor_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
        y_cursor_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_height : in unsigned (CURSOR_WIDTH - 1 downto 0);
        monitor_width : in unsigned (CURSOR_WIDTH - 1 downto 0);
        is_top_i : in STD_LOGIC;
        valid_x_i : in std_logic;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        dbg_i : in std_logic;
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0);
        
        clk_i : in std_logic
    );
end component;

component x_cursor_to_bin is
    Generic (
        CURSOR_WIDTH : integer := CURSOR_WIDTH;
        NUM_BIN_BITS : integer := AMP_WIDTH
    );
    Port ( 
       cursor_x_i : in unsigned (CURSOR_WIDTH - 1 downto 0);
       fft_bin_o : out unsigned (NUM_BIN_BITS - 1 downto 0);
       is_valid_x_o : out STD_LOGIC;
       dbg_bin_o : out unsigned (NUM_BIN_BITS - 1 downto 0)
   );
end component;

constant FFT_SYNC_BUS_WIDTH : integer := 2;

signal monitor_width, monitor_height : unsigned(CURSOR_WIDTH - 1 downto 0) := (others => '0');  --dynamic height tracking


signal cursor_x_int, sync_cursor_x_int : unsigned (CURSOR_WIDTH - 1 downto 0) := (others => '0'); 
signal cursor_y_int, sync_cursor_y_int : unsigned (CURSOR_WIDTH - 1 downto 0) := (others => '0');
signal std_sync_x, std_sync_y : std_logic_vector(CURSOR_WIDTH -1 downto 0) := (others => '0');

signal video_ahvf_bus, sync_video_ahvf_bus : std_logic_vector(3 downto 0) := (others => '0');

signal tv_bus, sync_tv_bus : std_logic_vector(1 downto 0) := (others => '0'); --create a bus for all the signals to sync to fft

signal is_top_half, sync_is_top_half : std_logic := '1';
signal sync_top_bus : std_logic_vector(1 downto 0) := "00";
signal is_valid_x, sync_is_valid_x : std_logic := '1'; 

signal switch_reset_x_int, switch_reset_y_int : std_logic := '0';   --signal to determine reset off switch toggle (sometimes hysync and vsync are active low, sometimes high)  
signal reset_x_int, reset_y_int : std_logic := '0';
signal next_row_int : std_logic := '0';
signal prev_reset_x_int : std_logic := '0';

signal rgb_int : std_logic_vector(23 downto 0) := (others => '0');

begin


switch_reset_x_int <= hsync_i when dbg_i(3) = '1' else not(hsync_i);
switch_reset_y_int <= vsync_i when dbg_i(3) = '1' else not(vsync_i);
reset_x_int <= switch_reset_x_int or fsync_i;
reset_y_int <= switch_reset_y_int or fsync_i;
is_top_half <= '1' when cursor_y_int < monitor_height(CURSOR_WIDTH - 1 downto 1) else '0';  --check if below half of height
lr_fft_o <= is_top_half;

--Counters
x_counter : counter
    Generic map(
        COUNT_BITS => CURSOR_WIDTH
    )
    Port map( 
        en_i => active_video_i,
        reset_i => reset_x_int,
        clk_i => pixel_clk_i,
        count_o => cursor_x_int
    );
dbg_cursor_x_o <= cursor_x_int;


next_row : process (pixel_clk_i) begin
    if rising_edge(pixel_clk_i) then
        prev_reset_x_int <= reset_x_int;
        next_row_int <= '0';
        if (prev_reset_x_int = '0' and reset_x_int ='1') then   --rising edge detection
            next_row_int <= '1';
        end if;
    end if;
end process next_row;

y_counter : counter
    Generic map(
        COUNT_BITS => CURSOR_WIDTH
    )
    Port map( 
        en_i => next_row_int,
        reset_i => reset_y_int,
        clk_i => pixel_clk_i,
        count_o => cursor_y_int
    );
dbg_cursor_y_o <= cursor_y_int;
     
--Get an idea of resolution
get_resolution : process(pixel_clk_i) begin
    if rising_edge(pixel_clk_i) then
        if (switch_reset_x_int = '1') then
            if (cursor_x_int > 0) then  --if we reset, and it is non-zero (aka not a holding reset, but x has counted a bit)
                monitor_width <= cursor_x_int;  --then that must be our new width
            end if;
        end if;
        if (switch_reset_y_int = '1') then
            if (cursor_y_int > 0) then
                monitor_height <= cursor_y_int;
            end if;
        end if;
    end if;
end process get_resolution; 
dbg_height_o <= monitor_height;
dbg_width_o <= monitor_width;

     
--Delay signals for FFT data back
tv_bus <= is_top_half & is_valid_x;
fft_request_sync : signal_delay
    Generic map(
        SIGNAL_WIDTH => 2,
        DELAY_COUNT => 2
    )
    Port map(
        clk_i => pixel_clk_i,
        signal_i => tv_bus,
        delay_signal_o => sync_tv_bus
    );
    
x_cursor_sync : signal_delay
    Generic map(
        SIGNAL_WIDTH => CURSOR_WIDTH,
        DELAY_COUNT => 2
    )
    Port map(
        clk_i => pixel_clk_i,
        signal_i => std_logic_vector(cursor_x_int),
        delay_signal_o => std_sync_x
    );
sync_cursor_x_int <= unsigned(std_sync_x);
    
y_cursor_sync : signal_delay
    Generic map(
        SIGNAL_WIDTH => CURSOR_WIDTH,
        DELAY_COUNT => 2
    )
    Port map(
        clk_i => pixel_clk_i,
        signal_i => std_logic_vector(cursor_y_int),
        delay_signal_o => std_sync_y
    );
sync_cursor_y_int <= unsigned(std_sync_y);

--Delay the Video Control signals
video_ahvf_bus <= active_video_i & hsync_i & vsync_i & fsync_i;
video_sync : signal_delay
    Generic map(
        SIGNAL_WIDTH => 4,
        DELAY_COUNT => 3
    )
    Port map(
        clk_i => pixel_clk_i,
        signal_i => video_ahvf_bus,
        delay_signal_o => sync_video_ahvf_bus
    );
active_video_o <= sync_video_ahvf_bus(3);
hsync_o <= sync_video_ahvf_bus(2);
vsync_o <= sync_video_ahvf_bus(1);
fsync_o <= sync_video_ahvf_bus(0);

--Get the bins
get_bin : x_cursor_to_bin
    Port map( 
       cursor_x_i => cursor_x_int,
       fft_bin_o => fft_bin_o,
       is_valid_x_o => is_valid_x,
       dbg_bin_o => dbg_bin_o
   );
dbg_valid_x <= is_valid_x;


--Get the RGB value
color_get : cursor_amp_to_rgb
    Port map( 
        x_cursor_i => sync_cursor_x_int,
        y_cursor_i => sync_cursor_y_int,
        monitor_height => monitor_height,
        monitor_width => monitor_width,
        is_top_i => sync_tv_bus(1),
        valid_x_i => sync_tv_bus(0),
        amp_i => amp_i, --debugging for now
        dbg_i => dbg_i(0),  --if switch 0 is thrown, every pixel is drawn to
        rgb_out => rgb_int,
        
        clk_i => pixel_clk_i
    );

display_sel : process (pixel_clk_i) begin
    if rising_edge(pixel_clk_i) then
        if (dbg_i(1) = '1') then
            rgb_o <= x"F00FF0";
        else
            rgb_o <= rgb_int;
        end if;
    end if;
end process;
    

end Behavioral;
