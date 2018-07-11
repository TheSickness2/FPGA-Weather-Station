library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity uart_tx_tb is
end uart_tx_tb;
 
architecture Behavioral of uart_tx_tb is

component uart_tx is
    generic(
        d_width     : integer     := 8;    -- data bus width
        stop_bits   : integer     := 1;    -- number of stop bits
        use_parity  : integer     := 0;    -- 0 for no parity, 1 for parity
        parity_eo   : std_logic   := '0'); -- '0' for even, '1' for odd parity
    port(
        clk     : in std_logic;                             -- system clock
        clk_en  : in std_logic;                             -- clock enable indicating baud pulses
        reset_n : in std_logic;                             -- asynchronous reset
        tx_en   : in std_logic;                             -- initiates transmission, latches in transmit data
        tx_data : in std_logic_vector(d_width-1 downto 0);  -- data to transmit
        tx_busy : out std_logic;                            -- transmission in progress
        tx      : out std_logic);                            -- transmit pin
end component uart_tx;

signal clock     : std_logic                    := '0';
signal clock_en  : std_logic                    := '1';
signal tx_enable : std_logic                    := '0';
signal tx_byte   : std_logic_vector(7 downto 0) := (others => '0');
signal tx_serial : std_logic;
signal tx_busy   : std_logic;

   
begin
 
-- Instantiate UART transmitter
UART_TX_INST : uart_tx
    generic map(
        d_width     => 8,
        stop_bits   => 1,
        use_parity  => 0,
        parity_eo   => '0')
    port map(
        clk     => clock,
        clk_en  => clock_en,
        reset_n => '1',
        tx_en   => tx_enable,
        tx_data => tx_byte,
        tx_busy => tx_busy,
        tx      => tx_serial);
 
clock       <= not clock after 50 ns;
clock_en    <= not clock_en after 150 ns;

process is
begin
 
    -- Tell the UART to send a command.
    wait until rising_edge(clock);
    tx_enable <= '1';
    tx_byte   <= X"53";
    wait until rising_edge(clock);
    tx_enable <= '0';
    wait until tx_busy = '0';
    -- repeat
    tx_enable <= '1';
    tx_byte   <= X"AC";
    wait until rising_edge(clock);
    tx_enable <= '0';
    wait until tx_busy = '0';
     
end process;
   
end Behavioral;