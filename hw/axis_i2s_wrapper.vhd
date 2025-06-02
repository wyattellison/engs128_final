----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI stream wrapper for controlling I2S audio data flow
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;     
use IEEE.STD_LOGIC_UNSIGNED.ALL;                                    
----------------------------------------------------------------------------
-- Entity definition
entity axis_i2s_wrapper is
	generic (
		-- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		
				-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
		
        DDS_DATA_WIDTH : integer := 24;         -- DDS data width
        DDS_PHASE_DATA_WIDTH : integer := 12   -- DDS phase increment data width
	);
    Port ( 
        ----------------------------------------------------------------------------
        -- Fabric clock from Zynq PS
        --sys_clk_100MHz_i : in std_logic;
		mclk_i : in  std_logic;	
		
        ----------------------------------------------------------------------------
        -- I2S audio codec ports		
		-- User controls
		ac_mute_en_i : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC;
                
        --lr clk out for filter stack
        lrclk_o : out std_logic;
        
        -- debug clock ports that aren't oddr
        dbg_mclk_o : out std_logic;
        dbg_bclk_o : out std_logic;
        
        ----------------------------------------------------------------------------
        -- AXI Stream Interface (Receiver/Responder)
    	-- Ports of Axi Responder Bus Interface S00_AXIS
		
        -- AXI Stream Interface (Tranmitter/Controller)
		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
		);
end axis_i2s_wrapper;
----------------------------------------------------------------------------
architecture Behavioral of axis_i2s_wrapper is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
signal mclk, bclk, lrclk : std_logic := '0';
signal ac_mute_en_n_register : std_logic := '1';
signal i2s_left_audio_data_rx, i2s_right_audio_data_rx, dds_left_audio_data_rx, dds_right_audio_data_rx, i2s_left_audio_data_tx, i2s_right_audio_data_tx, left_audio_data_axis_tx, right_audio_data_axis_tx : std_logic_vector(23 downto 0) := (others => '0');

signal dds_enable : std_logic := '1';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generation
component i2s_clock_gen is
    Generic (
        MCLK_TO_BCLK_DIV : integer := 4;
        BCLK_TO_LRCLK_DIV : integer := 64
    );
    Port ( 
        --Input signals
        --sys_clk_100MHz_i    : in std_logic;
        mclk_i : in std_logic;
        
        --Forwaded Clcoks (ODDRs)
        mclk_fwd_o  : out std_logic;
        bclk_fwd_o  : out std_logic;
        adc_lrclk_fwd_o : out std_logic;
        dac_lrclk_fwd_o : out std_logic;
        
        --Clocks (BUFG to Highway)
        mclk_o  :   out std_logic;
        bclk_o  :   out std_logic;
        
        --Logic Signals
        lrclk_o           : out std_logic;
		lrclk_unbuf_o     : out std_logic
    );
end component;



---------------------------------------------------------------------------- 
-- I2S receiver
component i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (
        adc_serial_data_i     : in std_logic;
        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0)
		);  
end component;
	
---------------------------------------------------------------------------- 
-- I2S transmitter
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end component;

---------------------------------------------------------------------------- 
-- AXI stream transmitter
component axis_transmitter_interface is
generic (
    -- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
    C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
    AC_DATA_WIDTH : integer := 24
);
Port (
lrclk_i : in std_logic;
left_audio_data_i : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
right_audio_data_i : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);

m00_axis_aclk : in std_logic;
m00_axis_aresetn : in std_logic;
m00_axis_tready : in std_logic;

m00_axis_tdata : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
m00_axis_tlast : out std_logic;
m00_axis_tstrb : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
m00_axis_tvalid : out std_logic);
end component;
    
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- Clock generation
clock_generation : i2s_clock_gen 
port map(

        mclk_i => mclk_i,
        
        --Forwaded Clcoks (ODDRs)
        mclk_fwd_o => ac_mclk_o,
        bclk_fwd_o  => ac_bclk_o,
        adc_lrclk_fwd_o => ac_adc_lrclk_o,
        dac_lrclk_fwd_o => ac_dac_lrclk_o,
        
        --Clocks (BUFG to Highway)
        mclk_o  => mclk,
        bclk_o  => bclk,
        
        --Logic Signals
        lrclk_o => open,
        lrclk_unbuf_o => lrclk);
        
-- tie mclk and bclk to dbg outputs
dbg_mclk_o <= mclk;
dbg_bclk_o <= bclk;
lrclk_o <= lrclk;


---------------------------------------------------------------------------- 

-- I2S receiver
audio_receiver : i2s_receiver
port map(
        adc_serial_data_i => ac_adc_data_i,
        -- Timing
		mclk_i => mclk,
		bclk_i => bclk,
		lrclk_i => lrclk,
		
		-- Data
		left_audio_data_o => i2s_left_audio_data_rx,
		right_audio_data_o => i2s_right_audio_data_rx);

	
---------------------------------------------------------------------------- 
-- I2S transmitter
audio_transmitter : i2s_transmitter
port map(
        -- Timing
		mclk_i => mclk,
		bclk_i => bclk,
		lrclk_i => lrclk,
		
		-- Data
		left_audio_data_i => i2s_left_audio_data_rx,
		right_audio_data_i => i2s_right_audio_data_rx,
		dac_serial_data_o => ac_dac_data_o);


---------------------------------------------------------------------------- 
-- AXI stream transmitter
axis_transmitter : axis_transmitter_interface
port map(
    lrclk_i => lrclk,
    left_audio_data_i => i2s_left_audio_data_rx, -- task 1 just tied to dds, later implement i2s switching
    right_audio_data_i => i2s_right_audio_data_rx,
    
    m00_axis_aclk => m00_axis_aclk,
    m00_axis_aresetn => m00_axis_aresetn,
    m00_axis_tready => m00_axis_tready,
    
    m00_axis_tdata => m00_axis_tdata,
    m00_axis_tlast => m00_axis_tlast,
    m00_axis_tstrb => m00_axis_tstrb,
    m00_axis_tvalid => m00_axis_tvalid);


---------------------------------------------------------------------------- 
-- Logic
---------------------------------------------------------------------------- 
mute_enable_register : process(mclk)
begin
    if rising_edge(mclk) then
        ac_mute_en_n_register <= not(ac_mute_en_i);
    end if;
end process mute_enable_register;
-- tie to output
ac_mute_n_o <= ac_mute_en_n_register;


----------------------------------------------------------------------------


end Behavioral;