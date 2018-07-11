library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity debouncer is
    generic(
        num_cons_cycles : integer := 8);
    port(
        clk : in std_logic;
        clk_en : in std_logic;
        data_in : in std_logic;
        data_deb : out std_logic;
        deb_err : out std_logic);
end debouncer;

architecture Behavorial of debouncer is

constant cntr_size : integer := integer(ceil(log2(real(num_cons_cycles))));
signal cntr_reg : unsigned(cntr_size-1 downto 0) := (others => '0');
signal cntr_next : unsigned(cntr_size-1 downto 0);
signal syncbuf_reg : std_logic_vector(2 downto 0) := (others => '0');
signal syncbuf_next : std_logic_vector(2 downto 0);
signal deb_reg : std_logic;
signal deb_next : std_logic;
signal error_reg : std_logic;
signal error_next : std_logic := '0';

begin

    reg_proc : process (clk)
    begin
        if rising_edge(clk) AND clk_en = '1' then
            syncbuf_reg <= syncbuf_next;
            cntr_reg <= cntr_next;
            deb_reg <= deb_next;
            error_reg <= error_next;
        end if;
    end process reg_proc;
    
    syncbuf_next <= syncbuf_reg(1 downto 0) & data_in;
        
    deb_proc : process(syncbuf_reg(2 downto 1), cntr_reg, deb_reg, data_in)
    begin
    
        deb_next <= deb_reg; -- default
        cntr_next <= cntr_reg; -- default
        error_next <= error_reg; -- default
        
        if syncbuf_reg(1) = syncbuf_reg(2) then -- sync. data stable?
            if cntr_reg = num_cons_cycles then
                deb_next <= syncbuf_reg(2);
                error_next <= '0';
            else
                cntr_next <= cntr_reg + 1;
            end if;
        else
            cntr_next <= (others => '0'); -- data not stable
            error_next <= '1';
        end if;
    
    end process deb_proc;
    
    data_deb <= deb_reg;
    deb_err <= error_reg;

end Behavorial;
