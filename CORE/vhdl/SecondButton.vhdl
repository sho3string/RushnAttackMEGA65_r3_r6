library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bombtrigger is
port (
 clk_i           : in std_logic;
 enable_n_i      : in std_logic;
 reset_i         : in std_logic;
 -- player 1
 fire1_n_i       : in std_logic;
 bomb1_o         : out std_logic;
 -- player 2
 fire2_n_i       : in std_logic;
 bomb2_o         : out std_logic;
 -- trigger select switch
 trigger_sel_i   : in std_logic_vector(3 downto 0)
);

end entity bombtrigger;

architecture synthesis of bombtrigger is

-- Press and hold mechanic, similar to games like "Who Dares Wins" to work around single fire button limitation.
-- Based on 48mhz * 0.20s roughly 9,600,000 - default setting.    
signal bomb1_trigger_count : integer range 0 to 16000000 ; -- Counter for a maximum of 0.33 seconds at 48mhz
signal bomb2_trigger_count : integer range 0 to 16000000 ;
signal bomb_delay          : integer range 0 to 16000000 ; -- Delay setting from OSM

begin
process (clk_i,fire1_n_i,fire2_n_i)
begin
    if rising_edge(clk_i) then
    
       if enable_n_i = '0' then
       
           -- check the delay setting from the OSM.
           bomb_delay <= 0  when trigger_sel_i = "0000" else     -- no delay 
                   4800000  when trigger_sel_i = "0001" else     -- 0.10s
                   6400000  when trigger_sel_i = "0010" else     -- 0.13s
                   8000000  when trigger_sel_i = "0011" else     -- 0.16s
                   9600000  when trigger_sel_i = "0100" else     -- 0.20s
                   11200000 when trigger_sel_i = "0101" else     -- 0.23s
                   12280000 when trigger_sel_i = "0110" else     -- 0.25s
                   14400000 when trigger_sel_i = "0111" else     -- 0.30s
                   16000000 when trigger_sel_i = "1000";         -- 0.33s
           
           if reset_i = '1' then
              bomb1_trigger_count <= bomb_delay;
              bomb1_o <= '0';
              bomb2_trigger_count <= bomb_delay;
              bomb2_o <= '0';
           else
                -- handle player 1
                if fire1_n_i = '0' then
                    if  bomb1_trigger_count = 0 then    
                        bomb1_o <= '1';
                    else
                        bomb1_trigger_count <= bomb1_trigger_count - 1;
                        bomb1_o <= '0';
                    end if;
                else
                   bomb1_trigger_count <= bomb_delay;
                   bomb1_o <= '0';
                end if;
                
                -- handle player 2 ( cocktail mode only )
                if fire2_n_i = '0' then
                    if  bomb2_trigger_count = 0 then
                        bomb2_o <= '1';
                    else
                        bomb2_trigger_count <= bomb2_trigger_count - 1;
                        bomb2_o <= '0';
                    end if;
                else
                   bomb2_trigger_count <= bomb_delay; 
                   bomb2_o <= '0';
                end if;
           end if;
        end if;
  end if;
end process;

 
end architecture synthesis;