library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hex2sseg is
    port ( 
        hexnum : in std_logic_vector(3 downto 0);
        decpoint : in std_logic;
        sevseg : out std_logic_vector(7 downto 0) -- dp
        --: bit 7; g: bit 6 ; ... a : bit 0
    );
end hex2sseg;

architecture impl of hex2sseg is

begin
    with hexnum select
        sevseg(6 downto 0) <=
        "0111111" when X"0",
        "0000110" when X"1",
        "1011011" when X"2",
        "1001111" when X"3",
        "1100110" when X"4",
        "1101101" when X"5",
        "1111101" when X"6",
        "0000111" when x"7",
        "1111111" when X"8",
        "1100111" when X"9",
        "1110111" when X"a",
        "1111100" when x"b",
        "0111001" when X"c",
        "1011110" when X"d",
        "1111001" when X"e",
        "1110001" when others; -- 'f'
        
        sevseg(7) <= decpoint;

end impl;
