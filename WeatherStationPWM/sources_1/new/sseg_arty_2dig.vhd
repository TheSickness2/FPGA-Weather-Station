library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity sseg_arty_2dig is
    port (
        --CLK100MHZ : in std_logic;
        clk100 : in std_logic;
        binval : in std_logic_vector(5 downto 0);
        --sw : in std_logic_vector(3 downto 0);
        --btn : in std_logic_vector(1 downto 0);
        seg : out std_logic_vector(6 downto 0);
        cat : out std_logic
    );
end sseg_arty_2dig;

architecture impl of sseg_arty_2dig is
component sseg_control is
    port(
        clk : in std_logic;
        disp_data : in std_logic_vector(15 downto 0); --4 digits: (31 downto 0);
        seg_data : out std_logic_vector(7 downto 0);
        digit_sel : out std_logic_vector(1 downto 0) --4 digits: (3 downto 0);
    );
end component;

component bin6tobcd is
    port(
        bin6 : in std_logic_vector(5 downto 0);
        ones : out std_logic_vector(3 downto 0);
        tens : out std_logic_vector(2 downto 0)
    );
end component;

component hex2sseg is
    port(
        hexnum : in std_logic_vector(3 downto 0);
        decpoint : in std_logic;
        sevseg : out std_logic_vector(7 downto 0) -- dp: bit 7; g: bit 6 ; ... a : bit 0
    );
end component;

signal disp_buf : std_logic_vector(15 downto 0);
signal seg_buf : std_logic_vector(7 downto 0);

signal digit_sel_buf : std_logic_vector(1 downto 0); -- 4 digits: (3 downto 0);

signal digit0_data : std_logic_vector(3 downto 0);
signal digit1_data : std_logic_vector(3 downto 0);

begin
    sseg_cntrl : sseg_control
    port map(
        clk => clk100,
        disp_data(15 downto 0) => disp_buf,
        --4 digits: 
        --disp_data(31 downto 16) => (others => '0');
        seg_data => seg_buf,
        digit_sel => digit_sel_buf        
    );
    
    bintobcd0 : bin6tobcd
    port map(
        bin6 => binval,
        --bin6(5 downto 2) => sw,
        --bin6(1 downto 0) => btn,
        ones => digit0_data,
        tens => digit1_data(2 downto 0)
    );

    hex2sseg_00 : hex2sseg
    port map(
        hexnum => digit0_data,
        decpoint => '0',
        sevseg => disp_buf(7 downto 0)
    );
    
     hex2sseg_01 : hex2sseg
     port map(
         hexnum => digit1_data,
         decpoint => '0',
         sevseg => disp_buf(15 downto 8)
     );
     
     digit1_data(3) <= '0';
     
     seg <= seg_buf(6 downto 0);
     cat <= not digit_sel_buf(0);

end impl;
