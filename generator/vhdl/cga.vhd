library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.n_queens_types.all;

entity cga is
    Port (
        CLK100MHZ : in std_logic;
        btnR      : in std_logic;
        btnL      : in std_logic;
        LED       : out std_logic_vector(6-1 downto 0);
        RsTx      : out std_logic
     );
end cga;

architecture Behavioral of cga is

    signal reset_clean  : std_logic;
    signal start_clean  : std_logic;
    signal en_init      : std_logic := '0';
    signal en_crossover : std_logic := '0';
    signal en_mutation  : std_logic := '0';

    type state_type is (S_IDLE, S_INIT, S_WAIT_INIT, S_CROSS, S_WAIT_CROSS, S_MUTATE, S_WAIT_MUT, S_DONE, S_TX_LOAD, S_TX_ACK, S_TX_WAIT);
    signal state : state_type := S_IDLE;

    signal wait_cnt : integer range 0 to 7 := 0;

    signal top_lfsr     : std_logic_vector(31 downto 0) := x"DEADBEEF";
    signal mut_prob_reg : std_logic_vector(2 downto 0) := "000";

    signal uart_start : std_logic := '0';
    signal uart_ready : std_logic;
    signal uart_data  : std_logic_vector(7 downto 0) := (others => '0');

    signal tx_idx     : integer range 0 to 10 + 3 := 0;

    signal cycle_counter : unsigned(31 downto 0) := (others => '0');
    signal is_computing  : std_logic := '0';

    signal fit_0_0 : unsigned(6-1 downto 0);
    signal chrom_0_0 : queen_chrom_t;
    signal fit_0_1 : unsigned(6-1 downto 0);
    signal chrom_0_1 : queen_chrom_t;
    signal fit_0_2 : unsigned(6-1 downto 0);
    signal chrom_0_2 : queen_chrom_t;
    signal fit_0_3 : unsigned(6-1 downto 0);
    signal chrom_0_3 : queen_chrom_t;
    signal fit_0_4 : unsigned(6-1 downto 0);
    signal chrom_0_4 : queen_chrom_t;
    signal fit_1_0 : unsigned(6-1 downto 0);
    signal chrom_1_0 : queen_chrom_t;
    signal fit_1_1 : unsigned(6-1 downto 0);
    signal chrom_1_1 : queen_chrom_t;
    signal fit_1_2 : unsigned(6-1 downto 0);
    signal chrom_1_2 : queen_chrom_t;
    signal fit_1_3 : unsigned(6-1 downto 0);
    signal chrom_1_3 : queen_chrom_t;
    signal fit_1_4 : unsigned(6-1 downto 0);
    signal chrom_1_4 : queen_chrom_t;
    signal fit_2_0 : unsigned(6-1 downto 0);
    signal chrom_2_0 : queen_chrom_t;
    signal fit_2_1 : unsigned(6-1 downto 0);
    signal chrom_2_1 : queen_chrom_t;
    signal fit_2_2 : unsigned(6-1 downto 0);
    signal chrom_2_2 : queen_chrom_t;
    signal fit_2_3 : unsigned(6-1 downto 0);
    signal chrom_2_3 : queen_chrom_t;
    signal fit_2_4 : unsigned(6-1 downto 0);
    signal chrom_2_4 : queen_chrom_t;
    signal fit_3_0 : unsigned(6-1 downto 0);
    signal chrom_3_0 : queen_chrom_t;
    signal fit_3_1 : unsigned(6-1 downto 0);
    signal chrom_3_1 : queen_chrom_t;
    signal fit_3_2 : unsigned(6-1 downto 0);
    signal chrom_3_2 : queen_chrom_t;
    signal fit_3_3 : unsigned(6-1 downto 0);
    signal chrom_3_3 : queen_chrom_t;
    signal fit_3_4 : unsigned(6-1 downto 0);
    signal chrom_3_4 : queen_chrom_t;
    signal fit_4_0 : unsigned(6-1 downto 0);
    signal chrom_4_0 : queen_chrom_t;
    signal fit_4_1 : unsigned(6-1 downto 0);
    signal chrom_4_1 : queen_chrom_t;
    signal fit_4_2 : unsigned(6-1 downto 0);
    signal chrom_4_2 : queen_chrom_t;
    signal fit_4_3 : unsigned(6-1 downto 0);
    signal chrom_4_3 : queen_chrom_t;
    signal fit_4_4 : unsigned(6-1 downto 0);
    signal chrom_4_4 : queen_chrom_t;


