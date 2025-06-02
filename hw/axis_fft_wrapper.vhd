----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/25/2025 05:41:06 PM
-- Design Name: 
-- Module Name: axis_fft_wrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axis_fft_wrapper is
	generic (
		-- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		AUDIO_DATA_WIDTH : integer := 24;
		FFT_DATA_WIDTH : integer := 16;
		FFT_FRAME_SIZE : integer := 256;
		LR_INDEX : integer := 31  --index of where the lr bit is
	);
    Port ( 
    
        ----------------------------------------------------------------------------
        -- AXI Stream Interface (Receiver/Responder)
    	-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;
		
        -- AXI Stream Interface (Tranmitter/Controller)
		-- Ports of Axi Controller Bus Interface M00_AXIS
--		m00_axis_aclk     : in std_logic;
--		m00_axis_aresetn  : in std_logic;
--		m00_axis_tvalid   : out std_logic;
--		m00_axis_tdata    : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
--		m00_axis_tstrb    : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
--		m00_axis_tlast    : out std_logic;
--		m00_axis_tready   : in std_logic;
--		m00_axis_tuser    : out std_logic_vector(7 downto 0)

        left_fft_bram_rd_addr : in std_logic_vector(7 downto 0);
        left_fft_bram_rd_data : out std_logic_vector(31 downto 0);
        right_fft_bram_rd_addr : in std_logic_vector(7 downto 0);
        right_fft_bram_rd_data : out std_logic_vector(31 downto 0)
		
		);
end axis_fft_wrapper;

architecture Behavioral of axis_fft_wrapper is

signal left_en, right_en, tlast_valid, tlast : std_logic := '0';
signal input_left_valid, input_right_valid : std_logic := '0';
signal unfiltered_data_int : std_logic_vector(C_AXI_STREAM_DATA_WIDTH - 1 downto 0) := (others => '0');


signal    s_axis_config_tdata :  STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
signal s_axis_config_tvalid :  STD_LOGIC := '0';
signal     s_axis_config_tready : STD_LOGIC := '0';

signal left_fft_bram_wr_en : std_logic_vector(0 downto 0) := "0";
signal left_fft_bram_wr_addr: std_logic_vector(7 downto 0) := (others => '0');
signal left_fft_bram_wr_data: std_logic_vector(31 downto 0) := (others => '0');
signal left_fft_data_int : std_logic_vector(C_AXI_STREAM_DATA_WIDTH - 1 downto 0) := (others => '0');

signal right_fft_bram_wr_en : std_logic_vector(0 downto 0) := "0";
signal right_fft_bram_wr_addr: std_logic_vector(7 downto 0) := (others => '0');
signal right_fft_bram_wr_data: std_logic_vector(31 downto 0) := (others => '0');
signal right_fft_data_int : std_logic_vector(C_AXI_STREAM_DATA_WIDTH - 1 downto 0) := (others => '0');

COMPONENT xfft_1
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tuser : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tlast : OUT STD_LOGIC;
    event_frame_started : OUT STD_LOGIC;
    event_tlast_unexpected : OUT STD_LOGIC;
    event_tlast_missing : OUT STD_LOGIC;
    event_status_channel_halt : OUT STD_LOGIC;
    event_data_in_channel_halt : OUT STD_LOGIC;
    event_data_out_channel_halt : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT fft_block_ram
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

component fft_output_to_magnitude is
  port (
    fft_abs_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fft_axis_data_i : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );
 end component fft_output_to_magnitude;

signal right_s00_axis_tready_int, left_s00_axis_tready_int : std_logic := '0';

begin


-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
left_fft : xfft_1
  PORT MAP (
    aclk => s00_axis_aclk,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_config_tvalid => s_axis_config_tvalid,
    s_axis_config_tready => open,
    s_axis_data_tdata => unfiltered_data_int,
    s_axis_data_tvalid => input_left_valid,
    s_axis_data_tready => left_s00_axis_tready_int,
    s_axis_data_tlast => tlast,
    
    m_axis_data_tdata => left_fft_data_int,
    m_axis_data_tuser => left_fft_bram_wr_addr,
    m_axis_data_tvalid => left_fft_bram_wr_en(0),
    m_axis_data_tready => '1',
    m_axis_data_tlast => open,
    event_frame_started => open,
    event_tlast_unexpected => open,
    event_tlast_missing => open,
    event_status_channel_halt => open,
    event_data_in_channel_halt => open,
    event_data_out_channel_halt => open
  );
  
right_fft : xfft_1
  PORT MAP (
    aclk => s00_axis_aclk,
    s_axis_config_tdata => s_axis_config_tdata,
    s_axis_config_tvalid => s_axis_config_tvalid,
    s_axis_config_tready => open,
    s_axis_data_tdata => unfiltered_data_int,
    s_axis_data_tvalid => input_right_valid,
    s_axis_data_tready => right_s00_axis_tready_int,
    s_axis_data_tlast => tlast,
    
    m_axis_data_tdata => right_fft_data_int,
    m_axis_data_tuser => right_fft_bram_wr_addr,
    m_axis_data_tvalid => right_fft_bram_wr_en(0),
    m_axis_data_tready => '1',
    m_axis_data_tlast => open,
    event_frame_started => open,
    event_tlast_unexpected => open,
    event_tlast_missing => open,
    event_status_channel_halt => open,
    event_data_in_channel_halt => open,
    event_data_out_channel_halt => open
  );
  
s00_axis_tready <= right_s00_axis_tready_int when left_en = '0' else left_s00_axis_tready_int;
  
left_fft_block_ram : fft_block_ram
  PORT MAP (
    clka => s00_axis_aclk,
    wea => left_fft_bram_wr_en,
    addra => left_fft_bram_wr_addr,
    dina => left_fft_bram_wr_data,
    clkb => s00_axis_aclk,
    addrb => left_fft_bram_rd_addr,
    doutb => left_fft_bram_rd_data
  );
  
right_fft_block_ram : fft_block_ram
  PORT MAP (
    clka => s00_axis_aclk,
    wea => right_fft_bram_wr_en,
    addra => right_fft_bram_wr_addr,
    dina => right_fft_bram_wr_data,
    clkb => s00_axis_aclk,
    addrb => right_fft_bram_rd_addr,
    doutb => right_fft_bram_rd_data
  );
  
left_fft_output_to_magnitude_i: component fft_output_to_magnitude
     port map (
      fft_abs_o(31 downto 0) => left_fft_bram_wr_data,
      fft_axis_data_i(31 downto 0) => left_fft_data_int
    );
    
right_fft_output_to_magnitude_i: component fft_output_to_magnitude
     port map (
      fft_abs_o(31 downto 0) => right_fft_bram_wr_data,
      fft_axis_data_i(31 downto 0) => right_fft_data_int
    );
  
 
  
left_en <= not(s00_axis_tdata(LR_INDEX));
input_left_valid <= left_en AND s00_axis_tvalid;

right_en <= (s00_axis_tdata(LR_INDEX));
input_right_valid <= right_en AND s00_axis_tvalid;

tlast <= '0';

unfiltered_data_int <= x"0000" & s00_axis_tdata(AUDIO_DATA_WIDTH - 1 downto AUDIO_DATA_WIDTH - FFT_DATA_WIDTH); -- need to rm the 8 LSBs b/c FFT filter takes in 16 bits


end Behavioral;
