----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: I2S Receiver Controller for ENGS128 Lab 1
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2s_receiver_controller is
    Generic(
        DATA_WIDTH : integer := 24
    );
    Port ( 
        lrclk_i : in std_logic;
        bclk_i : in std_logic;
        load_done_i : in std_logic;
        
        load_en_o : out std_logic;
        count_rst_o : out std_logic
    );
end i2s_receiver_controller;

architecture Behavioral of i2s_receiver_controller is

--FSM States
type state_type is (Idle_l, Load_l, Idle_r, Load_r);
signal curr_state, next_state : state_type := Idle_l;

begin

next_state_logic : process(curr_state, lrclk_i,  load_done_i) begin
    next_state <= curr_state;
    
    case curr_state is
        when Idle_l =>
            if (lrclk_i = '0') then
                next_state <= Load_l;
            end if;
        when Load_l =>
            if (load_done_i = '1') then
                next_state <= Idle_r;
            end if;
        when Idle_r =>
            if (lrclk_i = '1') then
                next_state <= Load_r;
            end if;
        when Load_r =>
            if (load_done_i = '1') then
                next_state <= Idle_l;
            end if;
        when others =>
            next_state <= Idle_l;   --default to Idle left, since that is all 0s
    end case;
end process next_state_logic;

output_logic : process(curr_state) begin
    load_en_o <= '0';
    count_rst_o <= '0';
    
    case curr_state is
        when Idle_l =>
            count_rst_o <= '1';     
        when Load_l =>
            load_en_o <= '1';
        when Idle_r =>
            count_rst_o <= '1';  
        when Load_r =>
            load_en_o <= '1';
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