begin

    push_btn_reset: entity work.push_btn port map(clk => CLK100MHZ, btn => btnR, enabled => reset_clean);
    push_btn_start: entity work.push_btn port map(clk => CLK100MHZ, btn => btnL, enabled => start_clean);

    uart_tx_inst: entity work.uart_tx
        port map (
            clk   => CLK100MHZ,
            reset => reset_clean,
            start => uart_start,
            data  => uart_data,
            tx    => RsTx,
            ready => uart_ready
        );

    cell_0_0: entity work.cell
        generic map (
            CELL_SEED => x"64E80C9E"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_0,
            north_chrom   => chrom_4_0,
            south_fitness => fit_1_0,
            south_chrom   => chrom_1_0,
            east_fitness  => fit_0_1,
            east_chrom    => chrom_0_1,
            west_fitness  => fit_0_4,
            west_chrom    => chrom_0_4,
            fitness       => fit_0_0,
            chromosome    => chrom_0_0
        );

    cell_0_1: entity work.cell
        generic map (
            CELL_SEED => x"8FE81008"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_1,
            north_chrom   => chrom_4_1,
            south_fitness => fit_1_1,
            south_chrom   => chrom_1_1,
            east_fitness  => fit_0_2,
            east_chrom    => chrom_0_2,
            west_fitness  => fit_0_0,
            west_chrom    => chrom_0_0,
            fitness       => fit_0_1,
            chromosome    => chrom_0_1
        );

    cell_0_2: entity work.cell
        generic map (
            CELL_SEED => x"16317716"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_2,
            north_chrom   => chrom_4_2,
            south_fitness => fit_1_2,
            south_chrom   => chrom_1_2,
            east_fitness  => fit_0_3,
            east_chrom    => chrom_0_3,
            west_fitness  => fit_0_1,
            west_chrom    => chrom_0_1,
            fitness       => fit_0_2,
            chromosome    => chrom_0_2
        );

    cell_0_3: entity work.cell
        generic map (
            CELL_SEED => x"DCF5DCC2"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_3,
            north_chrom   => chrom_4_3,
            south_fitness => fit_1_3,
            south_chrom   => chrom_1_3,
            east_fitness  => fit_0_4,
            east_chrom    => chrom_0_4,
            west_fitness  => fit_0_2,
            west_chrom    => chrom_0_2,
            fitness       => fit_0_3,
            chromosome    => chrom_0_3
        );

    cell_0_4: entity work.cell
        generic map (
            CELL_SEED => x"CCF55F43"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_4,
            north_chrom   => chrom_4_4,
            south_fitness => fit_1_4,
            south_chrom   => chrom_1_4,
            east_fitness  => fit_0_0,
            east_chrom    => chrom_0_0,
            west_fitness  => fit_0_3,
            west_chrom    => chrom_0_3,
            fitness       => fit_0_4,
            chromosome    => chrom_0_4
        );

    cell_1_0: entity work.cell
        generic map (
            CELL_SEED => x"07006FB5"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_0,
            north_chrom   => chrom_0_0,
            south_fitness => fit_2_0,
            south_chrom   => chrom_2_0,
            east_fitness  => fit_1_1,
            east_chrom    => chrom_1_1,
            west_fitness  => fit_1_4,
            west_chrom    => chrom_1_4,
            fitness       => fit_1_0,
            chromosome    => chrom_1_0
        );

    cell_1_1: entity work.cell
        generic map (
            CELL_SEED => x"B5100FA1"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_1,
            north_chrom   => chrom_0_1,
            south_fitness => fit_2_1,
            south_chrom   => chrom_2_1,
            east_fitness  => fit_1_2,
            east_chrom    => chrom_1_2,
            west_fitness  => fit_1_0,
            west_chrom    => chrom_1_0,
            fitness       => fit_1_1,
            chromosome    => chrom_1_1
        );

    cell_1_2: entity work.cell
        generic map (
            CELL_SEED => x"73EE161F"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_2,
            north_chrom   => chrom_0_2,
            south_fitness => fit_2_2,
            south_chrom   => chrom_2_2,
            east_fitness  => fit_1_3,
            east_chrom    => chrom_1_3,
            west_fitness  => fit_1_1,
            west_chrom    => chrom_1_1,
            fitness       => fit_1_2,
            chromosome    => chrom_1_2
        );

    cell_1_3: entity work.cell
        generic map (
            CELL_SEED => x"88BA42D3"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_3,
            north_chrom   => chrom_0_3,
            south_fitness => fit_2_3,
            south_chrom   => chrom_2_3,
            east_fitness  => fit_1_4,
            east_chrom    => chrom_1_4,
            west_fitness  => fit_1_2,
            west_chrom    => chrom_1_2,
            fitness       => fit_1_3,
            chromosome    => chrom_1_3
        );

    cell_1_4: entity work.cell
        generic map (
            CELL_SEED => x"3AE727CB"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_4,
            north_chrom   => chrom_0_4,
            south_fitness => fit_2_4,
            south_chrom   => chrom_2_4,
            east_fitness  => fit_1_0,
            east_chrom    => chrom_1_0,
            west_fitness  => fit_1_3,
            west_chrom    => chrom_1_3,
            fitness       => fit_1_4,
            chromosome    => chrom_1_4
        );

    cell_2_0: entity work.cell
        generic map (
            CELL_SEED => x"B5B15509"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_0,
            north_chrom   => chrom_1_0,
            south_fitness => fit_3_0,
            south_chrom   => chrom_3_0,
            east_fitness  => fit_2_1,
            east_chrom    => chrom_2_1,
            west_fitness  => fit_2_4,
            west_chrom    => chrom_2_4,
            fitness       => fit_2_0,
            chromosome    => chrom_2_0
        );

    cell_2_1: entity work.cell
        generic map (
            CELL_SEED => x"0384E37C"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_1,
            north_chrom   => chrom_1_1,
            south_fitness => fit_3_1,
            south_chrom   => chrom_3_1,
            east_fitness  => fit_2_2,
            east_chrom    => chrom_2_2,
            west_fitness  => fit_2_0,
            west_chrom    => chrom_2_0,
            fitness       => fit_2_1,
            chromosome    => chrom_2_1
        );

    cell_2_2: entity work.cell
        generic map (
            CELL_SEED => x"9F95F2F8"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_2,
            north_chrom   => chrom_1_2,
            south_fitness => fit_3_2,
            south_chrom   => chrom_3_2,
            east_fitness  => fit_2_3,
            east_chrom    => chrom_2_3,
            west_fitness  => fit_2_1,
            west_chrom    => chrom_2_1,
            fitness       => fit_2_2,
            chromosome    => chrom_2_2
        );

    cell_2_3: entity work.cell
        generic map (
            CELL_SEED => x"0FB711E1"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_3,
            north_chrom   => chrom_1_3,
            south_fitness => fit_3_3,
            south_chrom   => chrom_3_3,
            east_fitness  => fit_2_4,
            east_chrom    => chrom_2_4,
            west_fitness  => fit_2_2,
            west_chrom    => chrom_2_2,
            fitness       => fit_2_3,
            chromosome    => chrom_2_3
        );

    cell_2_4: entity work.cell
        generic map (
            CELL_SEED => x"89C0182F"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_4,
            north_chrom   => chrom_1_4,
            south_fitness => fit_3_4,
            south_chrom   => chrom_3_4,
            east_fitness  => fit_2_0,
            east_chrom    => chrom_2_0,
            west_fitness  => fit_2_3,
            west_chrom    => chrom_2_3,
            fitness       => fit_2_4,
            chromosome    => chrom_2_4
        );

    cell_3_0: entity work.cell
        generic map (
            CELL_SEED => x"6C5B9189"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_0,
            north_chrom   => chrom_2_0,
            south_fitness => fit_4_0,
            south_chrom   => chrom_4_0,
            east_fitness  => fit_3_1,
            east_chrom    => chrom_3_1,
            west_fitness  => fit_3_4,
            west_chrom    => chrom_3_4,
            fitness       => fit_3_0,
            chromosome    => chrom_3_0
        );

    cell_3_1: entity work.cell
        generic map (
            CELL_SEED => x"87AD1167"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_1,
            north_chrom   => chrom_2_1,
            south_fitness => fit_4_1,
            south_chrom   => chrom_4_1,
            east_fitness  => fit_3_2,
            east_chrom    => chrom_3_2,
            west_fitness  => fit_3_0,
            west_chrom    => chrom_3_0,
            fitness       => fit_3_1,
            chromosome    => chrom_3_1
        );

    cell_3_2: entity work.cell
        generic map (
            CELL_SEED => x"32BA9E16"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_2,
            north_chrom   => chrom_2_2,
            south_fitness => fit_4_2,
            south_chrom   => chrom_4_2,
            east_fitness  => fit_3_3,
            east_chrom    => chrom_3_3,
            west_fitness  => fit_3_1,
            west_chrom    => chrom_3_1,
            fitness       => fit_3_2,
            chromosome    => chrom_3_2
        );

    cell_3_3: entity work.cell
        generic map (
            CELL_SEED => x"F41502BA"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_3,
            north_chrom   => chrom_2_3,
            south_fitness => fit_4_3,
            south_chrom   => chrom_4_3,
            east_fitness  => fit_3_4,
            east_chrom    => chrom_3_4,
            west_fitness  => fit_3_2,
            west_chrom    => chrom_3_2,
            fitness       => fit_3_3,
            chromosome    => chrom_3_3
        );

    cell_3_4: entity work.cell
        generic map (
            CELL_SEED => x"C8C170A7"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_4,
            north_chrom   => chrom_2_4,
            south_fitness => fit_4_4,
            south_chrom   => chrom_4_4,
            east_fitness  => fit_3_0,
            east_chrom    => chrom_3_0,
            west_fitness  => fit_3_3,
            west_chrom    => chrom_3_3,
            fitness       => fit_3_4,
            chromosome    => chrom_3_4
        );

    cell_4_0: entity work.cell
        generic map (
            CELL_SEED => x"0CBB2C16"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_0,
            north_chrom   => chrom_3_0,
            south_fitness => fit_0_0,
            south_chrom   => chrom_0_0,
            east_fitness  => fit_4_1,
            east_chrom    => chrom_4_1,
            west_fitness  => fit_4_4,
            west_chrom    => chrom_4_4,
            fitness       => fit_4_0,
            chromosome    => chrom_4_0
        );

    cell_4_1: entity work.cell
        generic map (
            CELL_SEED => x"8FA887C6"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_1,
            north_chrom   => chrom_3_1,
            south_fitness => fit_0_1,
            south_chrom   => chrom_0_1,
            east_fitness  => fit_4_2,
            east_chrom    => chrom_4_2,
            west_fitness  => fit_4_0,
            west_chrom    => chrom_4_0,
            fitness       => fit_4_1,
            chromosome    => chrom_4_1
        );

    cell_4_2: entity work.cell
        generic map (
            CELL_SEED => x"2C9153CF"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_2,
            north_chrom   => chrom_3_2,
            south_fitness => fit_0_2,
            south_chrom   => chrom_0_2,
            east_fitness  => fit_4_3,
            east_chrom    => chrom_4_3,
            west_fitness  => fit_4_1,
            west_chrom    => chrom_4_1,
            fitness       => fit_4_2,
            chromosome    => chrom_4_2
        );

    cell_4_3: entity work.cell
        generic map (
            CELL_SEED => x"8639BD95"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_3,
            north_chrom   => chrom_3_3,
            south_fitness => fit_0_3,
            south_chrom   => chrom_0_3,
            east_fitness  => fit_4_4,
            east_chrom    => chrom_4_4,
            west_fitness  => fit_4_2,
            west_chrom    => chrom_4_2,
            fitness       => fit_4_3,
            chromosome    => chrom_4_3
        );

    cell_4_4: entity work.cell
        generic map (
            CELL_SEED => x"DF937442"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_4,
            north_chrom   => chrom_3_4,
            south_fitness => fit_0_4,
            south_chrom   => chrom_0_4,
            east_fitness  => fit_4_0,
            east_chrom    => chrom_4_0,
            west_fitness  => fit_4_3,
            west_chrom    => chrom_4_3,
            fitness       => fit_4_4,
            chromosome    => chrom_4_4
        );



    process (CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            top_lfsr <= top_lfsr(30 downto 0) & (top_lfsr(31) xor top_lfsr(21) xor top_lfsr(1) xor top_lfsr(0));
            mut_prob_reg <= mut_prob_reg(1 downto 0) & top_lfsr(31);

            if reset_clean = '1' then
                state <= S_IDLE;
                en_init <= '0';
                en_crossover <= '0';
                en_mutation <= '0';
                uart_start <= '0';
                wait_cnt <= 0;
                tx_idx <= 0;
                cycle_counter <= (others => '0');
                is_computing <= '0';
            else
                en_init <= '0';
                en_crossover <= '0';
                en_mutation <= '0';
                uart_start <= '0';

                if is_computing = '1' then
                    cycle_counter <= cycle_counter + 1;
                end if;

                case state is
                    when S_IDLE =>
                        if start_clean = '1' then
                            cycle_counter <= (others => '0');
                            is_computing <= '1';
                            state <= S_INIT;
                        end if;

                    when S_INIT =>
                        en_init <= '1';
                        wait_cnt <= 0;
                        state <= S_WAIT_INIT;

                    when S_WAIT_INIT =>
                        if wait_cnt = 2 then
                            state <= S_CROSS;
                        else
                            wait_cnt <= wait_cnt + 1;
                        end if;

                    when S_CROSS =>
                        en_crossover <= '1';
                        wait_cnt <= 0;
                        state <= S_WAIT_CROSS;

                    when S_WAIT_CROSS =>
                        if wait_cnt = 6 then
                            if fit_0_0 = "000000" then
                                tx_idx <= 0;
                                is_computing <= '0';
                                state <= S_DONE;
                            else
                                if mut_prob_reg = "000" then
                                    state <= S_MUTATE;
                                else
                                    state <= S_CROSS;
                                end if;
                            end if;
                        else
                            wait_cnt <= wait_cnt + 1;
                        end if;

                    when S_MUTATE =>
                        en_mutation <= '1';
                        wait_cnt <= 0;
                        state <= S_WAIT_MUT;

                    when S_WAIT_MUT =>
                        if wait_cnt = 2 then
                            if fit_0_0 = "000000" then
                                tx_idx <= 0;
                                is_computing <= '0';
                                state <= S_DONE;
                            else
                                state <= S_CROSS;
                            end if;
                        else
                            wait_cnt <= wait_cnt + 1;
                        end if;

                    when S_DONE =>
                        if uart_ready = '1' then
                            state <= S_TX_LOAD;
                        end if;

                    when S_TX_LOAD =>

                        if tx_idx < 10 then
                            uart_data <= "0000" & std_logic_vector(chrom_0_0(tx_idx));
                        elsif tx_idx = 10 then
                            uart_data <= std_logic_vector(cycle_counter(31 downto 24));
                        elsif tx_idx = 10 + 1 then
                            uart_data <= std_logic_vector(cycle_counter(23 downto 16));
                        elsif tx_idx = 10 + 2 then
                            uart_data <= std_logic_vector(cycle_counter(15 downto 8));
                        else
                            uart_data <= std_logic_vector(cycle_counter(7 downto 0));
                        end if;

                        uart_start <= '1';
                        state <= S_TX_ACK;

                    when S_TX_ACK =>
                        if uart_ready = '0' then
                            state <= S_TX_WAIT;
                        end if;

                    when S_TX_WAIT =>
                        if uart_ready = '1' then
                            if tx_idx = 10 + 3 then
                                state <= S_IDLE;
                            else
                                tx_idx <= tx_idx + 1;
                                state <= S_TX_LOAD;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

    LED <= std_logic_vector(fit_0_0);

end Behavioral;
