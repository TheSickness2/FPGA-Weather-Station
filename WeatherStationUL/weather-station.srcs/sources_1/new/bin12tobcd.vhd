library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This takes a 12 bit binary number and codes it into 4 BCD digits, the lowest one representing tenths
entity bin12tobcd is
    port ( 
        bin12 : in std_logic_vector(11 downto 0);
        tenths : out std_logic_vector(3 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(3 downto 0);
        hundreds : out std_logic_vector(3 downto 0)
    );
end bin12tobcd;

architecture impl of bin12tobcd is

constant bin_size : integer := 12;

begin

    process(bin12) is
    
    variable bin_buf : unsigned(bin_size-1 downto 0);
    variable tenths_buf : unsigned(3 downto 0);
    variable ones_buf : unsigned(3 downto 0);
    variable tens_buf : unsigned(3 downto 0);
    variable hundreds_buf : unsigned(3 downto 0);
    
    begin
    
        bin_buf := unsigned(bin12);
        tenths_buf := "0000";
        ones_buf := "0000";
        tens_buf := "0000";
        hundreds_buf := "0000";
        
        for idx in 1 to bin_size loop
            
            if tenths_buf >= 5 then
                tenths_buf := tenths_buf + 3;
            end if;
            if ones_buf >= 5 then
                ones_buf := ones_buf + 3;
            end if;
            if tens_buf >= 5 then
                tens_buf := tens_buf + 3;
            end if;
            if hundreds_buf >= 5 then
                hundreds_buf := hundreds_buf + 3;
            end if;
            
            
            hundreds_buf := hundreds_buf(2 downto 0) & tens_buf(3);
            tens_buf := tens_buf(2 downto 0) & ones_buf(3);
            ones_buf := ones_buf(2 downto 0) & tenths_buf(3);
            tenths_buf := tenths_buf(2 downto 0) & bin_buf(bin_size - idx);
            
        end loop;
        
        tenths <= std_logic_vector(tenths_buf);
        ones <= std_logic_vector(ones_buf);
        tens <= std_logic_vector(tens_buf);
        hundreds <= std_logic_vector(hundreds_buf);
    
    end process;

end impl;
