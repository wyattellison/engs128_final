----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: Controller/FSM for I2S Transmitter
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity i2s_transmitter_controller is
    Generic (
        DATA_WIDTH : integer := 24
    );
    Port (
        lrclk_i : in STD_LOGIC;
        count_tc_i : in STD_LOGIC;
        bclk_i : in std_logic;
        mclk_i : in std_logic;
           
        shift_en_o : out STD_LOGIC;
        load_en_o : out STD_LOGIC;
        count_rst_o : out STD_LOGIC);
end i2s_transmitter_controller;

architecture Behavioral of i2s_transmitter_controller is

--FSM States
type state_type is (Idle_l, Load_l, Shift_l, Idle_r, Load_r, Shift_r);
signal curr_state, next_state : state_type := Idle_l;


begin

next_state_logic : process(curr_state, lrclk_i,  count_tc_i) begin
    next_state <= curr_state;
    
    case curr_state is
        when Idle_l =>
            if (lrclk_i = '0') then
                next_state <= Load_l;
            end if;
        when Load_l =>
            next_state <= Shift_l;
        when Shift_l =>
            if (count_tc_i = '1') then
                next_state <= Idle_r;
            end if;
        when Idle_r =>
            if (lrclk_i = '1') then
                next_state <= Load_r;
            end if;
        when Load_r =>
            next_state <= SHift_r;
        when Shift_r =>
            if (count_tc_i = '1') then
                next_state <= Idle_l;
            end if;
        when others =>
            next_state <= Idle_l;   --default to Idle left, since that is all 0s
    end case;
end process next_state_logic;

output_logic : process(curr_state) begin
    shift_en_o <= '0';
    load_en_o <= '0';
    count_rst_o <= '0';
    
    case curr_state is
        when Idle_l =>
            --Default values
        when Load_l =>
            load_en_o <= '1';
            count_rst_o <= '1';
        when Shift_l =>
            shift_en_o <= '1';
        when Idle_r =>
            --Defaults
        when Load_r =>
            load_en_o <= '1';
            count_rst_o <= '1';
        when Shift_r =>
            shift_en_o <= '1';
        when others =>
            --defaults
    end case;
end process output_logic;

change_state : process(bclk_i) begin
    if (rising_edge(bclk_i)) then
        curr_state <= next_state;
    end if;
end process change_state;

end Behavioral;
