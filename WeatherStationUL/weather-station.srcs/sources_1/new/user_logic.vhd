----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Christopher Ringhofer, Nicolas Frick
-- 
-- Create Date: 13.07.2018 00:37:35
-- Design Name: 
-- Module Name: user_logic - Behavioral
-- Project Name: FPGA Weather Station
-- Target Devices: Digilent Arty S7-50 (Xilinx Spartan-7)
-- Tool Versions: 
-- Description: Implements the weather station user-logic.
-- 
-- Dependencies: analog_sensors, uart_rxtx, pwm, sseg_arty_2dig,
--  temp_conversion, light_conversion
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
        CLK100MHZ : in std_logic;   -- System clock
                
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
        cat2 : out std_logic;
        
        pwm_fan : out std_logic;
        pwm_led : out std_logic 
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

component temp_conversion is
    port(
        adc_tempval : in std_logic_vector(11 downto 0);
        temp_celsius : out std_logic_vector(5 downto 0);
        temp_tenths_celsius : out std_logic_vector(11 downto 0);
        ascii_temp_tenths : out std_logic_vector(7 downto 0);
        ascii_temp_ones : out std_logic_vector(7 downto 0);
        ascii_temp_tens : out std_logic_vector(7 downto 0);
        ascii_temp_hundreds : out std_logic_vector(7 downto 0)
    );
end component;

component light_conversion is
    port(
        adc_lightval : in std_logic_vector(11 downto 0);
        brightness : out std_logic_vector(5 downto 0);
        ascii_light_ones : out std_logic_vector(7 downto 0);
        ascii_light_tens : out std_logic_vector(7 downto 0)
    );
end component;


-- Analog sensor registers
signal pin_sel : std_logic := '0';
signal pin_sel_next : std_logic := '0';
signal sensor_value_next : std_logic_vector(11 downto 0);
signal last_temperature : std_logic_vector(11 downto 0);    -- holds the last temperature measurement
signal last_brightness : std_logic_vector(11 downto 0);     -- holds the last brightness measurement

-- Sensor values for visualization
signal temp_celsius : std_logic_vector(5 downto 0);
signal ascii_temp_tens : std_logic_vector(7 downto 0);
signal ascii_temp_ones : std_logic_vector(7 downto 0);
signal ascii_temp_tenths : std_logic_vector(7 downto 0);
signal brightness : std_logic_vector(5 downto 0);
signal ascii_bright_tens : std_logic_vector(7 downto 0);
signal ascii_bright_ones : std_logic_vector(7 downto 0);

-- PWM output and duty cycle register
signal pwm_out : std_logic;
signal dcval_reg : unsigned(5 downto 0):= (others => '0'); 
signal dcval_next : unsigned(5 downto 0);  

-- UART configuration
constant CLK_RATE   : integer   := 100_000_000;
constant BAUD_RATE  : integer   := 38_400;
constant OS_RATE    : integer   := 16;
constant D_WIDTH    : integer   := 8;
constant STOP_BITS  : integer   := 1;
constant PARITY     : integer   := 1;
constant PARITY_EO  : std_logic := '0';

-- UART registers and pins
signal reset_n : std_logic := '1';
signal tx_en : std_logic := '0';
signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal tx_internal : std_logic;
signal tx_busy : std_logic;
signal rx_done : std_logic;
signal rx_data : std_logic_vector(7 downto 0);
signal rx_err : std_logic;

--The type definition for the UART state machine type. Here is a description of what
--occurs during each state:
-- RST_REG     -- Do Nothing. This state is entered after configuration or a user reset.
--                The state is set to LD_TEMP_STR.
-- LD_TEMP_STR -- The Temperature String is loaded into the sendStr variable and the strIndex
--                variable is set to zero. The temp string length is stored in the StrEnd
--                variable. The state is set to SEND_CHAR.
-- SEND_CHAR   -- uartSend is set high for a single clock cycle, signaling the character
--                data at sendStr(strIndex) to be registered by the UART_TX_CTRL at the next
--                cycle. Also, strIndex is incremented (behaves as if it were post 
--                incremented after reading the sendStr data). The state is set to RDY_LOW.
-- RDY_LOW     -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go high, 
--                indicating a send operation has begun. State is set to WAIT_RDY.
-- WAIT_RDY    -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go low, 
--                indicating a send operation has finished. If READY is low and strEnd /=
--                StrIndex then state is set to SEND_CHAR.
type UART_STATE_TYPE is (RST_REG, LD_TEMP_STR, SEND_CHAR, RDY_LOW, WAIT_RDY);

