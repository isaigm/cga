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

    signal any_done      : std_logic;
    signal winning_chrom : queen_chrom_t;

    signal fit_0_0 : unsigned(6-1 downto 0);
    signal chrom_0_0 : queen_chrom_t;
    signal done_0_0 : std_logic;
    signal fit_0_1 : unsigned(6-1 downto 0);
    signal chrom_0_1 : queen_chrom_t;
    signal done_0_1 : std_logic;
    signal fit_0_2 : unsigned(6-1 downto 0);
    signal chrom_0_2 : queen_chrom_t;
    signal done_0_2 : std_logic;
    signal fit_0_3 : unsigned(6-1 downto 0);
    signal chrom_0_3 : queen_chrom_t;
    signal done_0_3 : std_logic;
    signal fit_0_4 : unsigned(6-1 downto 0);
    signal chrom_0_4 : queen_chrom_t;
    signal done_0_4 : std_logic;
    signal fit_0_5 : unsigned(6-1 downto 0);
    signal chrom_0_5 : queen_chrom_t;
    signal done_0_5 : std_logic;
    signal fit_1_0 : unsigned(6-1 downto 0);
    signal chrom_1_0 : queen_chrom_t;
    signal done_1_0 : std_logic;
    signal fit_1_1 : unsigned(6-1 downto 0);
    signal chrom_1_1 : queen_chrom_t;
    signal done_1_1 : std_logic;
    signal fit_1_2 : unsigned(6-1 downto 0);
    signal chrom_1_2 : queen_chrom_t;
    signal done_1_2 : std_logic;
    signal fit_1_3 : unsigned(6-1 downto 0);
    signal chrom_1_3 : queen_chrom_t;
    signal done_1_3 : std_logic;
    signal fit_1_4 : unsigned(6-1 downto 0);
    signal chrom_1_4 : queen_chrom_t;
    signal done_1_4 : std_logic;
    signal fit_1_5 : unsigned(6-1 downto 0);
    signal chrom_1_5 : queen_chrom_t;
    signal done_1_5 : std_logic;
    signal fit_2_0 : unsigned(6-1 downto 0);
    signal chrom_2_0 : queen_chrom_t;
    signal done_2_0 : std_logic;
    signal fit_2_1 : unsigned(6-1 downto 0);
    signal chrom_2_1 : queen_chrom_t;
    signal done_2_1 : std_logic;
    signal fit_2_2 : unsigned(6-1 downto 0);
    signal chrom_2_2 : queen_chrom_t;
    signal done_2_2 : std_logic;
    signal fit_2_3 : unsigned(6-1 downto 0);
    signal chrom_2_3 : queen_chrom_t;
    signal done_2_3 : std_logic;
    signal fit_2_4 : unsigned(6-1 downto 0);
    signal chrom_2_4 : queen_chrom_t;
    signal done_2_4 : std_logic;
    signal fit_2_5 : unsigned(6-1 downto 0);
    signal chrom_2_5 : queen_chrom_t;
    signal done_2_5 : std_logic;
    signal fit_3_0 : unsigned(6-1 downto 0);
    signal chrom_3_0 : queen_chrom_t;
    signal done_3_0 : std_logic;
    signal fit_3_1 : unsigned(6-1 downto 0);
    signal chrom_3_1 : queen_chrom_t;
    signal done_3_1 : std_logic;
    signal fit_3_2 : unsigned(6-1 downto 0);
    signal chrom_3_2 : queen_chrom_t;
    signal done_3_2 : std_logic;
    signal fit_3_3 : unsigned(6-1 downto 0);
    signal chrom_3_3 : queen_chrom_t;
    signal done_3_3 : std_logic;
    signal fit_3_4 : unsigned(6-1 downto 0);
    signal chrom_3_4 : queen_chrom_t;
    signal done_3_4 : std_logic;
    signal fit_3_5 : unsigned(6-1 downto 0);
    signal chrom_3_5 : queen_chrom_t;
    signal done_3_5 : std_logic;
    signal fit_4_0 : unsigned(6-1 downto 0);
    signal chrom_4_0 : queen_chrom_t;
    signal done_4_0 : std_logic;
    signal fit_4_1 : unsigned(6-1 downto 0);
    signal chrom_4_1 : queen_chrom_t;
    signal done_4_1 : std_logic;
    signal fit_4_2 : unsigned(6-1 downto 0);
    signal chrom_4_2 : queen_chrom_t;
    signal done_4_2 : std_logic;
    signal fit_4_3 : unsigned(6-1 downto 0);
    signal chrom_4_3 : queen_chrom_t;
    signal done_4_3 : std_logic;
    signal fit_4_4 : unsigned(6-1 downto 0);
    signal chrom_4_4 : queen_chrom_t;
    signal done_4_4 : std_logic;
    signal fit_4_5 : unsigned(6-1 downto 0);
    signal chrom_4_5 : queen_chrom_t;
    signal done_4_5 : std_logic;


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
            CELL_SEED => x"116A8EBB"
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
            west_fitness  => fit_0_5,
            west_chrom    => chrom_0_5,
            fitness       => fit_0_0,
            chromosome    => chrom_0_0
        );

    done_0_0 <= '1' when fit_0_0 = "000000" else '0';

    cell_0_1: entity work.cell
        generic map (
            CELL_SEED => x"B046805B"
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

    done_0_1 <= '1' when fit_0_1 = "000000" else '0';

    cell_0_2: entity work.cell
        generic map (
            CELL_SEED => x"5A6B257D"
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

    done_0_2 <= '1' when fit_0_2 = "000000" else '0';

    cell_0_3: entity work.cell
        generic map (
            CELL_SEED => x"90068E7C"
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

    done_0_3 <= '1' when fit_0_3 = "000000" else '0';

    cell_0_4: entity work.cell
        generic map (
            CELL_SEED => x"CBF9013F"
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
            east_fitness  => fit_0_5,
            east_chrom    => chrom_0_5,
            west_fitness  => fit_0_3,
            west_chrom    => chrom_0_3,
            fitness       => fit_0_4,
            chromosome    => chrom_0_4
        );

    done_0_4 <= '1' when fit_0_4 = "000000" else '0';

    cell_0_5: entity work.cell
        generic map (
            CELL_SEED => x"590508CB"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_4_5,
            north_chrom   => chrom_4_5,
            south_fitness => fit_1_5,
            south_chrom   => chrom_1_5,
            east_fitness  => fit_0_0,
            east_chrom    => chrom_0_0,
            west_fitness  => fit_0_4,
            west_chrom    => chrom_0_4,
            fitness       => fit_0_5,
            chromosome    => chrom_0_5
        );

    done_0_5 <= '1' when fit_0_5 = "000000" else '0';

    cell_1_0: entity work.cell
        generic map (
            CELL_SEED => x"1DF450ED"
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
            west_fitness  => fit_1_5,
            west_chrom    => chrom_1_5,
            fitness       => fit_1_0,
            chromosome    => chrom_1_0
        );

    done_1_0 <= '1' when fit_1_0 = "000000" else '0';

    cell_1_1: entity work.cell
        generic map (
            CELL_SEED => x"66507AB8"
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

    done_1_1 <= '1' when fit_1_1 = "000000" else '0';

    cell_1_2: entity work.cell
        generic map (
            CELL_SEED => x"B6FD7196"
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

    done_1_2 <= '1' when fit_1_2 = "000000" else '0';

    cell_1_3: entity work.cell
        generic map (
            CELL_SEED => x"B48113AE"
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

    done_1_3 <= '1' when fit_1_3 = "000000" else '0';

    cell_1_4: entity work.cell
        generic map (
            CELL_SEED => x"0DE0BB4A"
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
            east_fitness  => fit_1_5,
            east_chrom    => chrom_1_5,
            west_fitness  => fit_1_3,
            west_chrom    => chrom_1_3,
            fitness       => fit_1_4,
            chromosome    => chrom_1_4
        );

    done_1_4 <= '1' when fit_1_4 = "000000" else '0';

    cell_1_5: entity work.cell
        generic map (
            CELL_SEED => x"B7425532"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_0_5,
            north_chrom   => chrom_0_5,
            south_fitness => fit_2_5,
            south_chrom   => chrom_2_5,
            east_fitness  => fit_1_0,
            east_chrom    => chrom_1_0,
            west_fitness  => fit_1_4,
            west_chrom    => chrom_1_4,
            fitness       => fit_1_5,
            chromosome    => chrom_1_5
        );

    done_1_5 <= '1' when fit_1_5 = "000000" else '0';

    cell_2_0: entity work.cell
        generic map (
            CELL_SEED => x"78C45B47"
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
            west_fitness  => fit_2_5,
            west_chrom    => chrom_2_5,
            fitness       => fit_2_0,
            chromosome    => chrom_2_0
        );

    done_2_0 <= '1' when fit_2_0 = "000000" else '0';

    cell_2_1: entity work.cell
        generic map (
            CELL_SEED => x"553D7913"
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

    done_2_1 <= '1' when fit_2_1 = "000000" else '0';

    cell_2_2: entity work.cell
        generic map (
            CELL_SEED => x"7216E5A4"
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

    done_2_2 <= '1' when fit_2_2 = "000000" else '0';

    cell_2_3: entity work.cell
        generic map (
            CELL_SEED => x"2B405B7E"
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

    done_2_3 <= '1' when fit_2_3 = "000000" else '0';

    cell_2_4: entity work.cell
        generic map (
            CELL_SEED => x"BEC13AC9"
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
            east_fitness  => fit_2_5,
            east_chrom    => chrom_2_5,
            west_fitness  => fit_2_3,
            west_chrom    => chrom_2_3,
            fitness       => fit_2_4,
            chromosome    => chrom_2_4
        );

    done_2_4 <= '1' when fit_2_4 = "000000" else '0';

    cell_2_5: entity work.cell
        generic map (
            CELL_SEED => x"09447550"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_1_5,
            north_chrom   => chrom_1_5,
            south_fitness => fit_3_5,
            south_chrom   => chrom_3_5,
            east_fitness  => fit_2_0,
            east_chrom    => chrom_2_0,
            west_fitness  => fit_2_4,
            west_chrom    => chrom_2_4,
            fitness       => fit_2_5,
            chromosome    => chrom_2_5
        );

    done_2_5 <= '1' when fit_2_5 = "000000" else '0';

    cell_3_0: entity work.cell
        generic map (
            CELL_SEED => x"E9F06FAB"
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
            west_fitness  => fit_3_5,
            west_chrom    => chrom_3_5,
            fitness       => fit_3_0,
            chromosome    => chrom_3_0
        );

    done_3_0 <= '1' when fit_3_0 = "000000" else '0';

    cell_3_1: entity work.cell
        generic map (
            CELL_SEED => x"CCC620E8"
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

    done_3_1 <= '1' when fit_3_1 = "000000" else '0';

    cell_3_2: entity work.cell
        generic map (
            CELL_SEED => x"5C0FEF87"
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

    done_3_2 <= '1' when fit_3_2 = "000000" else '0';

    cell_3_3: entity work.cell
        generic map (
            CELL_SEED => x"ACA78CFC"
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

    done_3_3 <= '1' when fit_3_3 = "000000" else '0';

    cell_3_4: entity work.cell
        generic map (
            CELL_SEED => x"05DEF839"
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
            east_fitness  => fit_3_5,
            east_chrom    => chrom_3_5,
            west_fitness  => fit_3_3,
            west_chrom    => chrom_3_3,
            fitness       => fit_3_4,
            chromosome    => chrom_3_4
        );

    done_3_4 <= '1' when fit_3_4 = "000000" else '0';

    cell_3_5: entity work.cell
        generic map (
            CELL_SEED => x"C8C34B12"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_2_5,
            north_chrom   => chrom_2_5,
            south_fitness => fit_4_5,
            south_chrom   => chrom_4_5,
            east_fitness  => fit_3_0,
            east_chrom    => chrom_3_0,
            west_fitness  => fit_3_4,
            west_chrom    => chrom_3_4,
            fitness       => fit_3_5,
            chromosome    => chrom_3_5
        );

    done_3_5 <= '1' when fit_3_5 = "000000" else '0';

    cell_4_0: entity work.cell
        generic map (
            CELL_SEED => x"24D4A6F6"
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
            west_fitness  => fit_4_5,
            west_chrom    => chrom_4_5,
            fitness       => fit_4_0,
            chromosome    => chrom_4_0
        );

    done_4_0 <= '1' when fit_4_0 = "000000" else '0';

    cell_4_1: entity work.cell
        generic map (
            CELL_SEED => x"499CB3A5"
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

    done_4_1 <= '1' when fit_4_1 = "000000" else '0';

    cell_4_2: entity work.cell
        generic map (
            CELL_SEED => x"77C593DD"
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

    done_4_2 <= '1' when fit_4_2 = "000000" else '0';

    cell_4_3: entity work.cell
        generic map (
            CELL_SEED => x"9B6F4096"
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

    done_4_3 <= '1' when fit_4_3 = "000000" else '0';

    cell_4_4: entity work.cell
        generic map (
            CELL_SEED => x"AD79EFA9"
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
            east_fitness  => fit_4_5,
            east_chrom    => chrom_4_5,
            west_fitness  => fit_4_3,
            west_chrom    => chrom_4_3,
            fitness       => fit_4_4,
            chromosome    => chrom_4_4
        );

    done_4_4 <= '1' when fit_4_4 = "000000" else '0';

    cell_4_5: entity work.cell
        generic map (
            CELL_SEED => x"ECDCEEA5"
        )
        port map (
            clk => CLK100MHZ,
            reset => reset_clean,
            en_init => en_init,
            en_crossover => en_crossover,
            en_mutation => en_mutation,
            north_fitness => fit_3_5,
            north_chrom   => chrom_3_5,
            south_fitness => fit_0_5,
            south_chrom   => chrom_0_5,
            east_fitness  => fit_4_0,
            east_chrom    => chrom_4_0,
            west_fitness  => fit_4_4,
            west_chrom    => chrom_4_4,
            fitness       => fit_4_5,
            chromosome    => chrom_4_5
        );

    done_4_5 <= '1' when fit_4_5 = "000000" else '0';

    any_done <= done_0_0 or done_0_1 or done_0_2 or done_0_3 or done_0_4 or done_0_5 or done_1_0 or done_1_1 or done_1_2 or done_1_3 or done_1_4 or done_1_5 or done_2_0 or done_2_1 or done_2_2 or done_2_3 or done_2_4 or done_2_5 or done_3_0 or done_3_1 or done_3_2 or done_3_3 or done_3_4 or done_3_5 or done_4_0 or done_4_1 or done_4_2 or done_4_3 or done_4_4 or done_4_5;
    winning_chrom <= chrom_0_0 when done_0_0 = '1' else
                     chrom_0_1 when done_0_1 = '1' else
                     chrom_0_2 when done_0_2 = '1' else
                     chrom_0_3 when done_0_3 = '1' else
                     chrom_0_4 when done_0_4 = '1' else
                     chrom_0_5 when done_0_5 = '1' else
                     chrom_1_0 when done_1_0 = '1' else
                     chrom_1_1 when done_1_1 = '1' else
                     chrom_1_2 when done_1_2 = '1' else
                     chrom_1_3 when done_1_3 = '1' else
                     chrom_1_4 when done_1_4 = '1' else
                     chrom_1_5 when done_1_5 = '1' else
                     chrom_2_0 when done_2_0 = '1' else
                     chrom_2_1 when done_2_1 = '1' else
                     chrom_2_2 when done_2_2 = '1' else
                     chrom_2_3 when done_2_3 = '1' else
                     chrom_2_4 when done_2_4 = '1' else
                     chrom_2_5 when done_2_5 = '1' else
                     chrom_3_0 when done_3_0 = '1' else
                     chrom_3_1 when done_3_1 = '1' else
                     chrom_3_2 when done_3_2 = '1' else
                     chrom_3_3 when done_3_3 = '1' else
                     chrom_3_4 when done_3_4 = '1' else
                     chrom_3_5 when done_3_5 = '1' else
                     chrom_4_0 when done_4_0 = '1' else
                     chrom_4_1 when done_4_1 = '1' else
                     chrom_4_2 when done_4_2 = '1' else
                     chrom_4_3 when done_4_3 = '1' else
                     chrom_4_4 when done_4_4 = '1' else
                     chrom_4_5 when done_4_5 = '1' else
                     (others => (others => '0'));



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
                            -- ¡Freno global! Revisa si cualquier celda terminó
                            if any_done = '1' then
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
                            -- Reevaluación global tras la mutación
                            if any_done = '1' then
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
                            -- Mod N_QUEENS evita el warning de inferencia fuera de rango en el sintetizador
                            uart_data <= "0000" & std_logic_vector(winning_chrom(tx_idx mod 10));
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
