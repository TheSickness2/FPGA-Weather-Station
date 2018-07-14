library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity bin6tobcd is
    port ( 
        bin6 : in std_logic_vector(5 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(2 downto 0)
    );
end bin6tobcd;

architecture impl of bin6tobcd is

constant bin_size : integer := 6;

begin
    process(bin6) is
    variable bin_buf : unsigned(bin_size-1 downto 0);
    variable ones_buf : unsigned(3 downto 0);
    variable tens_buf : unsigned(2 downto 0);
    begin
        bin_buf := unsigned(bin6);
        ones_buf := "0000";
        tens_buf := "000";
        
        for idx in 1 to bin_size loop
            if ones_buf >= 5 then
                ones_buf := ones_buf +3;
            end if;
            tens_buf := tens_buf(1 downto 0) & ones_buf(3);
            ones_buf := ones_buf(2 downto 0) & bin_buf(bin_size - idx);
       end loop;
       ones <= std_logic_vector(ones_buf);
       tens <= std_logic_vector(tens_buf);
    end process;

end impl;
