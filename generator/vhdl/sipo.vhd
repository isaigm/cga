library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sipo is
    generic (
        N : integer := 16 
    );
    Port ( 
        clk         : in std_logic;
        reset       : in std_logic;
        enable      : in std_logic;  
        in_bit      : in std_logic;  
        valid       : out std_logic; 
        output_data : out std_logic_vector(N - 1 downto 0)
    );
end sipo;

architecture Behavioral of sipo is
    signal s_valid : std_logic := '0';
    signal s_reg   : std_logic_vector(N - 1 downto 0) := (others => '0'); 
    signal s_cnt   : integer range 0 to N - 1 := 0; 
begin
    process (clk, reset)
    begin
        if reset = '1' then 
            s_valid <= '0';
            s_reg <= (others => '0');
            s_cnt <= 0;
            
        elsif rising_edge(clk) then
            
            s_valid <= '0'; 
            
            if enable = '1' then
                
                
                s_reg <= s_reg(N - 2 downto 0) & in_bit;
                
                if s_cnt = N - 1 then 
                    s_cnt <= 0;
                    s_valid <= '1';
                else
                    s_cnt <= s_cnt + 1;
                end if;
                
            end if;
        end if;
    end process;

    valid <= s_valid;
    output_data <= s_reg;

end Behavioral;
