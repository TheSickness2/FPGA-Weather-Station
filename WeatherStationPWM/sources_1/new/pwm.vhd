library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm is
    port ( 
        clk : in std_logic;
        dc : in std_logic_vector(15 downto 0);   --define duty cycle
        pwm : out std_logic
    );
end pwm;

architecture impl of pwm is
    signal pwm_reg : std_logic := '0';
    signal pwm_next : std_logic;
    
    signal cntr_reg : unsigned(16 downto 0) := "00000000000000000";   
    signal cntr_next : unsigned(16 downto 0);
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            pwm_reg <= pwm_next;
            cntr_reg <= cntr_next;
        end if;    
    end process;
    
    cntr_next <= cntr_reg +1;
    --pwm_next <= '1' when ((cntr_reg(7) = '0') and (cntr_reg(6 downto 1) < unsigned(dc))) else '0'; --duty cycle = 50%, half of counter reg 
    pwm_next <= '1' when (cntr_reg(16 downto 1) < unsigned(dc)) else '0';
    pwm <= not pwm_reg;

end impl;
