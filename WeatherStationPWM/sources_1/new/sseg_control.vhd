library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sseg_control is
    port (
        clk : in std_logic;
        disp_data : in std_logic_vector(15 downto 0); --4 digits: (31 downto 0);
        seg_data : out std_logic_vector(7 downto 0);
        digit_sel : out std_logic_vector(1 downto 0) --4 digits: (3 downto 0);
    );   
end sseg_control;

architecture impl of sseg_control is
signal cntr_reg : unsigned(19 downto 0);
signal cntr_next : unsigned(19 downto 0);

signal digit_addr : unsigned(1 downto 0);

signal seg_data_reg : std_logic_vector(7 downto 0);
signal seg_data_next : std_logic_vector(7 downto 0);

signal digit_sel_reg : std_logic_vector(1 downto 0);--2 digit
signal digit_sel_next : std_logic_vector(1 downto 0);--2 digit
--signal digit_sel_reg : std_logic_vector(3 downto 0);--4digit
--signal digit_sel_next : std_logic_vector(3 downto 0);--4digit

begin
    process(clk)
    begin
        if rising_edge(clk) then 
            cntr_reg <= cntr_next;
            seg_data_reg <= seg_data_next;
            digit_sel_reg <= digit_sel_next;
        end if;
    end process;
    
    cntr_next <= cntr_reg +1;
    digit_addr <= cntr_reg(19 downto 18);
    
    with digit_addr select --digit selection
        digit_sel_next <=
            --2 digits:
            "01" when "00",
            "01" when "01",
            "10" when "10",
            "10" when "11";
            --4 digits:
            --"0001" when "00",
            --"0010" when "01",
            --"0100" when "10",
            --"1000" when others;
            
     with digit_addr select -- segment data selection
       seg_data_next <=
            --2 digits:
            disp_data(7 downto 0) when "00",
            disp_data(7 downto 0) when "01",
            disp_data(15 downto 8) when "10",
            disp_data(15 downto 8) when "11";
            --4 digits:
            --disp_data(7 downto 0) when "00",
            --disp_data(15 downto 8) when "01",
            --disp_data(23 downto 16) when "10",
            --disp_data(31 downto 24) when others;
            
      seg_data <= seg_data_reg;
      digit_sel <= digit_sel_reg;
    
end impl;
