library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity temp_conversion is
    port(
        adc_tempval : in std_logic_vector(11 downto 0);
        temp_celsius : out std_logic_vector(5 downto 0);
        temp_tenths_celsius : out std_logic_vector(11 downto 0);
        temp_tenths : out std_logic_vector(3 downto 0);
        temp_ones : out std_logic_vector(3 downto 0);
        temp_tens : out std_logic_vector(3 downto 0);
        temp_hundreds : out std_logic_vector(3 downto 0)
    );
end temp_conversion;

architecture Behavioral of temp_conversion is

component bin12tobcd is
    port ( 
        bin12 : in std_logic_vector(11 downto 0);
        tenths : out std_logic_vector(3 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(3 downto 0);
        hundreds : out std_logic_vector(3 downto 0)
    );
end component;

signal temp_celsius_internal : unsigned(23 downto 0);
signal temp_tenths_celsius_internal : unsigned(23 downto 0);

signal tenths_internal : std_logic_vector(3 downto 0);
signal ones_internal : std_logic_vector(3 downto 0);
signal tens_internal : std_logic_vector(3 downto 0);
signal hundreds_internal : std_logic_vector(3 downto 0);

begin

temptobcd : bin12tobcd
port map(
    bin12 => std_logic_vector(temp_tenths_celsius_internal(11 downto 0)),
    tenths => tenths_internal,
    ones => ones_internal,
    tens => tens_internal,
    hundreds => hundreds_internal
);

temp_celsius_internal <= temp_tenths_celsius_internal / 10; -- yes, there is loss, we take this into account
temp_tenths_celsius_internal <= ((unsigned(adc_tempval(11 downto 0)) * 4) / 5) - 490;   -- adc_tempval x 4/5 (minus 490 to compensate difference to -50 centigrades and error)

temp_celsius <= std_logic_vector(temp_celsius_internal(5 downto 0));  -- cut upper bits because we won't get our temperature there anyway
temp_tenths_celsius <= std_logic_vector(temp_tenths_celsius_internal(11 downto 0));

temp_tenths <= tenths_internal;
temp_ones <= ones_internal;
temp_tens <= tens_internal;
temp_hundreds <= hundreds_internal;

end Behavioral;
