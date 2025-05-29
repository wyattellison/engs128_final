----------------------------------------------------------------------------------
-- ENGS128
-- Author: Noah Dunleavy
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity av_sync is
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
        active_video_i : in STD_LOGIC;
        hsync_i : in STD_LOGIC;
        vsync_i : in STD_LOGIC;
        fsync_i : in STD_LOGIC;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        pixel_clk_i : in STD_LOGIC;
        dbg_i : in std_logic;
        lr_fft_o : out STD_LOGIC;
        fft_bin_o : out STD_LOGIC_VECTOR (AMP_WIDTH - 1 downto 0);
        active_video_o : out STD_LOGIC;
        hsync_o : out STD_LOGIC;
        vsync_o : out STD_LOGIC;
        fsync_o : out STD_LOGIC;
        rgb_o : out STD_LOGIC_VECTOR (23 downto 0)
    );
end av_sync;

architecture Behavioral of av_sync is

--Inernal Components
component counter is
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
        X_CURSOR_WIDTH : integer := X_CURSOR_WIDTH; --num of bits for cursor pos
        Y_CURSOR_WIDTH : integer := Y_CURSOR_WIDTH;
        AMP_WIDTH : integer := AMP_WIDTH;   --same as number of bits for fft bins
        AMP_NORM_WIDTH : integer := AMP_NORM_WIDTH;  --number of bits to normalize to. 
        NUM_BINS : integer := NUM_BINS;  --number of FFT bins
        PIXEL_X : integer := PIXEL_X;  --monitor width
        PIXEL_Y : integer := PIXEL_Y   --monitor height
    );
    Port ( 
        x_cursor_i : in unsigned (X_CURSOR_WIDTH - 1 downto 0);
        y_cursor_i : in unsigned (Y_CURSOR_WIDTH - 1 downto 0);
        is_top_i : in STD_LOGIC;
        valid_x_i : in std_logic;
        amp_i : in unsigned (AMP_WIDTH - 1 downto 0);
        dbg_i : in std_logic;
        rgb_out : out STD_LOGIC_VECTOR (23 downto 0);
        
        clk_i : in std_logic
    );
end component;

constant MID_PIXEL : integer := PIXEL_Y / 2;
constant FFT_SYNC_BUS_WIDTH : integer := X_CURSOR_WIDTH + Y_CURSOR_WIDTH + 1 + 1;

signal cursor_x_int, sync_cursor_x_int : unsigned (X_CURSOR_WIDTH - 1 downto 0) := (others => '0'); 
signal cursor_y_int, sync_cursor_y_int : unsigned (Y_CURSOR_WIDTH - 1 downto 0) := (others => '0');

signal video_ahvf_bus, sync_video_ahvf_bus : std_logic_vector(3 downto 0) := (others => '0');

signal cursor_xytv_bus, sync_cursor_xytv_bus : std_logic_vector(FFT_SYNC_BUS_WIDTH - 1 downto 0) := (others => '0'); --create a bus for all the signals to sync to fft

signal is_top_half, sync_is_top_half : std_logic := '1';
signal sync_top_bus : std_logic_vector(1 downto 0) := "00";
signal is_valid_x, sync_is_valid_x : std_logic := '0';

signal reset_x_int, reset_y_int : std_logic := '0';
signal next_row_int : std_logic := '0';

begin

--Counters
reset_x_int <= not(hsync_i) or fsync_i;
reset_y_int <= not(vsync_i) or fsync_i;
is_top_half <= '1' when cursor_y_int < MID_PIXEL else '0';

x_counter : counter
    Generic map(
        MAX_COUNT => PIXEL_X,
        COUNT_BITS => X_CURSOR_WIDTH
    )
    Port map( 
        en_i => active_video_i,
        reset_i => reset_x_int,
        clk_i => pixel_clk_i,
        count_o => cursor_x_int,
        tc_o => next_row_int
    );

y_counter : counter
    Generic map(
        MAX_COUNT => PIXEL_Y,
        COUNT_BITS => Y_CURSOR_WIDTH
    )
    Port map( 
        en_i => next_row_int,
        reset_i => reset_y_int,
        clk_i => pixel_clk_i,
        count_o => cursor_y_int,
        tc_o => open
    );
     
--Delay signals for FFT data back
cursor_xytv_bus <= std_logic_vector(cursor_x_int) & std_logic_vector(cursor_y_int) & is_top_half & is_valid_x;
fft_request_sync : signal_delay
    Generic map(
        SIGNAL_WIDTH => FFT_SYNC_BUS_WIDTH,
        DELAY_COUNT => 2
    )
    Port map(
        clk_i => pixel_clk_i,
        signal_i => cursor_xytv_bus,
        delay_signal_o => sync_cursor_xytv_bus
    );
--sync_cursor_x_int <= to_unsigned(sync_cursor_xytv_bus(FFT_SYNC_BUS_WIDTH - 1 downto FFT_SYNC_BUS_WIDTH - X_CURSOR_WIDTH), X_CURSOR_WIDTH);

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

--Get the RGB value
color_get : cursor_amp_to_rgb
    Port map( 
        x_cursor_i => sync_cursor_x_int,
        y_cursor_i => sync_cursor_y_int,
        is_top_i => sync_is_top_half,
        valid_x_i => sync_is_valid_x,
        amp_i => amp_i,
        dbg_i => dbg_i,
        rgb_out => rgb_o,
        
        clk_i => pixel_clk_i
    );
    

end Behavioral;
