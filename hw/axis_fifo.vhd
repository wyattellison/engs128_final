----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI Stream FIFO Controller/Responder Interface 
----------------------------------------------------------------------------
-- Library Declarations
library ieee;
use ieee.std_logic_1164.all;

----------------------------------------------------------------------------
-- Entity definition
entity axis_fifo is
	generic (
		DATA_WIDTH	: integer	:= 32;
		FIFO_DEPTH	: integer	:= 1024
	);
	port (
	
		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
	);
end axis_fifo;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of axis_fifo is
----------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------  
signal reset_int, full_int : std_logic := '0'; --undo the active low of the AXI
signal last_resetn_int : std_logic := '0';   --to adhere to axis timing
signal empty_int : std_logic := '1';

----------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------  
component fifo is
    Generic (
		FIFO_DEPTH : integer := FIFO_DEPTH;
        DATA_WIDTH : integer := DATA_WIDTH);
    Port ( 
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        -- Write channel
        wr_en_i     : in std_logic;
        wr_data_i   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read channel
        rd_en_i     : in std_logic;
        rd_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Status flags
        empty_o         : out std_logic;
        full_o          : out std_logic);   
end component fifo;

----------------------------------------------------------------------------
begin

----------------------------------------------------------------------------
-- Component Instantiations
----------------------------------------------------------------------------   
internal_fifo : fifo
    Port map(
        reset_i => reset_int,
        wr_en_i => s00_axis_tvalid, --fifo checks to make sure it isn't full/empty, protection there
        wr_data_i => s00_axis_tdata,
        rd_en_i => m00_axis_tready,
        clk_i => s00_axis_aclk,
        
        rd_data_o => m00_axis_tdata,
        empty_o => empty_int,
        full_o => full_int
    );

----------------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------------  
last_reset : process (s00_axis_aclk) begin
    if rising_edge(s00_axis_aclk) then
        last_resetn_int <= s00_axis_aresetn;
        reset_int <= not(s00_axis_aresetn AND last_resetn_int);  --reset stays asserted for at least one clock cycle after 
        s00_axis_tready <= not(full_int) AND not(reset_int); --could also NOR, hopefully synth does that for us
        m00_axis_tvalid <= not(empty_int) AND not(reset_int);  --forced to be asserted for one extra cycle, as per specs https://docs.amd.com/r/en-US/pg085-axi4stream-infrastructure/Resets
    end if;
end process last_reset;


m00_axis_tstrb <= (others => '1');  --tie it high
m00_axis_tlast <= '0';      --tie it low


end Behavioral;
