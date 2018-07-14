library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin12tobcd_tb is
end bin12tobcd_tb;

architecture Behavioral of bin12tobcd_tb is

component bin12tobcd is
    port ( 
        bin12 : in std_logic_vector(11 downto 0);
        tenths : out std_logic_vector(3 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(3 downto 0);
        hundreds : out std_logic_vector(3 downto 0)
    );
end component bin12tobcd;

signal input_in_tenths : std_logic_vector(11 downto 0) := (others => '0');
signal tenths : std_logic_vector(3 downto 0);
signal ones : std_logic_vector(3 downto 0);
signal tens : std_logic_vector(3 downto 0);
signal hundreds : std_logic_vector(3 downto 0);

begin

    dut : bin12tobcd
    port map( 
        bin12 => input_in_tenths,
        tenths => tenths,
        ones => ones,
        tens => tens,
        hundreds => hundreds
    );

    process
    begin
    
        input_in_tenths <= "000000000001";  -- dec: 1
        wait for 50 ns;
        
        input_in_tenths <= "000000100101";  -- dec: 37
        wait for 50 ns;
        
        input_in_tenths <= "001110100011";  -- dec: 931
        wait for 50 ns;
        
        input_in_tenths <= "100110110011";  -- dec: 2483
        wait for 50 ns;
                
        input_in_tenths <= "010011011001";  -- dec: 1241
        wait for 50 ns;
                        
        input_in_tenths <= "111111111111";  -- dec: 1241
        wait;
            
    end process;

end Behavioral;
