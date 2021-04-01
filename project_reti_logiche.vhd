----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 20:57:03
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
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
        d_sel: in std_logic_vector (1 downto 0); -- instradamento ingresso
        i_we: in std_logic;
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
        mux_compare_sel: in std_logic; -- seleziona quale numero confrontare
        -- modulo shift level
        delta_load: in std_logic; -- load del registro delta
        shift_lvl_load: in std_logic; -- load del registro shift_lvl
        -- modulo new value
        temp_load: in std_logic; -- load registro temp
        new_value_load: in std_logic; -- load registro new value
        -- uscite
        o_data : out std_logic_vector (7 downto 0); -- esce per andare in memoria
        o_address: out std_logic_vector(15 downto 0); -- indirizzo attuale
        o_dim_zero: out std_logic; -- segnale di fine calcolo dimensione
        o_zero: out std_logic--; -- =1 <==> il contatore raggiunge lo 0
        --o_done : out std_logic
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
    signal delta_reg: std_logic_vector(7 downto 0);
    signal shift_lvl_reg: std_logic_vector(3 downto 0);
    signal temp_reg: std_logic_vector(15 downto 0);
    signal new_value_reg: std_logic_vector(7 downto 0);
    signal sign_extension: std_logic_vector(15 downto 0);
    
begin

    process(i_clk, i_res)
    begin
    
        if(i_res = '1') then
            
            in_reg <= eight_bit_zero;
            pc_reg <= sixteen_bit_zero;
            pc_iniz_reg <= sixteen_bit_zero;
            dim_reg <= sixteen_bit_zero;
            dim_zero_reg <= eight_bit_zero;
            counter_reg <= sixteen_bit_zero;
            max_reg <= eight_bit_zero;
            min_reg <= "11111111";
            delta_reg <= eight_bit_zero;
            shift_lvl_reg <= "0000";
            temp_reg <= sixteen_bit_zero;
            new_value_reg <= eight_bit_zero; 
            sign_extension <= sixteen_bit_zero;
             
        elsif(i_clk'event and i_clk='1') then
            
            -- gestione pc
            if(pc_load = '1') then
                if(mux_pc_sel = '1') then
                    pc_reg <= pc_iniz_reg;
                elsif(mux_pc_sel = '0') then
                    pc_reg <= pc_reg + "0000000000000001";
                end if;
            end if;
            
            if(pc_iniz_load = '1') then
                pc_iniz_reg <= pc_reg;
            end if;
            
            -- carico registro iniziale
            if(in_load = '1') then
                in_reg <= i_data;
            end if;
            
            -- carico contatore
            if(cont_load = '1') then
                if(mux_cont_sel = '1') then
                    counter_reg <= counter_reg - "0000000000000001";
                elsif(mux_cont_sel = '0') then
                    if(d_sel = "10") then
                        counter_reg <= dim_reg;
                    else
                        counter_reg <= dim_reg - "0000000000000001";
                    end if;
                end if;
            end if;
            
            -- segnale zero
            if(counter_reg = "0000000000000001" or dim_reg = "0000000000000001") then
                o_zero <= '1';
            else
                o_zero <= '0';
            end if;
            
            --------------------- uscite demux ----------------------------
             if(d_sel = "00") then -- CASO 00
                if(mux_dim_sel = '0') then
		          if(dim_zero_load = '1') then
			         dim_zero_reg <= in_reg - "00000001";
		          end if;
		          if(in_reg - "00000001" = 0) then
		              o_dim_zero <= '1';
		          else
		              o_dim_zero <= '0';
		          end if;
	           elsif(mux_dim_sel = '1') then
		          if(dim_zero_load = '1') then
			         dim_zero_reg <= dim_zero_reg - "00000001";
		          end if;
		          if(dim_load ='1') then
			         dim_reg <= (eight_bit_zero & in_reg) + dim_reg;
		          end if;
		          if(dim_zero_reg - "00000001" = eight_bit_zero) then
                    o_dim_zero <= '1';
                  else
                    o_dim_zero <= '0';
                  end if;
	           end if;
	           
	           
            elsif(d_sel = "01") then -- CASO 01
                if(mux_compare_sel = '0') then
                    max_reg <= in_reg;
                    min_reg <= in_reg;
                elsif(mux_compare_sel = '1') then
                    if(in_reg < min_reg) then
                        min_reg <= in_reg;
                    end if;
                    if(in_reg > max_reg) then
                        max_reg <= in_reg;
                    end if;
                end if;
            --
            --    
            elsif(d_sel = "10") then -- CASO 10
                sign_extension <= "00000000" & (in_reg - min_reg);
                -- creazione di temp
                if(temp_load = '1') then
                    temp_reg <= std_logic_vector( shift_left( unsigned(sign_extension), to_integer(unsigned(shift_lvl_reg))));
                end if;
            end if;
            ---------------------------------------------------------------
            
            --shift level
            if(delta_load = '1') then
                delta_reg <= max_reg - min_reg;
            end if;
            
            
 
            if(shift_lvl_load = '1') then
                if(delta_reg = 0) then
                    shift_lvl_reg <= "1000" - "0000";
                elsif(delta_reg = "00000001" or delta_reg = "00000010") then
                    shift_lvl_reg <= "1000" - "0001";
                elsif(delta_reg > "00000010" and delta_reg < "00000111") then
                    shift_lvl_reg <= "1000" - "0010";
                elsif(delta_reg > "00000110" and delta_reg < "00001111") then
                    shift_lvl_reg <= "1000" - "0011";
                elsif(delta_reg > "00001110" and delta_reg  < "00011111") then
                    shift_lvl_reg <= "1000" - "0100";
                elsif(delta_reg > "00011110" and delta_reg  < "00111111") then
                    shift_lvl_reg <= "1000" - "0101";
                elsif(delta_reg > "00111110" and delta_reg  < "01111111") then
                    shift_lvl_reg <= "1000" - "0110";
                elsif(delta_reg > "01111110" and delta_reg  < "11111111") then
                    shift_lvl_reg <= "1000" - "0111";
                elsif(delta_reg = "11111111") then
                    shift_lvl_reg <= "1000" - "1000";
                end if;
            end if;
            
            -- new value
            if(new_value_load = '1') then
                if(temp_reg > "0000000011111111") then
                    new_value_reg <= "11111111";
                else
                    new_value_reg <= temp_reg(7 downto 0);
                end if;
            end if;
            
            if(i_we = '1') then
                o_address <= pc_reg + dim_reg;
            elsif(i_we = '0') then
                o_address <= pc_reg;
            end if;
            
        end if;    
    end process;
    
    o_data <= new_value_reg;
    
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
            d_sel: in std_logic_vector (1 downto 0);
            i_we: in std_logic;
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
            mux_compare_sel: in std_logic;
            -- modulo shift level
            delta_load: in std_logic;
            shift_lvl_load: in std_logic;
            -- modulo new value
            temp_load: in std_logic;
            new_value_load: in std_logic;
            -- uscite
            o_data : out std_logic_vector (7 downto 0); 
            o_address: out std_logic_vector(15 downto 0);
            o_dim_zero: out std_logic;
            o_zero: out std_logic--;
            --o_done : out std_logic
        );
    end component;
    
    type S is (RESET_STATE, S0, S1, S2, S3_0, S3_1, S4, S5, S6, S7, S8, 
               S9, S10, S11, S11_BUFf_12, S12, S13, S13_BUFF_14, S14, S15, S16, S16_BUFF_17, S17, S18, S18_BUFF_14, S19, S20, S_POZZO);
    
    signal current_state: S; -- stato corrente
    signal next_state: S; -- stato successivo
    signal in_load: std_logic;
    signal d_sel: std_logic_vector(1 downto 0);
    signal i_we: std_logic;
    signal mux_dim_sel: std_logic;
    signal dim_load: std_logic;
    signal dim_zero_load: std_logic;
    signal mux_cont_sel: std_logic;
    signal cont_load: std_logic;
    signal mux_pc_sel: std_logic;
    signal pc_load: std_logic;
    signal mux_addr_sel: std_logic;
    signal pc_iniz_load: std_logic;
    signal mux_compare_sel: std_logic;
    signal delta_load: std_logic;
    signal shift_lvl_load: std_logic;
    signal temp_load: std_logic;
    signal new_value_load: std_logic;
    signal o_dim_zero: std_logic;
    signal o_zero: std_logic;

