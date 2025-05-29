----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Wyatt Ellison ES128 Lab 2
-- 
-- Create Date: 04/27/2025 06:01:46 PM
-- Design Name: 
-- Module Name: axis_transmitter_interface - Behavioral
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

entity axis_transmitter_interface is
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

end axis_transmitter_interface;

architecture Behavioral of axis_transmitter_interface is


----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Constants

-- Signal declarations
signal left_audio_data_reg, right_audio_data_reg : std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0) := (others => '0');
signal lr_mux_sel, enable_data_reg : std_logic := '0';

signal zero_padding : std_logic_vector(C_AXI_STREAM_DATA_WIDTH - AC_DATA_WIDTH - 2 downto 0) := (others => '0');    --padding to put onto end of read in data, allowing for general width, minus data width, minus a lead MSB

--FSM States
type state_type is (IdleHigh, LatchInputs, IdleLow, SetLeftValid, SetRightValid);
signal curr_state, next_state : state_type := IdleHigh;




-- Signal declarations

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------

begin

----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    

----------------------------------------------------------------------------
m00_axis_tlast <= '0';    -- all data is part of the same stream
m00_axis_tstrb <= (others => '1');      -- all bytes contain valid data
----------------------------------------------------------------------------    


----------------------------------------------------------------------------
-- Processes
----------------------------------------------------------------------------   
-- concat and capture process
audio_data_reg_process : process(m00_axis_aclk)
begin
	if rising_edge(m00_axis_aclk) then
		if (enable_data_reg = '1') then
			left_audio_data_reg <= '0' & zero_padding & left_audio_data_i; --MSB of 1 indicates right data and 0 means left
			right_audio_data_reg <= '1' & zero_padding & right_audio_data_i;
		end if;
	end if;
end process audio_data_reg_process;

-- output mux select process 
output_channel_sel_mux : process(left_audio_data_reg, right_audio_data_reg, lr_mux_sel)
begin
	if (lr_mux_sel = '1') then
		m00_axis_tdata <= right_audio_data_reg;
	else
		m00_axis_tdata <= left_audio_data_reg;
	end if;
end process output_channel_sel_mux;


 --fsm processes--
update_state : process(m00_axis_aclk)
begin
	if rising_edge(m00_axis_aclk) then
		curr_state <= next_state;
	end if;
end process update_state;

next_state_logic : process(curr_state, lrclk_i, m00_axis_tready)
begin
	next_state <= curr_state;
	case curr_state is
		when IdleHigh =>
			if lrclk_i = '0' then
				next_state <= LatchInputs;
			end if;
		when LatchInputs =>
			next_state <= IdleLow;
		when IdleLow =>
			if lrclk_i = '1' then
				next_state <= SetLeftValid;
			end if;
		when SetLeftValid =>
				if m00_axis_tready = '1' then
					next_state <= SetRightValid;
				end if;
		when SetRightValid =>
				if m00_axis_tready = '1' then
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
	m00_axis_tvalid <= '0';
	lr_mux_sel <= '0';
	case curr_state is
		when IdleHigh =>
			lr_mux_sel <= '1';
		when LatchInputs =>
			enable_data_reg <= '1';
		when IdleLow =>
			null;
		when SetLeftValid =>
			m00_axis_tvalid <= '1';
		when SetRightValid =>
			lr_mux_sel <= '1';
			m00_axis_tvalid <= '1';
		when others =>
			null;
	end case;
end process output_logic;


end Behavioral;
