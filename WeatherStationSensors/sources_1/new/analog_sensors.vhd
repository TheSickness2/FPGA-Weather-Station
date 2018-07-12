----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.07.2018 22:25:12
-- Design Name: 
-- Module Name: analog_sensors - Behavioral
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

entity analog_sensors is
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        vp : IN STD_LOGIC;
        vn : IN STD_LOGIC;
        vauxp0 : IN STD_LOGIC;
        vauxn0 : IN STD_LOGIC;
        vauxp1 : IN STD_LOGIC;
        vauxn1 : IN STD_LOGIC;
        pin_select : IN STD_LOGIC;
        
        led : BUFFER STD_LOGIC_VECTOR(5 DOWNTO 0)
      );
end analog_sensors;

architecture Behavioral of analog_sensors is

COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);       -- Input data bus for the dynamic reconfiguration port
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);     -- Address bus for the dynamic reconfiguration port
    den_in : IN STD_LOGIC;                          -- Enable Signal for the dynamic reconfiguration port
    dwe_in : IN STD_LOGIC;                          -- Write Enable for the dynamic reconfiguration port
    drdy_out : OUT STD_LOGIC;                       -- Data ready signal for the dynamic reconfiguration port
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);     -- Output data bus for dynamic reconfiguration port
    dclk_in : IN STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
    reset_in : IN STD_LOGIC;                        -- Reset signal for the System Monitor control logic
    vp_in : IN STD_LOGIC;                           -- Dedicated Analog Input Pair
    vn_in : IN STD_LOGIC;
    vauxp0 : IN STD_LOGIC;                          -- Auxiliary Channel 0
    vauxn0 : IN STD_LOGIC;
    vauxp1 : IN STD_LOGIC;                          -- Auxiliary Channel 1
    vauxn1 : IN STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0); -- Channel Selection Outputs
    eoc_out : OUT STD_LOGIC;                        -- End of Conversion Signal
    alarm_out : OUT STD_LOGIC;                      -- OR'ed output of all the Alarms
    eos_out : OUT STD_LOGIC;                        -- End of Sequence Signal
    busy_out : OUT STD_LOGIC                        -- ADC Busy signal
  );
END COMPONENT;

SIGNAL enable : STD_LOGIC;
SIGNAL ready : STD_LOGIC;
SIGNAL ready_d1 : STD_LOGIC;
SIGNAL ready_rising : STD_LOGIC;
SIGNAL ready_falling : STD_LOGIC;
SIGNAL data : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL address_in : STD_LOGIC_VECTOR(6 DOWNTO 0);

CONSTANT a0_address : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000";
CONSTANT a1_address : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010001";

begin

my_xadc : xadc_wiz_0
  PORT MAP (
    di_in => (others => '0'),
    daddr_in => address_in,
    den_in => enable,
    dwe_in => '0',
    drdy_out => ready,
    do_out => data,
    dclk_in => CLK100MHZ,
    reset_in => '0',
    vp_in => vp,
    vn_in => vn,
    vauxp0 => vauxp0,
    vauxn0 => vauxn0,
    vauxp1 => vauxp1,
    vauxn1 => vauxn1,
    channel_out => open,
    eoc_out => enable,
    alarm_out => open,
    eos_out => open,
    busy_out => open
  );
  
LD_RDY : process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        ready_d1 <= ready;
    end if;
end process LD_RDY;

ready_rising <= '1' when ((ready = '1') AND (ready_d1 = '0')) else '0';
ready_falling <= '1' when ((ready = '0') AND (ready_d1 = '1')) else '0';

RD_DATA : process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        if ready_rising = '1' then
        
            if pin_select = '0' then    -- if we read a photocell, use only the upper bits
                case data(15 DOWNTO 13) is
                when "010" =>
                    led <= "000001";
                when "011" =>
                    led <= "000011";
                when "100" =>
                    led <= "000111";
                when "101" =>
                    led <= "001111";
                when "110" =>
                    led <= "011111";
                when "111" =>
                    led <= "111111";
                when others =>
                    led <= "000000"; 
                end case;
            else                        -- if we read a temperature sensor, use lower bits due to lower deviation
                case data(12 DOWNTO 10) is
                when "010" =>
                    led <= "000001";
                when "011" =>
                    led <= "000011";
                when "100" =>
                    led <= "000111";
                when "101" =>
                    led <= "001111";
                when "110" =>
                    led <= "011111";
                when "111" =>
                    led <= "111111";
                when others =>
                    led <= "000000"; 
                end case;
            end if;
        else
            led <= led;
        end if;
    end if;
end process RD_DATA;

LD_ADDR : process(CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        if ready_rising = '1' then
            if pin_select = '0' then
                address_in <= a0_address;
            else
                address_in <= a1_address;
            end if;
        else
            address_in <= address_in;
        end if;
    end if;
end process LD_ADDR;

end Behavioral;
