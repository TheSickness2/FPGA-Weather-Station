library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga_basic_safe is
    port ( 
        clk_in : in std_logic; --clock input
        in_1 : in std_logic; --button input
        in_2 : in std_logic;
        blink_o : out std_logic; --output for alternating signal (1Hz)
        and_o : out std_logic; --output for and op
        or_o : out std_logic -- output for or op
    );
end fpga_basic_safe;

architecture impl of fpga_basic_safe is
component clk_wiz_0
    port(
        clk_in1 : in std_logic;
        clk_out1 : out std_logic
    );
end component;

component debouncer is
    generic(
        num_cons_cycles : integer := 2000;
        cntr_size : integer := 11
    );
    port(
        clk : in std_logic;
        data_in : in std_logic;
        data_deb : out std_logic
    );
end component;

signal clk : std_logic; --system clock, couple output clk_out1 of clk_wiz to this module 
signal cntr_reg : unsigned(20 downto 0); --counter
signal cntr_next : unsigned(20 downto 0);

--debounced data from debouncer module
signal in1_deb : std_logic; 
signal in2_deb : std_logic;

--output buffers
signal andbuf_reg : std_logic := '0';  
signal andbuf_next : std_logic;
signal orbuf_reg : std_logic := '0';
signal orbuf_next : std_logic;

begin
    clk_mngt : clk_wiz_0
    port map(
        clk_in1 => clk_in,
        clk_out1 => clk
    );

    deb1 : debouncer
    generic map(
        num_cons_cycles => 100,
        cntr_size => 7
    )
    port map(
        clk => clk,
        data_in => in_1,
        data_deb => in1_deb
    );

    deb2 : debouncer
    generic map(
        num_cons_cycles => 100,
        cntr_size => 7
    )
    port map(
        clk => clk,
        data_in => in_2,
        data_deb => in2_deb
    );
    
    --concurrent part
    --shift debounced data into output buffer
    andbuf_next <= in1_deb and in2_deb;
    orbuf_next <= in1_deb or in2_deb;
    
    --sequential part
    process(clk)
    begin
        if rising_edge(clk) then
            cntr_reg <= cntr_next;
            andbuf_reg <= andbuf_next;
            orbuf_reg <= orbuf_next;
        end if;
    end process;
    
    cntr_next <= cntr_reg +1;
    and_o <= andbuf_reg;
    or_o <= orbuf_reg;
    blink_o <= cntr_reg(20);
end impl;
