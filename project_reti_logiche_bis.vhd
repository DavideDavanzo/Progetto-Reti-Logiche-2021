----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.04.2021 16:07:55
-- Design Name: 
-- Module Name: project_reti_logiche_bis - Behavioral
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
use IEEE.std_logic_arith;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.constants.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity datapath is
    port (
        -- entrate principali
        i_clk: in std_logic;
        i_res: in std_logic;
        i_data: in std_logic_vector (7 downto 0); -- entra nel circuito
        in_load: in std_logic; -- registro in entrata
        i_we: in std_logic;
        i_done : in std_logic;
        -- modulo dimensione
        mux_dim_sel: in std_logic; -- seleziona il secondo operando da moltiplicare
        dim_load: in std_logic; -- load del registro dim
        dim_zero_load: in std_logic; -- load del registro dim_zero
        mux_cont_sel: in std_logic; -- decide cosa far passare prima del sottrattore
        cont_load: in std_logic; -- load del registro cont
        -- modulo pc
        mux_pc_sel: in std_logic; -- seleziona quale indirizzo inserire nel pc
        pc_load: in std_logic; -- load del registro pc
        mux_addr_sel: in std_logic; -- decide che indirizzo mandare in memoria
        pc_iniz_load: in std_logic; -- load del registro pc iniziale
        -- modulo min max
        compare: in std_logic; -- seleziona quale numero confrontare
        -- modulo new value
        new_value_load: in std_logic; -- load registro new value
        -- uscite
        o_data : out std_logic_vector (7 downto 0); -- esce per andare in memoria
        o_address: out std_logic_vector(15 downto 0); -- indirizzo attuale
        o_dim_zero: out std_logic; -- segnale di fine calcolo dimensione
        o_zero: out std_logic--; -- =1 <==> il contatore raggiunge lo 0
    );
end datapath;

architecture Behavioral of datapath is
    -- registri
    signal in_reg: std_logic_vector(7 downto 0);
    signal pc_reg: std_logic_vector(15 downto 0);
    signal pc_iniz_reg: std_logic_vector(15 downto 0);
    signal dim_reg: std_logic_vector(15 downto 0);
    signal dim_zero_reg: std_logic_vector (7 downto 0);
    signal counter_reg: std_logic_vector(15 downto 0);
    signal max_reg: std_logic_vector(7 downto 0);
    signal min_reg: std_logic_vector(7 downto 0);
    signal delta: std_logic_vector(7 downto 0);
    signal shift_lvl: std_logic_vector(3 downto 0);
    signal temp: std_logic_vector(15 downto 0);
    signal new_value_reg: std_logic_vector(7 downto 0);
    signal sign_extension: std_logic_vector(15 downto 0);
    
