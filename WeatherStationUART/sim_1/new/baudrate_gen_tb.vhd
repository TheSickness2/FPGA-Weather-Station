library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baudrate_gen_tb is
end baudrate_gen_tb;

architecture Behavioral of baudrate_gen_tb is

component baudrate_gen is
    generic(
        clk_freq    : integer := 100_000_000;   -- frequency of system clock in Hertz
        baud_rate	: integer := 9_600;		    -- data link baud rate in bits/second
        os_rate		: integer := 16);           -- oversampling rate to find center of receive bits (in samples per baud period)
    port(
        clk		    : in std_logic;     -- system clock
        reset_n     : in std_logic;     -- asynchronous reset
        baud_pulse  : out std_logic;    -- periodic pulse that occurs at the baud rate
        os_pulse    : out std_logic);   -- periodic pulse that occurs at the oversampling rate
end component baudrate_gen;

signal clock        : std_logic := '0';
signal reset_n      : std_logic := '1';
signal baud_pulse   : std_logic;
signal os_pulse     : std_logic;

begin

-- instantiate baudrate generator
DUT : baudrate_gen
    generic map(
        clk_freq    => 1_000_000,
        baud_rate	=> 10_000,
        os_rate		=> 10)
    port map(
        clk		    => clock,
        reset_n     => reset_n,
        baud_pulse  => baud_pulse,
        os_pulse    => os_pulse);
        
clock <= not clock after 50 ns;

process is
begin
 
    wait for 29025 ns;
    reset_n <= '0';
    wait for 300 ns;
    reset_n <= '1';
     
end process;

end Behavioral;
