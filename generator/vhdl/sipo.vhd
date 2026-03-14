library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sipo is
    generic (
        N : integer := 16 -- Siempre es buena práctica poner un valor por defecto
    );
    Port ( 
        clk         : in std_logic;
        reset       : in std_logic;
        enable      : in std_logic;  
        in_bit      : in std_logic;  
        valid       : out std_logic; 
        output_data : out std_logic_vector(N - 1 downto 0) -- CORREGIDO: N-1
    );
end sipo;

architecture Behavioral of sipo is
    signal s_valid : std_logic := '0';
    signal s_reg   : std_logic_vector(N - 1 downto 0) := (others => '0'); -- CORREGIDO: N-1
    signal s_cnt   : integer range 0 to N - 1 := 0; -- CORREGIDO: Cuenta de 0 a N-1
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
                
                -- CORREGIDO: Tomamos desde N-2 hasta 0, y concatenamos el nuevo bit
                -- Ejemplo para N=16: s_reg(14 downto 0) & in_bit
                s_reg <= s_reg(N - 2 downto 0) & in_bit;
                
                if s_cnt = N - 1 then -- CORREGIDO: Si llega a 15 (que es el ciclo 16)
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