begin
    
    DATAPATH0: datapath port map(     -- mappa i segnali con i nomi originali
        i_clk,
        i_rst,
        i_data,
        in_load,
        d_sel,
        i_we,
        mux_dim_sel,
        dim_load,
        dim_zero_load,
        mux_cont_sel,
        cont_load,
        mux_pc_sel,
        pc_load,
        mux_addr_sel,
        pc_iniz_load,
        mux_compare_sel,
        delta_load,
        shift_lvl_load,
        temp_load,
        new_value_load,
        o_data,
        o_address,
        o_dim_zero,
        o_zero--,
        --o_done
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
                    next_state <= S0;
                end if;
            when S0 =>
                next_state <= S1;
            when S1 =>
                next_state <= S2;
            when S2 =>
                if o_dim_zero = '1' then
                    next_state <= S3_1;
                else
                    next_state <= S3_0;
                end if;
            when S3_0 =>
                if o_dim_zero = '1' then
                    next_state <= S4;
                else
                    next_state <= S3_0;
                end if;
            when S3_1 =>
                next_state <= S4;  
            when S4 =>
                if o_zero = '1' then    -- caso DIM=1
                    next_state <= S_POZZO;  -- A CASO LO STO USANDO COME POZZO TANTO NEL TB DIM>1
                else                    -- caso DIM>1
                    next_state <= S5;
                end if;
            when S5 =>
                if o_zero = '1' then    -- caso DIM=2
                    next_state <= S_POZZO;  -- A CASO LO STO USANDO COME POZZO TANTO NEL TB DIM>2
                else
                    next_state <= S6;
                end if;
            when S6 =>
                if o_zero = '0' then
                    next_state <= S6;
                else
                    next_state <= S7;
                end if;
            when S7 =>
                next_state <= S8;
            when S8 =>
                next_state <= S9;
            when S9 =>
                next_state <= S10;
            when S10 =>
                next_state <= S11;
            when S11 =>
                next_state <= S11_BUFF_12;
            when S11_BUFF_12 =>
                next_state <= S12;
            when S12 =>
                next_state <= S13;
--            when S13 =>
--                if o_zero = '0' then
--                    next_state <= S14;
--                elsif o_zero = '1' then
--                    next_state <= S19;
--                end if;
            when S13 =>
                if o_zero = '0' then
                    next_state <= S13_BUFF_14;
                elsif o_zero = '1' then
                    next_state <= S19;
                end if;
            when S13_BUFF_14 =>
                next_state <= S14;
            when S14 =>
                next_state <= S15;
            when S15 =>
                next_state <= S16;
            when S16 =>
                next_state <= S16_BUFF_17;
            when S16_BUFF_17 =>
                next_state <= S17;
            when S17 =>
                next_state <= S18;
--            when S18 =>
--                if o_zero = '0' then
--                    next_state <= S14;
--                elsif o_zero = '1' then
--                    next_state <= S19;
--                end if;
            when S18 =>
                if o_zero = '0' then
                    next_state <= S18_BUFF_14;
                elsif o_zero = '1' then
                    next_state <= S19;
                end if;
            when S18_BUFF_14 =>
                next_state <= S14;
            when S19 =>
                if i_start = '0' then
                    next_state <= S20;
                end if;
            when S20 =>
                if i_start = '1' then
                    next_state <= S0;
                end if;
            when S_POZZO =>
        end case;
    end process;
            
    process(current_state)      -- gestisce i segnali degli stati della fsm
            begin
                -- inizializzazione dei segnali
                pc_load <= '0';
                pc_iniz_load <= '0';
                in_load <= '0';
                dim_load <= '0';
                dim_zero_load <= '0';
                cont_load <= '0';
                delta_load <= '0';   --  forse inutile
                shift_lvl_load <= '0';
                temp_load <= '0';
                new_value_load <= '0';
                d_sel <= "00";
                mux_dim_sel <= '0';
                mux_cont_sel <= '0';
                mux_compare_sel <= '0';
                mux_pc_sel <= '0';
                o_en <= '0';    -- mandato alla memoria
                i_we <= '0';    -- mandato al datapath
                o_we <= '0';    -- mandato alla memoria
                o_done <= '0';
                
                case current_state is
                    when RESET_STATE =>     -- non cambio nulla, tutto è già stato inizializzato
                    when S0 =>
                    -- leggo M(0), PC++
                        o_en <= '1';
                        mux_pc_sel <= '0';
                        pc_load <= '1';     -- PC=1, ADDR=0
                    when S1 =>
                    -- carico M(0), leggo M(1), PC++
                    -- carico DIM=1 temporaneamente
                        o_en <= '1';
                        mux_pc_sel <= '0';
                        pc_load <= '1';     -- PC=2, ADDR=1
                        in_load <= '1';
                    when S2 =>
                    -- non leggo da memoria, carico M(1), carico PC0=PC
                    -- carico DIM=M(0) temporaneamente
                        o_en <= '0';
                        in_load <= '1';
                        mux_pc_sel <= '0';
                        pc_load <= '0';     -- PC=2, ADDR=2
                        pc_iniz_load <= '1';    -- carico PC0=PC=2
                        mux_dim_sel <= '0';
                        dim_zero_load <= '1';
                        dim_load <= '0';
                        d_sel <= "00";
                    when S3_0 =>
                    -- carico il valore finale DIM=M(0)*M(1)
                        mux_dim_sel <= '1';
                        pc_load <= '0';
                        pc_iniz_load <= '0';
                        dim_load <= '1';
                        dim_zero_load <= '1';
                        in_load <= '0';
                        o_en <= '0';
                        d_sel <= "00";
                    when S3_1 =>
                    -- carico il valore finale DIM=M(0)*M(1)
                        mux_dim_sel <= '1';
                        pc_load <= '0';
                        pc_iniz_load <= '0';
                        dim_load <= '1';
                        dim_zero_load <= '0';
                        in_load <= '0';
                        o_en <= '0';
                        d_sel <= "00";
                    when S4 =>
                    -- leggo M(2), carico CONT=DIM-1, PC++
                        dim_load <= '0';
                        dim_zero_load <= '0';
                        mux_cont_sel <= '0';
                        cont_load <= '1';
                        o_en <= '1';
                        pc_load <= '1';     -- PC=3, ADDR=2
                        in_load <= '0';                        
                    when S5 =>
                    -- solo se in S4 zero=0 (DIM!=1)
                    -- carico MIN=MAX=M(2), carico M(2), leggo M(3), PC++, CONT--                        
                        mux_cont_sel <= '1';
                        cont_load <= '1';
                        o_en <= '1';
                        in_load <= '1';
                        pc_load <= '1';
                        mux_compare_sel <= '0';
                    when S6 =>
                    -- ciclo finchè non si alza zero (CONT-1==0)
                    -- carico M(3) o in generale il valore letto il ciclo prima, PC++, CONT--
                    -- indirizzo i valori caricati verso il modulo min/max
                        d_sel <= "01";
                        o_en <= '1';
                        in_load <= '1';
                        mux_compare_sel <= '1';
                        pc_load <= '1';
                        mux_cont_sel <= '1';
                        cont_load <= '1';
                    when S7 =>
                    --
                        o_en <= '0';
                        in_load <= '1';
                        d_sel <= "01";
                        mux_pc_sel <= '1';
                        pc_load <= '1';     --PC=PC0
                        cont_load <= '0';
                        mux_compare_sel <= '1';
                    when S8 =>
                        d_sel <= "01";
                        mux_compare_sel <= '1';
                        o_en <= '0';
                        in_load <= '0';
                    when S9 =>
                        delta_load <= '1';
                        o_en <= '1';
                    when S10 =>
                        shift_lvl_load <= '1';
                        in_load <= '1';
                    when S11 =>
                        d_sel <= "10";
                    when S11_BUFF_12 =>
                        d_sel <= "10";
                        temp_load <= '1';
                    when S12 =>
                        i_we <= '1';
                        d_sel <= "10";
                        new_value_load <= '1';
                    when S13 =>
                        d_sel <= "10";
                        o_en <= '1';
                        o_we <= '1';
                        mux_pc_sel <= '0';
                        pc_load <= '1';
                        mux_cont_sel <= '0';
                        cont_load <= '1';
                    when S13_BUFF_14 =>
                        d_sel <= "10";
                    when S14 =>
                        d_sel <= "10";
                        o_en <= '1';
                        mux_cont_sel <= '1';
                        cont_load <= '1';
                    when S15 =>
                        d_sel <= "10";
                        in_load <= '1';
                    when S16 =>
                        d_sel <= "10";
                    when S16_BUFF_17 =>
                        d_sel <= "10";
                        temp_load <= '1';
                    when S17 =>
                        i_we <= '1';                       
                        d_sel <= "10";
                        new_value_load <= '1';
                    when S18 =>
                        d_sel <= "10";
                        o_en <= '1';
                        o_we <= '1';
                        mux_pc_sel <= '0';
                        pc_load <= '1';
                        mux_cont_sel <= '1';
                    when S18_BUFF_14 =>
                        d_sel <= "10";
                    when S19 =>
                        o_done <= '1';
                    when S20 =>
                    when S_POZZO =>
                end case;
    end process;
end Behavioral;