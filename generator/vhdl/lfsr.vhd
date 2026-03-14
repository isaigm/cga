library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr is
    generic (
        SEED : std_logic_vector(31 downto 0) := x"ACE11ECA" 
    );
    Port ( 
        clk        : in  std_logic;      
        reset      : in  std_logic;      
        output_bit : out std_logic       
    );
end lfsr;

architecture Behavioral of lfsr is

    signal s_reg : std_logic_vector(31 downto 0) := SEED; 
    
    signal s_feedback : std_logic;

begin

    s_feedback <= s_reg(31) xor s_reg(21) xor s_reg(1) xor s_reg(0);

    process (clk, reset)
    begin
        if reset = '1' then
            s_reg <= SEED; 
            
        elsif rising_edge(clk) then
            s_reg <= s_reg(30 downto 0) & s_feedback;
        end if;
    end process;

    output_bit <= s_reg(31);

end Behavioral;