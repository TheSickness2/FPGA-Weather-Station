library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity uart_rxtx_tb is
end uart_rxtx_tb;

architecture Behavioral of uart_rxtx_tb is

    component uart_rxtx is
        generic(
            clk_freq    : integer     := 100_000_000;   -- frequency of system clock in Hertz
            baud_rate   : integer     := 9_600;         -- data link baud rate in bits/second
            os_rate		: integer     := 16;            -- oversampling rate (in samples per baud period)
            d_width		: integer     := 8;             -- data bus width
            stop_bits   : integer     := 1;             -- number of stop bits
            use_parity	: integer     := 0;             -- 0 for no parity, 1 for parity
            parity_eo	: std_logic   := '0');          -- '0' for even, '1' for odd parity
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
            rx_data  : out std_logic_vector(d_width-1 downto 0));   -- data received
    end component uart_rxtx;
    
    
    constant CLK_RATE   : integer := 10_000_000;
    
    -- test bench uses a 10 MHz clock
    -- UART is configured with 100000 baud
    -- 10000000 / 100000 = 100 cycles per bit
    constant BIT_PERIOD : time := 10000 ns;
    
    -- configuration
    constant BAUD_RATE  : integer   := 100_000;
    constant OS_RATE    : integer   := 10;
    constant D_WIDTH    : integer   := 8;
    constant STOP_BITS  : integer   := 1;
    constant PARITY     : integer   := 0;
    constant PARITY_EO  : std_logic := '0';
    
    
    signal test_clk     : std_logic                     := '0';
    signal test_reset_n : std_logic                     := '1';
    
    signal test_tx_en   : std_logic                     := '0';
    signal test_tx_busy : std_logic                     := '0';
    signal test_tx_data : std_logic_vector(7 downto 0)  := (others => '0');
    signal test_tx      : std_logic                     := '1';
    
    signal test_rx      : std_logic                     := '1';
    signal test_rx_done : std_logic                     := '0';
    signal test_rx_data : std_logic_vector(7 downto 0)  := (others => '0');
    signal test_rx_err  : std_logic                     := '0';
   
    
    -- Low-level byte-write for testing RX
    procedure UART_WRITE_BYTE(
        data_in             : in  std_logic_vector(D_WIDTH-1 downto 0);
        signal serial_out   : out std_logic) is
    begin
    
        -- Send Start Bit
        serial_out <= '0';
        wait for BIT_PERIOD;
        
        -- Send Data Byte
        for ii in 0 to D_WIDTH-1 loop
            serial_out <= data_in(ii);
            wait for BIT_PERIOD;
        end loop;
        
        -- Send Stop Bits
        for jj in 0 to STOP_BITS-1 loop
            serial_out <= '1';
            wait for BIT_PERIOD;
        end loop;
        
    end UART_WRITE_BYTE;

begin

    dut : uart_rxtx
        generic map(
            clk_freq    => CLK_RATE,  -- 10 MHz
            baud_rate   => BAUD_RATE,
            os_rate		=> OS_RATE,
            d_width		=> D_WIDTH,
            stop_bits   => STOP_BITS,
            use_parity	=> PARITY,
            parity_eo	=> PARITY_EO)
        port map(
            clk      => test_clk,
            reset_n  => test_reset_n,
            tx_en    => test_tx_en,
            tx_data  => test_tx_data,
            rx		 => test_rx,
            tx       => test_tx,
            tx_busy  => test_tx_busy,
            rx_done  => test_rx_done,
            rx_error => test_rx_err,
            rx_data  => test_rx_data);        
        
    test_clk <= not test_clk after 50 ns;   -- 10 MHz
            
    process is
    begin
    
        -- Tell the UART to send a command
        wait until rising_edge(test_clk);
        test_tx_en <= '1';
        test_tx_data <= X"53";
        wait until rising_edge(test_clk);
        test_tx_en <= '0';
        wait until test_tx_busy = '0';
        -- repeat
        test_tx_en <= '1';
        test_tx_data <= X"AC";
        wait until rising_edge(test_clk);
        test_tx_en <= '0';
        wait until test_tx_busy = '0';
        
        
        -- Send a command to the UART
        wait until rising_edge(test_clk);
        UART_WRITE_BYTE(X"3F", test_rx);
        wait until test_rx_done = '1';

        -- Check that the correct command was received
        if test_rx_data = X"3F" then
            report "Test Passed - Correct Byte Received" severity note;
        else
            report "Test Failed - Incorrect Byte Received" severity note;
        end if;
        
        
        assert false report "Tests Complete" severity failure;
    
    end process;

end Behavioral;
