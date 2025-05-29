----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Noah Dunleavy
----------------------------------------------------------------------------
--	Description: Clock generation for I2S Communication
----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all; --for the ODDR


entity i2s_clock_gen is
    Generic (
        MCLK_TO_BCLK_DIV : integer := 4;
        BCLK_TO_LRCLK_DIV : integer := 64
    );
    Port ( 
        --Input signals
        --sys_clk_100MHz_i    : in std_logic; for pulling out ip core
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
end i2s_clock_gen;

architecture Behavioral of i2s_clock_gen is

-- Components

component clock_divider
    Generic (CLK_DIV_RATIO : integer := MCLK_TO_BCLK_DIV);
    Port (  fast_clk_i : in std_logic;		  
            slow_clk_o : out std_logic
    );
end component;

component i2s_falling_edge_clk_gen
    Generic (CLK_DIV_RATIO : integer := BCLK_TO_LRCLK_DIV);
    Port (  
        clk_i : in std_logic;		  
            
        bufg_clk_o  : out std_logic;
        clk_o    : out std_logic
    );
end component;


-- Constants

-- Signals
signal bufg_mclk_int : std_logic := '0';
signal bufg_bclk_int : std_logic := '0';
signal lrclk_int : std_logic := '0';
signal bufg_lrclk_int : std_logic := '0';


begin

-- Instantiation
bufg_mclk_int <= mclk_i;
 
mst_to_bit_clk : clock_divider
    Port map (
        fast_clk_i => bufg_mclk_int,
        
        slow_clk_o => bufg_bclk_int
    );
    
bclk_to_lr_clk : i2s_falling_edge_clk_gen
    Port map (
        clk_i => bufg_bclk_int,
        
        bufg_clk_o => bufg_lrclk_int,
        clk_o => lrclk_int
    ); 
 
fwd_mclk : ODDR
    Port map (
        C => bufg_mclk_int,   
        CE => '1', 
        D1 => '1', 
        D2 => '0', 
        R => '0', 
        S => '0',
        
        Q => mclk_fwd_o
    );
    
fwd_bclk : ODDR
    Port map (
        C => bufg_bclk_int,   
        CE => '1', 
        D1 => '1', 
        D2 => '0', 
        R => '0', 
        S => '0',
        
        Q => bclk_fwd_o
    );
    
fwd_adc_lr_clk : ODDR
    Port map (
        C => bufg_lrclk_int,   
        CE => '1', 
        D1 => '1', 
        D2 => '0', 
        R => '0', 
        S => '0',
        
        Q => adc_lrclk_fwd_o
    );
    
fwd_dac_lr_clk : ODDR
    Port map (
        C => bufg_lrclk_int,   
        CE => '1', 
        D1 => '1', 
        D2 => '0', 
        R => '0', 
        S => '0',
        
        Q => dac_lrclk_fwd_o
    );

--explictly point our internal bufg signal to output pins
mclk_o <= bufg_mclk_int;    
bclk_o <= bufg_bclk_int;
lrclk_o <= bufg_lrclk_int;
lrclk_unbuf_o <= lrclk_int;
    

end Behavioral;
