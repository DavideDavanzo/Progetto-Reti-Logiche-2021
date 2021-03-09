----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2021 19:35:28
-- Design Name: 
-- Module Name: progetto_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package constants is
    constant sixteen_bit_zero: std_logic_vector := "0000000000000000";
    constant eight_bit_zero: std_logic_vector := "00000000";
end constants;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.constants.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity progetto_reti_logiche is
    port ( 
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end progetto_reti_logiche;

architecture Behavioral of progetto_reti_logiche is
    
    type S is (reset_state, S1, S2, S3, S4, S5, S6, S7, S8, 
               S9, S10, S11, S12, S13);
    
    signal current_state: S; -- stato corrente
    signal program_counter: std_logic_vector(15 downto 0); -- indirizzo attuale
    signal dimension: std_logic_vector(15 downto 0); -- dimensione
    signal max: std_logic_vector(7 downto 0); -- massimo
    signal min: std_logic_vector(7 downto 0); -- minimo
    signal pixel_counter: std_logic_vector(15 downto 0); -- contatore dimensione
    signal delta_value: std_logic_vector(7 downto 0); -- max - min
    signal shift_value: std_logic_vector(3 downto 0); -- shift
    signal temp_value:  std_logic_vector(15 downto 0); -- valore temporaneo a confronto con 255
    signal new_value: std_logic_vector(8 downto 0); -- nuovo valore del pixel

begin

    UNIQUE_PROCESS: process(i_clk)
    begin
        if rising_edge(i_clk) then
        
            if (i_rst = '1') then
                current_state <= reset_state;
                
            else
                case current_state is
                
                when reset_state =>
                    -- outputs a 0
                    o_done <= '0';
                    o_en <= '0';
                    o_we <= '0';
                    o_data <= eight_bit_zero;
                    -- stato
                    current_state <= reset_state;
                    -- indirizzi a 0
                    o_address <= sixteen_bit_zero;
                    program_counter <= sixteen_bit_zero;
                    -- variabili a 0
                    dimension <= sixteen_bit_zero;
                    pixel_counter <= sixteen_bit_zero;
                    max <= eight_bit_zero;
                    min <= eight_bit_zero;
                    delta_value <= eight_bit_zero;
                    shift_value <= "0000";
                    temp_value <= sixteen_bit_zero;
                    new_value <= eight_bit_zero;
                    
                    if (i_start = '1') then
                        o_en <= '1'; -- alzo segnale enable
                        current_state <= S1;
                    end if;
                
                when S1 => 
                --roba che accade in S1 
                
                
                                   
                end case;
                
            end if;
                
        end if;
                           
    end process;
    
end Behavioral;
