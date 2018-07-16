library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity light_conversion is
    port(
        adc_lightval : in std_logic_vector(11 downto 0);
        brightness : out std_logic_vector(5 downto 0);
        ascii_light_ones : out std_logic_vector(7 downto 0);
        ascii_light_tens : out std_logic_vector(7 downto 0)
    );
end light_conversion;

architecture Behavioral of light_conversion is

component bin6tobcd is
    port ( 
        bin6 : in std_logic_vector(5 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(2 downto 0)
    );
end component;

signal brightness_internal : unsigned(11 downto 0);

signal ones_internal : std_logic_vector(3 downto 0);
signal tens_internal : std_logic_vector(2 downto 0);

begin

lighttobcd : bin6tobcd
port map(
    bin6 => std_logic_vector(brightness_internal(11 downto 6)),
    ones => ones_internal,
    tens => tens_internal
);

brightness_internal <= unsigned(adc_lightval);  -- TODO: range conversion!
brightness <= std_logic_vector(brightness_internal(11 downto 6));

ascii_light_ones <= (X"3" & ones_internal);
ascii_light_tens <= (X"3" & ("0" & tens_internal));

end Behavioral;
