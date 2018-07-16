library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity temp_conversion is
    port(
        adc_tempval : in std_logic_vector(11 downto 0);
        temp_celsius : out std_logic_vector(5 downto 0);
        temp_tenths_celsius : out std_logic_vector(11 downto 0);
        ascii_temp_tenths : out std_logic_vector(7 downto 0);
        ascii_temp_ones : out std_logic_vector(7 downto 0);
        ascii_temp_tens : out std_logic_vector(7 downto 0);
        ascii_temp_hundreds : out std_logic_vector(7 downto 0)
    );
end temp_conversion;

architecture Behavioral of temp_conversion is

component bin12tobcd is
    port ( 
        bin12 : in std_logic_vector(11 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(3 downto 0);
        hundreds : out std_logic_vector(3 downto 0);
        thousands : out std_logic_vector(3 downto 0)
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
    ones => tenths_internal,
    tens => ones_internal,
    hundreds => tens_internal,
    thousands => hundreds_internal
);

temp_celsius_internal <= temp_tenths_celsius_internal / 10;     -- yes, there is loss, we take this into account
temp_tenths_celsius_internal <= (unsigned(adc_tempval) * 3) - 2475;    -- conversion formula

temp_celsius <= std_logic_vector(temp_celsius_internal(5 downto 0));  -- cut upper bits because we won't get our temperature there anyway
temp_tenths_celsius <= std_logic_vector(temp_tenths_celsius_internal(11 downto 0));

ascii_temp_tenths <= (X"3" & tenths_internal);
ascii_temp_ones <= (X"3" & ones_internal);
ascii_temp_tens <= (X"3" & tens_internal);
ascii_temp_hundreds <= (X"3" & hundreds_internal);

end Behavioral;
