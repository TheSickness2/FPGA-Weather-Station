----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.07.2018 00:37:35
-- Design Name: 
-- Module Name: user_logic - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity user_logic is
    port(
        CLK100MHZ : in std_logic;   -- system clock
        
        vp : in std_logic;  -- Dedicated analog input (not used)
        vn : in std_logic;
        vauxp0 : in std_logic;  -- Auxiliary input 0 (A0), connected to photocell
        vauxn0 : in std_logic;
        vauxp1 : in std_logic;  -- Auxiliary input 1 (A1), connected to temperature sensor
        vauxn1 : in std_logic;
        
        rx : in std_logic;  -- UART receive pin (IO0)
        tx : out std_logic; -- UART transmit pin (IO1)
        
        seg1 : out std_logic_vector(6 downto 0); -- Seven-segment display on PMOD headers JA/JB
        cat1 : out std_logic;
        seg2 : out std_logic_vector(6 downto 0); -- Seven-segment display on PMOD headers JC/JD
        cat2 : out std_logic
    );
end user_logic;


architecture Behavioral of user_logic is

component analog_sensors is
    port(
        clk100mhz : in std_logic;                       -- system clock
        vp : in std_logic;                              -- dedicated analog input (not used)
        vn : in std_logic;
        vauxp0 : in std_logic;                          -- auxiliary input 0 (A0)
        vauxn0 : in std_logic;
        vauxp1 : in std_logic;                          -- auxiliary input 1 (A1)
        vauxn1 : in std_logic;
        pin_select : in std_logic;                      -- toggles between inputs, '0' for A0 and '1' for A1
        data_out : buffer std_logic_vector(11 downto 0) -- 12-bit ADC data output corresponding to pin_select
    );
end component analog_sensors;

component uart_rxtx is
    generic(
        clk_freq    : integer     := 100_000_000;   -- frequency of system clock in Hertz
        baud_rate   : integer     := 9_600;         -- data link baud rate in bits/second
        os_rate		: integer     := 16;            -- oversampling rate (in samples per baud period)
        d_width		: integer     := 8;             -- data bus width
        stop_bits   : integer     := 1;             -- number of stop bits
        use_parity	: integer     := 0;             -- 0 for no parity, 1 for parity
        parity_eo	: std_logic   := '0'            -- '0' for even, '1' for odd parity
    );
    port(
        clk      : in std_logic;                                -- system clock
        reset_n  : in std_logic;                                -- asynchronous reset
        tx_en    : in std_logic;                                -- initiates transmission, latches in transmit data
        tx_data  : in std_logic_vector(d_width-1 downto 0);     -- data to transmit
        rx		 : in std_logic;							    -- receive pin
        tx       : out std_logic;                               -- transmit pin
        tx_busy  : out std_logic;                               -- transmission in progress
        rx_done  : out std_logic;                               -- data reception finished
        rx_error : out std_logic;                               -- start, parity, or stop bit error detected
        rx_data  : out std_logic_vector(d_width-1 downto 0)     -- data received
    );
end component uart_rxtx;

component pwm is
    port(
        clk : in std_logic;
        dc : in std_logic_vector(5 downto 0);
        pwm : out std_logic
    );
end component;

component sseg_arty_2dig is 
    port(
        clk100 : in std_logic;
        binval : in std_logic_vector(5 downto 0);
        seg : out std_logic_vector(6 downto 0);
        cat : out std_logic
    );
end component;

-- PWM output and duty cycle register
signal pwm_out : std_logic;
signal dcval_reg : unsigned(5 downto 0):= (others => '0');
signal dcval_next : unsigned(5 downto 0);

-- UART configuration
constant CLK_RATE   : integer   := 100_000_000;
constant BAUD_RATE  : integer   := 9_600;
constant OS_RATE    : integer   := 16;
constant D_WIDTH    : integer   := 8;
constant STOP_BITS  : integer   := 1;
constant PARITY     : integer   := 0;
constant PARITY_EO  : std_logic := '0';

-- UART registers and pins
signal reset_n : std_logic := '1';
signal tx_en : std_logic := '0';
signal tx_en_next : std_logic := '0';
signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal tx_data_next : std_logic_vector(7 downto 0) := (others => '0');
signal tx_busy : std_logic;
signal rx_done : std_logic;
signal rx_data : std_logic_vector(7 downto 0);
signal rx_err : std_logic;

-- Analog sensor registers
signal pin_sel : std_logic := '0';
signal pin_sel_next : std_logic := '0';
signal sensor_value_next : std_logic_vector(11 downto 0);
signal last_temperature : std_logic_vector(11 downto 0);    -- holds the last temperature measurement
signal last_brightness : std_logic_vector(11 downto 0);     -- holds the last brightness measurement

begin

sense0 : analog_sensors
port map(
    clk100mhz => CLK100MHZ,
    vp => vp,
    vn => vn,
    vauxp0 => vauxp0,
    vauxn0 => vauxn0,
    vauxp1 => vauxp1,
    vauxn1 => vauxn1,
    pin_select => pin_sel,
    data_out => sensor_value_next
);

uart : uart_rxtx
generic map(
    clk_freq    => CLK_RATE,
    baud_rate   => BAUD_RATE,
    os_rate		=> OS_RATE,
    d_width		=> D_WIDTH,
    stop_bits   => STOP_BITS,
    use_parity	=> PARITY,
    parity_eo	=> PARITY_EO
)
port map(
    clk      => CLK100MHZ,
    reset_n  => reset_n,
    tx_en    => tx_en,
    tx_data  => tx_data,
    rx		 => rx,
    tx       => tx,
    tx_busy  => tx_busy,
    rx_done  => rx_done,
    rx_error => rx_err,
    rx_data  => rx_data
);

pwm0 : pwm
port map(
    clk => CLK100MHZ,
    dc => std_logic_vector(dcval_reg),
    pwm => pwm_out
);

disp1 : sseg_arty_2dig
port map(
    clk100 => CLK100MHZ,
    binval => std_logic_vector(dcval_reg),  -- TODO: put temperature value here! (e.g. mapping of last_temperature)
    seg => seg1,
    cat => cat1
);

disp2 : sseg_arty_2dig
port map(
    clk100 => CLK100MHZ,
    binval => std_logic_vector(dcval_reg),  -- TODO: put brightness value here! (e.g. mapping of last_brightness)
    seg => seg2,
    cat => cat2
);

upd_proc : process(CLK100MHZ)   -- update working registers
begin
    if rising_edge(CLK100MHZ) then
        pin_sel <= pin_sel_next;
        tx_en <= tx_en_next;
        tx_data <= tx_data_next;
        dcval_reg <= dcval_next;
    end if;
end process upd_proc;

-- TODO: After pin_sel has changed, e.g. is '0', the new measurement
-- *may* not be there already, i.e. last_brightness would actually still
-- show the value read out of the temperature sensor!
fetch_measureval_proc : process(CLK100MHZ)   -- fetch sensor measurements
begin
    if rising_edge(CLK100MHZ) then
        if pin_sel = '0' then   -- we read the photocell
            last_brightness <= sensor_value_next;
            last_temperature <= last_temperature;
        else                    -- we read the temp sensor
            last_brightness <= last_brightness;
            last_temperature <= sensor_value_next;
        end if;
    end if;
end process fetch_measureval_proc;

end Behavioral;
