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
        led : out std_logic_vector(1 downto 0);
        seg : out std_logic_vector(6 downto 0);
        cat : out std_logic
    );
end pwm_vardisp3_arty;

architecture impl of pwm_vardisp3_arty is
component pwm is
    port(
        clk : in std_logic;
        dc : in std_logic_vector(5 downto 0);
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


signal dcval_reg : unsigned(5 downto 0):= (others => '0');
signal dcval_next : unsigned(5 downto 0);


signal ta_plus : std_logic;
signal ta_minus : std_logic;


begin
 pwm0 : pwm
 port map(
    clk => clk100mhz,
    dc => std_logic_vector(dcval_reg),
    pwm => led(1)
 );
 
 disp : sseg_arty_2dig
 port map(
    clk100 => clk100mhz,
    binval => std_logic_vector(dcval_reg),
    seg => seg,
    cat => cat
 );
 
 led(0) <= '1';
 
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
            dcval_next <= dcval_reg +1;
            dc_state_next <= idle;
        when dec =>
            dcval_next <= dcval_reg -1;
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
     
 ta_plus <= btn(0);
 ta_minus <= btn(1);

end impl;
