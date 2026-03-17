library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is 
    generic (
        TICKS_PER_BIT : integer := 868 
    );
    Port ( 
        clk   : in std_logic;
        reset : in std_logic;         
        start : in std_logic;         
        data  : in std_logic_vector(7 downto 0); 
        tx    : out std_logic;
        
        ready : out std_logic         
    );
end uart_tx;

architecture Behavioral of uart_tx is

    type State is (IDLE, S_START, DATA_BITS, STOP);
    signal curr_state : State := IDLE;
    
    signal s_tx    : std_logic := '1';
    signal counter : integer range 0 to TICKS_PER_BIT := 0;
    signal idx     : integer range 0 to 7 := 0;
    signal tx_data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                curr_state <= IDLE;
                s_tx <= '1';
                counter <= 0;
                idx <= 0;
                ready <= '0'; 
            else
                
                case curr_state is 
                
                    when IDLE =>
                        s_tx <= '1';
                        counter <= 0; 
                        idx <= 0;
                        ready <= '1'; 
                        
                        if start = '1' then
                            ready <= '0'; 
                            tx_data_reg <= data;
                            curr_state <= S_START;
                        end if;

                    when others =>
                        ready <= '0'; 
                        
                        if counter < TICKS_PER_BIT - 1 then
                            counter <= counter + 1;
                        else
                            counter <= 0; 
                            
                            case curr_state is
                                when S_START =>
                                    s_tx <= '0'; 
                                    curr_state <= DATA_BITS;
                                
                                when DATA_BITS =>
                                    s_tx <= tx_data_reg(idx);
                                    if idx = 7 then
                                        idx <= 0;
                                        curr_state <= STOP;
                                    else
                                        idx <= idx + 1;
                                    end if;
                                
                                when STOP =>
                                    s_tx <= '1'; 
                                    curr_state <= IDLE; 
                                    
                                when others =>
                                    curr_state <= IDLE;
                            end case;
                        end if;
                end case;
            end if;
        end if;
    end process;

    tx <= s_tx;

end Behavioral;