begin
    --gestione in_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            in_reg <= eight_bit_zero;
        elsif rising_edge(i_clk) then
            if(in_load = '1') then
                in_reg <= i_data;
            end if;
        end if;
    end process;
    
    --gestione pc_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            pc_reg <= sixteen_bit_zero;
        elsif rising_edge(i_clk) then
            if(pc_load = '1') then
                if(mux_pc_sel = '1') then
                    pc_reg <= pc_iniz_reg;
                elsif(mux_pc_sel = '0') then
                    pc_reg <= pc_reg + "0000000000000001";
                end if;
            end if;
        end if;
    end process;
    
    --gestione pc_iniz_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            pc_iniz_reg <= sixteen_bit_zero;
        elsif rising_edge(i_clk) then
            if(pc_iniz_load = '1') then
                pc_iniz_reg <= pc_reg;
            end if;
        end if;
    end process;
    
    --gestione dim_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            dim_reg <= sixteen_bit_zero;
        elsif rising_edge(i_clk) then
            if(dim_load ='1') then
                dim_reg <= (eight_bit_zero & in_reg) + dim_reg;
		    end if;
        end if;
    end process;
    
    --gestione dim_zero_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            dim_zero_reg <= eight_bit_zero;
        elsif rising_edge(i_clk) then
            if(dim_zero_load = '1') then
                if(mux_dim_sel = '0') then
                    dim_zero_reg <= in_reg - "00000001";
                elsif(mux_dim_sel = '1') then
                    dim_zero_reg <= dim_zero_reg - "00000001";
                end if;
		    end if;
        end if;
    end process;
    
    --gestione counter_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            counter_reg <= sixteen_bit_zero;
        elsif rising_edge(i_clk) then
            if(cont_load = '1') then
                if(mux_cont_sel = '1') then
                    counter_reg <= counter_reg - "0000000000000001";
                elsif(mux_cont_sel = '0') then
                    counter_reg <= dim_reg;
                end if;
            end if;
        end if;
    end process;
    
    --gestione max/min
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            max_reg <= eight_bit_zero;
            min_reg <= "11111111";
        elsif rising_edge(i_clk) then
            if(compare = '1') then
                if(in_reg < min_reg) then
                    min_reg <= in_reg;
                end if;
                if(in_reg > max_reg) then
                    max_reg <= in_reg;
                end if;
            end if;
        end if;
    end process;
    
    --gestione shift_lvl_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            shift_lvl <= "0000";
        elsif rising_edge(i_clk) then
            if(delta = 0) then
                shift_lvl <= "1000" - "0000";
            elsif(delta = "00000001" or delta = "00000010") then
                shift_lvl <= "1000" - "0001";
            elsif(delta > "00000010" and delta < "00000111") then
                shift_lvl <= "1000" - "0010";
            elsif(delta > "00000110" and delta < "00001111") then
                shift_lvl <= "1000" - "0011";
            elsif(delta > "00001110" and delta  < "00011111") then
                shift_lvl <= "1000" - "0100";
            elsif(delta > "00011110" and delta  < "00111111") then
                shift_lvl <= "1000" - "0101";
            elsif(delta > "00111110" and delta  < "01111111") then
                shift_lvl <= "1000" - "0110";
            elsif(delta > "01111110" and delta  < "11111111") then
                shift_lvl <= "1000" - "0111";
            elsif(delta = "11111111") then
                shift_lvl <= "1000" - "1000";
            end if;
        end if;
    end process;
        
    --gestione new_value_reg
    process(i_clk, i_res)
    begin
        if(i_res = '1' or i_done = '1') then
            new_value_reg <= eight_bit_zero;
        elsif rising_edge(i_clk) then
            if(new_value_load = '1') then
                if(temp > "0000000011111111") then
                    new_value_reg <= "11111111";
                else
                    new_value_reg <= temp(7 downto 0);
                end if;
            end if;
        end if;
    end process;
    
    o_zero <= '1' when counter_reg = 0 else '0';
    
    o_dim_zero <= '1' when dim_zero_reg = 0 else '0';
    -- o_dim_zero <= '1' when (dim_zero_reg = 0 or dim_zero_reg = "11111111") else '0';
                  
    o_address <= pc_reg + dim_reg when i_we = '1' else pc_reg;
    
    o_data <= new_value_reg;
    
    delta <= max_reg - min_reg;
    
    sign_extension <= "00000000" & (in_reg - min_reg);
    
    temp <= std_logic_vector( shift_left( unsigned(sign_extension), to_integer(unsigned(shift_lvl)) ) );
    
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith;
use work.constants.all;

entity project_reti_logiche is
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
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
        
    component datapath is
        port (
            -- entrate principali
            i_clk: in std_logic;
            i_res: in std_logic;
            i_data: in std_logic_vector (7 downto 0);
            in_load: in std_logic;
            i_we: in std_logic;
            i_done: in std_logic;
            -- modulo dimensione
            mux_dim_sel: in std_logic;
            dim_load: in std_logic;
            dim_zero_load: in std_logic;
            mux_cont_sel: in std_logic;
            cont_load: in std_logic;
            -- modulo pc
            mux_pc_sel: in std_logic;
            pc_load: in std_logic;
            mux_addr_sel: in std_logic;
            pc_iniz_load: in std_logic;
            -- modulo min max
            compare: in std_logic;
            new_value_load: in std_logic;
            -- uscite
            o_data : out std_logic_vector (7 downto 0); 
            o_address: out std_logic_vector(15 downto 0);
            o_dim_zero: out std_logic;
            o_zero: out std_logic
        );
    end component;
    
    type S is ( RESET_STATE,
                FETCH_NUM_COLS,
                FETCH_NUM_ROWS,
                INIT_DIM_COUNTER,
                COMPUTE_DIM,
                FETCH_FIRST_PIXEL,
                FIND_MAX_MIN,
                COMPUTE_SHIFT_LEVEL,
                RESTART_FROM_FIRST_PIXEL,
                LOAD_OLD_VALUE,
                COMPUTE_NEW_VALUE,
                WRITE_NEW_VALUE,
                DONE);
    
    signal current_state: S; -- stato corrente
    signal next_state: S; -- stato successivo
    signal in_load: std_logic;
    signal i_we: std_logic;
    signal i_done: std_logic;
    signal mux_dim_sel: std_logic;
    signal dim_load: std_logic;
    signal dim_zero_load: std_logic;
    signal mux_cont_sel: std_logic;
    signal cont_load: std_logic;
    signal mux_pc_sel: std_logic;
    signal pc_load: std_logic;
    signal mux_addr_sel: std_logic;
    signal pc_iniz_load: std_logic;
    signal compare: std_logic;
    signal new_value_load: std_logic;
    signal o_dim_zero: std_logic;
    signal o_zero: std_logic;