--Current uart state signal
signal uartState : UART_STATE_TYPE := RST_REG;

--The CHAR_ARRAY type is a variable length array of 8 bit std_logic_vectors. 
--Each std_logic_vector contains an ASCII value and represents a character in
--a string. The character at index 0 is meant to represent the first
--character of the string, the character at index 1 is meant to represent the
--second character of the string, and so on.
type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);

constant TMR_CNTR_MAX : std_logic_vector(26 downto 0) := "101111101011110000100000000"; --100,000,000 = clk cycles per second
constant TMR_VAL_MAX : std_logic_vector(3 downto 0) := "1001"; --9

constant RESET_CNTR_MAX : unsigned(17 downto 0) := "110000110101000000"; -- 100,000,000 * 0.002 = 200,000 = clk cycles per 2 ms
constant LOG_CNTR_MAX : unsigned(29 downto 0) := "111110000011111000001111100000";

constant TEMP_STR_LEN : natural := 15;
constant LUX_STR_LEN : natural := 14;
constant SEND_STR_LEN : natural := TEMP_STR_LEN + LUX_STR_LEN + 6;
    
-- temperature string definition, the values stored at each index are the ASCII values of the indicated character
constant TEMP_STR : CHAR_ARRAY(0 to TEMP_STR_LEN-1) :=  (X"0A", --\n
                                                        X"0D",  --\r
                                                        X"54",  --T
                                                        X"65",  --e
                                                        X"6D",  --m
                                                        X"70",  --p
                                                        X"65",  --e
                                                        X"72",  --r
                                                        X"61",  --a
                                                        X"74",  --t
                                                        X"75",  --u
                                                        X"72",  --r
                                                        X"65",  --e
                                                        X"3A",  --:
                                                        X"20"); --
                                                          
constant LUX_STR : CHAR_ARRAY(0 to LUX_STR_LEN-1) :=    (X"2C", --,
                                                        X"20",  --
                                                        X"42",  --B
                                                        X"72",  --r
                                                        X"69",  --i
                                                        X"67",  --g
                                                        X"68",  --h
                                                        X"74",  --t
                                                        X"6E",  --n
                                                        X"65",  --e
                                                        X"73",  --s
                                                        X"73",  --s
                                                        X"3A",  --:
                                                        X"20"); --

--Contains the current string being sent over uart.
signal sendStr : CHAR_ARRAY(0 to (SEND_STR_LEN - 1));

--Contains the length of the current string being sent over uart.
signal strEnd : natural;

--Contains the index of the next character to be sent over uart
--within the sendStr variable.
signal strIndex : natural;

--this counter counts the amount of time to pass between log messages
signal log_cntr : unsigned(29 downto 0) := (others=>'0');

--this counter counts the amount of time paused in the UART reset state
signal reset_cntr : unsigned(17 downto 0) := (others=>'0');


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
    tx       => tx_internal,
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

-- shows brightness
disp1 : sseg_arty_2dig
port map(
    clk100 => CLK100MHZ,
    binval => brightness,
    seg => seg1,
    cat => cat1
);

-- shows temperature
disp2 : sseg_arty_2dig
port map(
    clk100 => CLK100MHZ,
    binval => temp_celsius,
    seg => seg2,
    cat => cat2
);

temp_conv : temp_conversion 
port map(
    adc_tempval => last_temperature,
    temp_celsius => temp_celsius,
    temp_tenths_celsius => open,
    ascii_temp_tenths => ascii_temp_tenths,
    ascii_temp_ones => ascii_temp_ones,
    ascii_temp_tens => ascii_temp_tens,
    ascii_temp_hundreds => open
);

light_conv : light_conversion
port map(
    adc_lightval => last_brightness,
    brightness => brightness,
    ascii_light_ones => ascii_bright_ones,
    ascii_light_tens => ascii_bright_tens
);


upd_proc : process(CLK100MHZ)   -- update working registers
begin
    if rising_edge(CLK100MHZ) then
        pin_sel <= pin_sel_next;
        dcval_reg <= dcval_next;
    end if;
