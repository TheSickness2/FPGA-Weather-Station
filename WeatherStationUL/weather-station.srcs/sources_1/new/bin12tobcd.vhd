library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This takes a 12 bit binary number and codes it into 4 BCD digits
entity bin12tobcd is
    port ( 
        bin12 : in std_logic_vector(11 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(3 downto 0);
        hundreds : out std_logic_vector(3 downto 0);
        thousands : out std_logic_vector(3 downto 0)
    );
end bin12tobcd;

architecture impl of bin12tobcd is

constant bin_size : integer := 12;

begin

    process(bin12) is
    
    variable bin_buf : unsigned(bin_size-1 downto 0);
    variable ones_buf : unsigned(3 downto 0);
    variable tens_buf : unsigned(3 downto 0);
    variable hundreds_buf : unsigned(3 downto 0);
    variable thousands_buf : unsigned(3 downto 0);
    
    begin
    
        bin_buf := unsigned(bin12);
        ones_buf := "0000";
        tens_buf := "0000";
        hundreds_buf := "0000";
        thousands_buf := "0000";
        
        for idx in 1 to bin_size loop
            
            if ones_buf >= 5 then
                ones_buf := ones_buf + 3;
            end if;
            if tens_buf >= 5 then
                tens_buf := tens_buf + 3;
            end if;
            if hundreds_buf >= 5 then
                hundreds_buf := hundreds_buf + 3;
            end if;
            if thousands_buf >= 5 then
                thousands_buf := thousands_buf + 3;
            end if;
            
            
            thousands_buf := thousands_buf(2 downto 0) & hundreds_buf(3);
            hundreds_buf := hundreds_buf(2 downto 0) & tens_buf(3);
            tens_buf := tens_buf(2 downto 0) & ones_buf(3);
            ones_buf := ones_buf(2 downto 0) & bin_buf(bin_size - idx);
            
        end loop;
        
        ones <= std_logic_vector(ones_buf);
        tens <= std_logic_vector(tens_buf);
        hundreds <= std_logic_vector(hundreds_buf);
        thousands <= std_logic_vector(thousands_buf);
    
    end process;

end impl;
