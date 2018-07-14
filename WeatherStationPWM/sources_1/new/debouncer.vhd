library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic(
        num_cons_cycles : integer := 2000; --cycles within input must not change to be stable
        cntr_size : integer := 11   --counter size fits to 2000 cycles, for counter register below
    );
    port ( 
        clk : in std_logic;
        data_in : in std_logic;
        data_deb : out std_logic
    );
end debouncer;

architecture impl of debouncer is
-- constant cntr_size : integer := integer(ceil(log2(real(num_cons_cycles)))); --automized counter size calculation
signal cntr_reg : unsigned(cntr_size -1 downto 0) := (others => '0'); --register of size of cntr_size as above
signal cntr_next : unsigned(cntr_size -1 downto 0);

signal syncbuf_reg : std_logic_vector(2 downto 0) := (others => '0'); --register for synchronisation stage at input, 
--3 bits width as compare of 2 consecutive values is necessary and last 2 bits should be yet synchronous
signal syncbuf_next : std_logic_vector(2 downto 0);

signal deb_reg : std_logic;
signal deb_next : std_logic;

begin
    --register update
    reg_proc : process(clk)
    begin
        if rising_edge(clk) then
            syncbuf_reg <= syncbuf_next;
            cntr_reg <= cntr_next;
            deb_reg <= deb_next;
        end if;
   end process reg_proc;
   
   syncbuf_next <= syncbuf_reg(1 downto 0) & data_in; --shifting of the synchronisation stage

    --debouncing   
   deb_proc : process(syncbuf_reg(2 downto 1), cntr_reg, deb_reg, data_in)
   begin
        deb_next <= deb_reg; --default
        cntr_next <= cntr_reg; --default
        if syncbuf_reg(1) = syncbuf_reg(2) then --sync. data stable...
            if cntr_reg = num_cons_cycles then --for number of consolidation cycles (num_cons_cycles)?..
                deb_next <= syncbuf_reg(2); --then assign debounced value to output buffer
            else
                cntr_next <= cntr_reg +1;  --else count up
            end if;
        else
            cntr_next <= (others => '0'); --else if sync data not stable reset counter        
        end if; 
   end process deb_proc;
   
   data_deb <= deb_reg; --assign debounced value buffer to output
   
end impl;
