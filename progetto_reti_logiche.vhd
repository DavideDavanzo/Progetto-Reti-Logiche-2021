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
    
    component dim_module is
        port (
            i_data: in std_logic_vector(7 downto 0); -- entra nel modulo
            mux_dim_sel: in std_logic; -- seleziona il secondo operando da moltiplicare
            dim_load: in std_logic; -- load del registro dim
            mux_cont_sel: in std_logic; -- decide cosa far passare prima del sottrattore
            cont_load: in std_logic; -- load del registro cont
            o_zero: out std_logic; -- =1 <==> il contatore raggiunge lo 0
            o_dim: out std_logic_vector(15 downto 0) -- valore attuale della dimensione
        );
    end component;
    
    component program_counter is
        port (
            i_dim: in std_logic_vector(15 downto 0); -- entra nel modulo
            mux_pc_sel: in std_logic; -- seleziona quale indirizzo inserire nel pc
            pc_load: in std_logic; -- load del registro pc
            mux_addr_sel: in std_logic; -- decide che indirizzo mandare in memoria
            pc_iniz_load: in std_logic; -- load del registro cont
            o_address: out std_logic_vector(15 downto 0) -- valore attuale della dimensione
        );
    end component;
    
    component min_max_module is
        port (
            i_data: in std_logic_vector(7 downto 0); -- entra nel modulo
            mux_compare_sel: in std_logic; -- seleziona quale numero confrontare
            max_load: in std_logic; -- load del registro max
            min_load: in std_logic; -- load del registro min
            o_min: out std_logic_vector(7 downto 0); -- valore min
            o_max: out std_logic_vector(7 downto 0) -- valore max
        );
    end component;
    
    component shift_level_module is
        generic (
                greater_127: std_logic;
                greater_63: std_logic;
                greater_31: std_logic;
                greater_15: std_logic;
                greater_7: std_logic;
                greater_3: std_logic;
                greater_1: std_logic;
                greater_0: std_logic
        );
        port (
            i_data: in std_logic_vector(7 downto 0); -- entra nel modulo
            delta_load: in std_logic; -- load del registro delta
            shift_lvl_load: in std_logic; -- load del registro shift_lvl
            o_shift_lvl: out std_logic_vector(3 downto 0) -- valore shift level
        );
    end component;
    
    component new_value_module is
        port (
            temp_load: in std_logic; -- load registro temp
            new_value_load: in std_logic; -- load registro new value
            i_data: in std_logic_vector(7 downto 0); -- entra nel modulo
            i_min: in std_logic_vector(7 downto 0); -- valore di min
            i_shift_lvl: in std_logic_vector(3 downto 0); -- valore shift level
            o_new_value: out std_logic_vector(7 downto 0) -- output new value
        );
    end component;
        
    component datapath is
        
    end component;
    
    type S is (RESET_STATE, S1, S2, S3, S4, S5, S6, S7, S8, 
               S9, S10, S11, S12, S13, S14);
    
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
                    next_state <= S7;
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
                next_state <= S10;
            when S10 =>
                next_state <= S11;
            when S11 =>
                if o_zero = '1' then    -- computazione e scrittura completata per ogni pixel
                    next_state <= S13;
                else                    -- passa al pixel successivo
                    next_state <= S12;
                end if;
            when S12 =>
                next_state <= S9;
            when S13 =>                 
                next_state <= S14;   
            when S14 =>              -- stato finale in attesa di nuovo start
                if start = '1' then
                    next_state <= S1    -- non torna in RESET_STATE perchè il PC non deve essere resettato all'indirizzo 0
                else
                    next_state <= S14;
                end if;
        end case;
    end process;
            
    process(current_state)      -- gestisce i segnali degli stati della fsm
            begin
                -- inizializzazione dei segnali
                pc_load <= '1';
                pc0_load <= '0';
                in_load <= '0';
                dim_load <= '0';
                cont_load <= '0';
                -- delta_load <= '0';   --  inutile
                sl_load <= '0';
                temp_load <= '0';
                nv_load <= '0';
                d_sel <= '00';
                mdim_sel <= '0';
                mcont_sel <= '0';
                minmax_sel <= '0';
                mpc_sel <= '00'
                en <= '0';
                we <= '0';
                o_done <= '0';
                
                case current_state is
                    when RESET_STATE =>     -- non cambio nulla, tutto è già stato inizializzato
                    when S1 =>              -- leggo da memoria il primo byte
                        en <= '1';
                        mpc_sel <= '01';
                        pc_load <= '1';
                        in_load <= '1';
                        dim_load <= '1';    -- DIM=1 temporaneamente
                    when S2 =>              -- leggo da memoria il secondo byte
                        mdim_sel <= '1';
                    when S3 =>              -- calcolo la dimensione, leggo il primo pixel di cui salvo l'indirizzo in PC0
                        pc0_load <= '1';
                        pc_load <= '0';
                    when S4 =>              -- indirizzo il primo byte letto nel modulo MIN/MAX e inizializzo il contatore
                        en <= '0';
                        in_load <= '0';
                        pc0_load <= '0';
                        pc_load <= '1';
                        cont_load <= '1';
                        d_sel <= '01';
                    when S5 =>              -- leggo e confronto i valori di tutti i pixel rimanenti
                        en <= '1';
                        in_load <= '1';
                        mm_sel <= '1';
                        mcont_sel <= '1';
                    when S6 =>              -- lascio che nel modulo MAX/MIN venga confrontato anche l'ultimo pixel
                        en <= '0';
                        in_load <= '0';
                        cont_load <= '0';
                    when S7 =>              -- carico nel PC l'indirizzo PC0 del primo pixel
                        mpc_sel <= '10';
                        pc_load <= '1';
                        sl_load <= '1';
                        cont_load <= '0';
                    when S8 =>              -- resetto il contatore a DIM
                        en <= '1';
                        in_load <= '1';
                        pc_load <= '0';
                        sl_load <= '0';
                        mcont_sel <= '0';
                    when S9 =>              -- calcolo il valore temporaneo
                        en <= '0';
                        in_load <= '1';
                        temp_load <= '1';
                        cont_load <= '0';
                    when S10 =>             -- definisco il valore finale da scrivere
                        temp_load <= '0';
                        nv_load <= '1';
                    when S11 =>             -- scrivo in memoria il valore calcolato all'indirizzo di memoria a distanza DIM da quello del pixel letto
                        en <= '1';
                        we <= '1';
                        mpc_sel <= '01';
                        pc_load <= '1';
                        nv_load <= '0';
                    when S12 =>             -- leggo il byte successivo e aggiorno il contatore
                        we <= '0';
                        in_load <= '1';
                        pc_load <= '0';
                        mcont_sel <= '1';
                        cont_load <= '1';
                    when S13 =>             -- resetto tutti i segnali e alzo il segnale DONE. PC è già l'indirizzo del primo byte della prossima immagine
                        en <= '0';
                        we <= '0';
                        in_load <= '0';
                        pc_load <= '0';
                        sl_load <= '0';
                        pc0_load <= '0';
                        temp_load <= '0';
                        nv_load <= '0';
                        cont_load <= '0';
                        o_done <= '1';
                    when S14 =>             -- quando si abbassa START posso riabbassare DONE
                        o_done <= '0';
                end case;
    end process;
                
end Behavioral;
