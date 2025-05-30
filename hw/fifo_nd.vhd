----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: FIFO buffer with AXI stream valid signal. Noah;s version
----------------------------------------------------------------------------
-- Library Declarations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity fifo is
Generic (
    FIFO_DEPTH : integer := 1024;
    DATA_WIDTH : integer := 32);
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
end fifo;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of fifo is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
type mem_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal fifo_buf : mem_type := (others => (others => '0'));

signal read_pointer, write_pointer : integer range 0 to FIFO_DEPTH-1 := 0;
signal data_count : integer range 0 to FIFO_DEPTH := 0;

signal full_int : std_logic := '0';
signal empty_int : std_logic := '1';

signal w_en_int : std_logic := '0';
signal r_en_int : std_logic := '0';

signal data_out_int : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Processes and Logic
----------------------------------------------------------------------------
-- Internal signals for logic
empty_int <= '1' when (data_count = 0) else '0'; 
full_int <= '1' when (data_count = FIFO_DEPTH) else '0'; 

w_en_int <= wr_en_i AND not(full_int); --only internally enable wriitng if enabled, and not full
r_en_int <= rd_en_i AND not(empty_int);

--Internal logic to output
empty_o <= empty_int;
full_o <= full_int;

--Memory
buffer_mem : process (clk_i) begin
    if rising_edge(clk_i) then
        if (w_en_int = '1') then
            fifo_buf(write_pointer) <= wr_data_i;
        end if;
        if (r_en_int = '1') then
            data_out_int <= fifo_buf(read_pointer);  --pointer itself is syncronous, so this is fine...?
        end if;
    end if;
end process buffer_mem;
rd_data_o <= data_out_int;

-- Pointer Counters
w_addr_cnt : process (clk_i) begin --writing
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            write_pointer <= 0;
        elsif (w_en_int = '1') then   --writing and not full
            if (write_pointer < (FIFO_DEPTH - 1)) then
                write_pointer <= write_pointer + 1;
            else
                write_pointer <= 0;
            end if;
        end if;
    end if;
end process w_addr_cnt;

r_addr_cnt : process (clk_i) begin --reading
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            read_pointer <= 0;
        elsif (r_en_int = '1') then  --if we want to read and are not empty
            if (read_pointer < (FIFO_DEPTH - 1)) then
                read_pointer <= read_pointer + 1;
            else
                read_pointer <= 0;
            end if;
        end if;
    end if;
end process r_addr_cnt;



--Storage Counter
stored_cnt : process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            data_count <= 0;
        else
            if (w_en_int = '1' AND r_en_int = '1') then
                --hold
            elsif (w_en_int = '1') then
                data_count <= data_count + 1;
            elsif (r_en_int = '1') then
                data_count <= data_count - 1;
            else
                --hold
            end if; 
        end if;
    end if;
end process stored_cnt;


end Behavioral;