begin
    
    DATAPATH0: datapath port map(     -- mappa i segnali con i nomi originali
        i_clk,
        i_rst,
        i_data,
        in_load,
        i_we,
        i_done,     
        mux_dim_sel,
        dim_load,
        dim_zero_load,
        mux_cont_sel,
        cont_load,
        mux_pc_sel,
        pc_load,
        mux_addr_sel,
        pc_iniz_load,
        compare,
        new_value_load,
        o_data,
        o_address,
        o_dim_zero,
        o_zero
    );

    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            current_state <= RESET_STATE;
        elsif rising_edge(i_clk) then       -- commuta sul fronte di salita
            current_state <= next_state;
        end if;
    end process;

    process(current_state, i_start, o_zero, o_dim_zero)
    begin
        next_state <= current_state;
        case current_state is
            when RESET_STATE =>
                if (i_start = '1') then
                    next_state <= FETCH_NUM_COLS;
                end if;
            when FETCH_NUM_COLS =>
                next_state <= FETCH_NUM_ROWS;
            when FETCH_NUM_ROWS =>
                next_state <= INIT_DIM_COUNTER;
            when INIT_DIM_COUNTER =>
                next_state <= COMPUTE_DIM;
            when COMPUTE_DIM =>
                if o_dim_zero = '1' then
                    next_state <= FETCH_FIRST_PIXEL;
                end if;
            when FETCH_FIRST_PIXEL =>
                next_state <= FIND_MAX_MIN;
            when FIND_MAX_MIN =>
                if o_zero = '1' then
                    next_state <= COMPUTE_SHIFT_LEVEL;
                end if;
            when COMPUTE_SHIFT_LEVEL =>
                next_state <= RESTART_FROM_FIRST_PIXEL;
            when RESTART_FROM_FIRST_PIXEL =>
                next_state <= LOAD_OLD_VALUE;
            when LOAD_OLD_VALUE =>
                next_state <= COMPUTE_NEW_VALUE;
            when COMPUTE_NEW_VALUE =>
                next_state <= WRITE_NEW_VALUE;
            when WRITE_NEW_VALUE =>
                if o_zero = '1' then
                    next_state <= DONE;
                else
                    next_state <= RESTART_FROM_FIRST_PIXEL;
                end if;
            when DONE =>
                if i_start = '0' then
                    next_state <= RESET_STATE;
                end if;
        end case;
    end process;
            
    process(current_state)
            begin
            -- inizializzazione dei segnali
                pc_load <= '0';
                pc_iniz_load <= '0';
                in_load <= '0';
                dim_load <= '0';
                dim_zero_load <= '0';
                cont_load <= '0';
                new_value_load <= '0';
                mux_dim_sel <= '0';
                mux_cont_sel <= '0';
                compare <= '0';
                mux_pc_sel <= '0';
                o_en <= '0';    -- mandato alla memoria
                i_we <= '0';    -- mandato al datapath
                o_we <= '0';    -- mandato alla memoria
                o_done <= '0';    -- mandato alla memoria
                i_done <= '0';    -- mandato al datapath
                
                case current_state is
                    when RESET_STATE =>
                    when FETCH_NUM_COLS =>
                    -- leggo M(0), PC++
                        o_en <= '1';
                        pc_load <= '1';
                    when FETCH_NUM_ROWS =>
                    -- carico M(0), leggo M(1), PC++
                        o_en <= '1';
                        in_load <= '1';
                        pc_load <= '1';
                    when INIT_DIM_COUNTER =>
                    -- non leggo da memoria, carico M(1), carico PC0=PC
                    -- carico DIM_ZERO=M(0)
                        in_load <= '1';
                        pc_iniz_load <= '1';
                        dim_zero_load <= '1';
                    when COMPUTE_DIM =>
                        o_en <= '1';
                        mux_dim_sel <= '1';
                        dim_load <= '1';
                        dim_zero_load <= '1';
                    when FETCH_FIRST_PIXEL =>
                    -- leggo M(2), carico CONT=DIM
                        cont_load <= '1';
                        o_en <= '1';
                        in_load <= '1';
                        pc_load <= '1';
                    when FIND_MAX_MIN =>
                    -- carico i valori e confronto per trovare max e min
                        compare <= '1';
                        o_en <= '1';
                        in_load <= '1';
                        pc_load <= '1';
                        mux_cont_sel <= '1';
                        cont_load <= '1';
                    when COMPUTE_SHIFT_LEVEL =>
                    -- calcolo delta, carico PC=PC_iniz
                        mux_pc_sel <= '1';
                        pc_load <= '1';
                        cont_load <= '1';
                    when RESTART_FROM_FIRST_PIXEL =>
                    -- ricomincio lettura da M(2) e resetto COUNTER_REG=DIM
                        o_en <= '1';
                        mux_cont_sel <= '1';
                        cont_load <= '1';
                    when LOAD_OLD_VALUE =>
                    -- carico pixel value
                        in_load <= '1';
                    when COMPUTE_NEW_VALUE =>
                    -- carico new value
                        new_value_load <= '1';
                    when WRITE_NEW_VALUE =>
                    -- scrivo in memoria NEW_VALUE_REG, PC++
                        o_en <= '1';
                        o_we <= '1';
                        i_we <= '1';
                        pc_load <= '1';
                    when DONE =>
                    -- computazione finita
                        o_done <= '1';
                        i_done <= '1';
                end case;
    end process;
end Behavioral;