end process upd_proc;

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

upd_pin : process(CLK100MHZ)
    variable counter : integer range 0 to (CLK_RATE / 4) := 0;  -- 0.25 seconds
begin
    if rising_edge(CLK100MHZ) then
        if counter < (CLK_RATE / 4) then
            counter := counter + 1;
            pin_sel_next <= pin_sel_next;
        else
            counter := 0;
            pin_sel_next <= not (pin_sel_next);
        end if;
    end if;
end process upd_pin;

setdc_proc : process(temp_celsius) --set pwm duty cycle in order to temperature changes, 1 degree = 10% increase
    variable deg : integer range 0 to 63 :=  to_integer(unsigned(temp_celsius)); --cast temperature value to allow math operations
begin
    dcval_next <= dcval_reg; --default
        case deg is --temperature range within the pwm works
            when 26 =>     --if temperature is 26 degrees
                dcval_next <= "011111"; --set dc to 31 (~50%)
            when 28 =>     --if temperature is 28 degrees
                dcval_next <= "100101"; --set dc to 37 (~60%)
            when 30 =>     --if temperature is 30 degrees
                dcval_next <= "101011"; --set dc to 43(~70%)
            when 32 =>     --if temperature is 32 degrees
                dcval_next <= "110001"; --set dc to 49(~80%)
            when 34 =>     --if temperature is 34 degrees
                dcval_next <= "110111"; --set dc to 55(~90%)
            when others =>
               if deg < 26 then
                   dcval_next <= "000000"; --below 26 degrees the fan is off
               elsif deg > 34 then
                   dcval_next <= "111111"; --above 34 degrees the fan is at full speed
               end if;
        end case;
end process setdc_proc;

pwm_fan <= pwm_out; --invert the output due to the motor circuit inverting character, otherwise the motor is at full speed when pwm is off
pwm_led <= pwm_out; --control led for pwm output

--This counter holds the UART state machine in reset for ~2 milliseconds. This
--will complete transmission of any byte that may have been initiated during 
--FPGA configuration due to the UART_TX line being pulled low, preventing a 
--frame shift error from occuring during the first message.
process(CLK100MHZ)
begin
    if (rising_edge(CLK100MHZ)) then
        if ((reset_cntr = RESET_CNTR_MAX) or (uartState /= RST_REG)) then
            reset_cntr <= (others=>'0');
        else
            reset_cntr <= reset_cntr + 1;
        end if;
    end if;
end process;

--count time between log messages
process(CLK100MHZ)
begin
    if (rising_edge(CLK100MHZ)) then
        if ((log_cntr = LOG_CNTR_MAX))then
            log_cntr <= (others=>'0');
        else
            log_cntr <= log_cntr + 1;
        end if;
    end if;
end process;

--Next Uart state logic (states described above)
next_uartState_process : process (CLK100MHZ)
begin
	if (rising_edge(CLK100MHZ)) then
			
        case uartState is 
        when RST_REG =>
            if (reset_cntr = RESET_CNTR_MAX) then
                tx_en <= '0';
                uartState <= LD_TEMP_STR;
            end if;
        when LD_TEMP_STR =>
            if (log_cntr = LOG_CNTR_MAX) then
                strIndex <= 0;
                tx_en <= '0';
                sendStr <= TEMP_STR & ascii_temp_tens & ascii_temp_ones & X"2E" & ascii_temp_tenths & LUX_STR & ascii_bright_tens & ascii_bright_ones;
                strEnd <= SEND_STR_LEN;
                uartState <= SEND_CHAR;
            end if;
        when SEND_CHAR =>
            strIndex <= strIndex + 1;
            tx_en <= '1';
            tx_data <= sendStr(strIndex);
            uartState <= RDY_LOW;
        when RDY_LOW =>
            tx_en <= '0';
            uartState <= WAIT_RDY;
        when WAIT_RDY =>
            tx_en <= '0';
            if (tx_busy = '0') then
                if (strEnd = strIndex) then
                    uartState <= LD_TEMP_STR;
                else
                    uartState <= SEND_CHAR;
                end if;
            end if;
        when others=> --should never be reached
            uartState <= RST_REG;
        end case;
	end if;
end process;

tx <= tx_internal;

end Behavioral;

