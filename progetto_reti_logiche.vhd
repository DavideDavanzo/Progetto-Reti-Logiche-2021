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
    
    component datapath is
        port(
            -- segnali del datapath
        );
    end component;
    
    type S is (RESET_STATE, S1, S2, S3, S4, S5, S6, S7, S8, 
               S9, S10, S11, S12, S13);
    
    signal current_state: S; -- stato corrente
    signal next_state: S; -- stato successivo
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
    
    DATAPATH0: datapath port map(     -- mappa i segnali con i nomi originali
        -- segnali del datapath
    );

    process(i_clk, i_res)
    begin
        if(i_res = '1') then
            current_state <= RESET_STATE;
        elsif rising_edge(i_clk) then       -- commuta sul fronte di salita
            current_state <= next_state;
        end if;
    end process;

    process(current_state, i_start, o_done)
    begin
        next_state <= current_state;
        case current_state is
            when RESET_STATE =>
                if i_start = '1' then
                    next_state <= S1;
                end if;
            when S1 =>
                next_state <= S2;
            when S2 =>
                next_state <= S3;
            when S3 =>
                next_state <= S4;
            when S4 =>                  -- inizio scansione per trovare MIN e MAX
                if o_zero = '1' then    -- caso DIM=1
                    next_state <= S6;
                else                    -- caso DIM>1
                    next_state <= S5;
                end if;
            when S5 =>
                if o_zero = '1' then    -- fine scansione
                    next_state <= S6;
                else                    -- scansione ancora in corso
                    next_state <= S5;
                end if;
            when S6 =>                  -- scansione completata, MAX e MIN trovati, calcolo DELTA
                next_state <= S7;
            when S7 =>
                next_state <= S8;
            when S8 =>
                next_state <= S9;
            when S9 =>
                next_state <= S9;
            when S10 =>
                next_state <= S11;
            when S11 =>
                if o_zero = '1' then    -- computazione e scrittura completata per ogni pixel
                    next_state <= S12;
                else                    -- passa al pixel successivo
                    next_state <= S8;
                end if;
            when S12 =>
                if i_start = '0' then
                    next_state <= S13;
                end if;
            when S13 =>                 -- stato finale in attesa di nuovo start
                if i_start = '1' then
                    next_state <= S1;   -- non torna in RESET_STATE perchè il PC non deve essere resettato all'indirizzo 0
        end case;
    end process;
            
    process(current_state)      -- gestisce i segnali degli stati della fsm
            begin
    end process;
                
end Behavioral;
