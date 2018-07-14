----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.07.2018 22:48:01
-- Design Name: main module
-- Module Name: pwm_vardisp3_arty - impl
-- Project Name: WeatherStation
-- Target Devices: arty s7 50
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_vardisp3_arty is
    port ( 
        clk100mhz : in std_logic;
        btn : in std_logic_vector(1 downto 0);
        led_out : out std_logic;
        fan_out : out std_logic;
        seg : out std_logic_vector(6 downto 0);
        cat : out std_logic
    );
end pwm_vardisp3_arty;

architecture impl of pwm_vardisp3_arty is
component pwm is
    port(
        clk : in std_logic;
        dc : in std_logic_vector(15 downto 0);
        pwm : out std_logic
    );
end component;

component sseg_arty_2dig is 
    port(
        clk100 : in std_logic;
        binval : in std_logic_vector(5 downto 0);
        seg : out std_logic_vector(6 downto 0);
        cat : out std_logic
    );
end component;

component debouncer is
    generic(
        num_cons_cycles : integer := 2000;
        cntr_size : integer := 11    
    );
    port(
        clk : in std_logic;
        data_in : in std_logic;
        data_deb : out std_logic
    );
 end component;

type dc_state_type is (idle, inc, dec);
signal dc_state_reg : dc_state_type := idle;
signal dc_state_next : dc_state_type;

type ta_state_type is (released, pressed, pulse);
signal ta_plus_state_reg : ta_state_type := released;
signal ta_plus_state_next : ta_state_type;

signal ta_minus_state_reg : ta_state_type := released;
signal ta_minus_state_next : ta_state_type;


signal ta_plus_pulse : std_logic := '0';
signal ta_minus_pulse : std_logic := '0';


signal dcval_reg : unsigned(15 downto 0):= (others => '0');
signal dcval_next : unsigned(15 downto 0);


signal ta_plus : std_logic;
signal ta_minus : std_logic;

signal btn1_deb : std_logic; --debouced data from debouncer 1
signal btn2_deb : std_logic; --debounced data from debouncer2

begin
 pwm0 : pwm
 port map(
    clk => clk100mhz,
    dc => std_logic_vector(dcval_reg),
    pwm => fan_out
 );
 
 pwm1 : pwm
 port map(
    clk => clk100mhz,
    dc => std_logic_vector(dcval_reg),
    pwm => led_out
 );
 
 disp : sseg_arty_2dig
 port map(
    clk100 => clk100mhz,
    binval => std_logic_vector(dcval_reg(15 downto 10)),
    seg => seg,
    cat => cat
 );
 
 --debouncing module 1
 deb1 : debouncer
 generic map(
    num_cons_cycles => 2000,
    cntr_size => 11
 )
 port map(
    clk => clk100mhz,
    data_in => btn(0),
    data_deb => btn1_deb
 );
 
 --debouncing module 2
 deb2 : debouncer
 generic map(
    num_cons_cycles => 2000,
    cntr_size => 11
 )
 port map(
    clk => clk100mhz,
    data_in => btn(1),
    data_deb => btn2_deb
 );
 
 --led(0) <= '1'; --set led0 constantly on (compare led for pwm)
 
 upd_proc : process(clk100mhz) --update process
 begin
    if rising_edge(clk100mhz) then
        dc_state_reg <= dc_state_next;
        ta_plus_state_reg <= ta_plus_state_next;
        ta_minus_state_reg <= ta_minus_state_next;
        dcval_reg <= dcval_next;
    end if;
 end process upd_proc; --update process
 
 
 
 state_proc : process(dc_state_reg, dcval_reg, ta_plus_pulse, ta_minus_pulse) --state machine process
 begin
    dc_state_next <= dc_state_reg; -- default, no change
    dcval_next <= dcval_reg; -- default, no change
    case dc_state_reg is
        when idle =>
            if ta_plus_pulse = '1' then
                dc_state_next <= inc;
            elsif ta_minus_pulse = '1' then
                dc_state_next <= dec;
            end if;
        when inc =>
            dcval_next <= dcval_reg +6553;
            dc_state_next <= idle;
        when dec =>
            dcval_next <= dcval_reg -6553;
            dc_state_next <= idle;
    end case;
 end process state_proc; --state machine process
     
 
 ta_plus_proc : process(ta_plus_state_reg, ta_plus) --press plus event process
 begin
    ta_plus_state_next <= ta_plus_state_reg; --default
    ta_plus_pulse <= '0'; -- default
    case ta_plus_state_reg is 
        when released =>
            if ta_plus = '1' then
                ta_plus_state_next <= pressed;
            end if;
        when pressed =>
            if ta_plus = '0' then
                ta_plus_state_next <= pulse;
            end if;
        when pulse =>
            ta_plus_pulse <= '1';
            ta_plus_state_next <= released;
    end case;
 end process; --press plus event process
 
 ta_minus_proc : process(ta_minus_state_reg, ta_minus) --press minus event process
 begin
    ta_minus_state_next <= ta_minus_state_reg; --default
    ta_minus_pulse <= '0'; --default
    case ta_minus_state_reg is
        when released =>
            if ta_minus = '1' then
                ta_minus_state_next <= pressed;
            end if;
        when pressed => 
            if ta_minus = '0' then
                ta_minus_state_next <= pulse;
            end if;
        when pulse =>
            ta_minus_pulse <= '1';
            ta_minus_state_next <= released;
    end case;                
 end process; --press minus event process
 
 --shift debounced button clicks to operation registers    
 ta_plus <= btn1_deb; 
 ta_minus <= btn2_deb;
 
end impl;
