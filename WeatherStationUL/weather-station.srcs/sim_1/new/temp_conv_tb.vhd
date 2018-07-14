library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity temp_conv_tb is
end temp_conv_tb;

architecture Behavioral of temp_conv_tb is

component temp_conversion is
    port(
        adc_tempval : in std_logic_vector(11 downto 0);
        temp_celsius : out std_logic_vector(5 downto 0);
        temp_tenths_celsius : out std_logic_vector(11 downto 0);
        temp_tenths : out std_logic_vector(3 downto 0);
        temp_ones : out std_logic_vector(3 downto 0);
        temp_tens : out std_logic_vector(3 downto 0);
        temp_hundreds : out std_logic_vector(3 downto 0)
    );
end component temp_conversion;

signal adc_tempval : std_logic_vector(11 downto 0) := (others => '0');
signal temp_celsius : std_logic_vector(5 downto 0);
signal temp_tenths_celsius : std_logic_vector(11 downto 0);
signal temp_tenths : std_logic_vector(3 downto 0);
signal temp_ones : std_logic_vector(3 downto 0);
signal temp_tens : std_logic_vector(3 downto 0);
signal temp_hundreds : std_logic_vector(3 downto 0);

begin

    dut : temp_conversion
    port map(
        adc_tempval => adc_tempval,
        temp_celsius => temp_celsius,
        temp_tenths_celsius => temp_tenths_celsius,
        temp_tenths => temp_tenths,
        temp_ones => temp_ones,
        temp_tens => temp_tens,
        temp_hundreds => temp_hundreds
    );


    process
    begin
    
        adc_tempval <= "001111101000";  -- dec: 1000, centigrade: +30,5
        wait for 50 ns;
        
        adc_tempval <= "001110100011";  -- dec: 931, centigrade: +25
        wait for 50 ns;
        
        adc_tempval <= "100110110011";  -- dec: 2483, centigrade: +150
        wait for 50 ns;
                
        adc_tempval <= "010011011001";  -- dec: 1241, centigrade: +50
        wait;
            
    end process;

end Behavioral;
