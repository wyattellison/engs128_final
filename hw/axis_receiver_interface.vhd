----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Wyatt Ellison ES128 Lab 2
-- 
-- Create Date: 04/27/2025 06:01:46 PM
-- Design Name: 
-- Module Name: axis_receiver_interface - Behavioral
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

entity axis_receiver_interface is
generic (
    -- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
    C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
    AC_DATA_WIDTH : integer := 24
);
Port (
    s00_axis_aclk : in std_logic;
    s00_axis_aresetn : in std_logic;
    s00_axis_tdata : in std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
    s00_axis_tlast : in std_logic;
    s00_axis_tstrb : in std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
    s00_axis_tvalid : in std_logic;
    
    lrclk_i : in std_logic;
    
    left_audio_data_o : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
    right_audio_data_o : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
    s00_axis_tready : out std_logic);
end axis_receiver_interface;

architecture Behavioral of axis_receiver_interface is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Constants


-- Signal declarations
signal axis_data_reg_0, axis_data_reg_1: std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0) := (others => '0');
signal s_ready_internal, enable_data_reg, lr_sel : std_logic := '0';
signal left_audio_data_reg, right_audio_data_reg : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

--FSM States
type state_type is (IdleHigh, LatchOutputs, IdleLow, SetLeftReady, SetRightReady);
signal curr_state, next_state : state_type := IdleHigh;

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------

begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    

-- processes

-- decoder: lr_sel gets MSB of axis_data_reg_1
lr_sel <= axis_data_reg_1(C_AXI_STREAM_DATA_WIDTH-1);

axis_data_reg_proc : process(s00_axis_aclk)
begin
	if rising_edge(s00_axis_aclk) then
		if s00_axis_tvalid = '1' and s_ready_internal = '1' then
			axis_data_reg_1 <= axis_data_reg_0;
			axis_data_reg_0 <= s00_axis_tdata;
		end if;
	end if;
end process axis_data_reg_proc;

audio_data_reg_proc : process(s00_axis_aclk)
begin
	if rising_edge(s00_axis_aclk) then
		if enable_data_reg = '1' then
			if (lr_sel = '0') then -- mux selects which is right/left
				left_audio_data_reg <= axis_data_reg_1(AC_DATA_WIDTH-1 downto 0);
				right_audio_data_reg <= axis_data_reg_0(AC_DATA_WIDTH-1 downto 0);
			else
				right_audio_data_reg <= axis_data_reg_1(AC_DATA_WIDTH-1 downto 0);
				left_audio_data_reg <= axis_data_reg_0(AC_DATA_WIDTH-1 downto 0);
			end if;
		end if;
	end if;
end process audio_data_reg_proc;

-- tie the audio data registers to the outputs
left_audio_data_o <= left_audio_data_reg;
right_audio_data_o <= right_audio_data_reg;

--fsm processes--
update_state : process(s00_axis_aclk)
begin
	if rising_edge(s00_axis_aclk) then
		curr_state <= next_state;
	end if;
end process update_state;

next_state_logic : process(curr_state, lrclk_i, s00_axis_tvalid)
begin
	next_state <= curr_state;
	case curr_state is
		when IdleHigh =>
			if lrclk_i = '0' then
				next_state <= LatchOutputs;
			end if;
		when LatchOutputs =>
			next_state <= IdleLow;
		when IdleLow =>
			if lrclk_i = '1' then
				next_state <= SetLeftReady;
			end if;
		when SetLeftReady =>
			if s00_axis_tvalid = '1' then
				next_state <= SetRightReady;
			end if;
		when SetRightReady =>
			if s00_axis_tvalid = '1' then
				next_state <= IdleHigh;
			end if;
		when others =>
			next_state <= IdleHigh;
	end case;

end process next_state_logic;

output_logic : process(curr_state)
begin
	-- defaults
	enable_data_reg <= '0';
	s_ready_internal <= '0';
	case curr_state is
		when IdleHigh =>
			null;
		when LatchOutputs =>
			enable_data_reg <= '1';
		when IdleLow =>
			null;
		when SetLeftReady =>
		      s_ready_internal <= '1';
		when SetRightReady =>
		      s_ready_internal <= '1';
		when others =>
			null;
	end case;
end process output_logic;
-- tie s_ready_internal fsm signal to axis output
s00_axis_tready <= s_ready_internal;



end Behavioral;
