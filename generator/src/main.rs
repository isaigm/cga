use rand::{Rng, RngExt};
use std::fs::{self, File};
use std::io::{Write, Result};
use indoc::formatdoc;

const ROWS: i32 = 5;
const COLS: i32 = 5;
const N_QUEENS: i32 = 10;
const W_QUEENS: i32 = 4;
const W_FITNESS: i32 = 6;

fn main() -> Result<()> {
    fs::create_dir_all("vhdl")?;

    generate_types_file()?;
    generate_comparator_file()?;
    generate_cell_file()?;
    generate_cga_file(ROWS, COLS)?;

    Ok(())
}

fn generate_types_file() -> Result<()> {
    let mut file = File::create("vhdl/n_queens_types.vhd")?;
    let content = formatdoc! {r#"
        library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        use IEEE.NUMERIC_STD.ALL;

        package n_queens_types is
            constant N_QUEENS : integer := {n};
            constant W_QUEENS : integer := {w};

            type queen_chrom_t is array (0 to N_QUEENS-1) of unsigned(W_QUEENS-1 downto 0);
        end package n_queens_types;
    "#, n = N_QUEENS, w = W_QUEENS};
    file.write_all(content.as_bytes())
}

fn generate_comparator_file() -> Result<()> {
    let mut file = File::create("vhdl/cell_comparator.vhd")?;
    let content = formatdoc! {r#"
        library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        use IEEE.NUMERIC_STD.ALL;
        use work.n_queens_types.all;

        entity cell_comparator is
            Port (
                fit_a     : in unsigned({w_fit}-1 downto 0);
                chrom_a   : in queen_chrom_t;
                fit_b     : in unsigned({w_fit}-1 downto 0);
                chrom_b   : in queen_chrom_t;
                fit_out   : out unsigned({w_fit}-1 downto 0);
                chrom_out : out queen_chrom_t
            );
        end cell_comparator;

        architecture Behavioral of cell_comparator is
        begin
            process(fit_a, chrom_a, fit_b, chrom_b)
            begin
                if fit_a <= fit_b then
                    fit_out   <= fit_a;
                    chrom_out <= chrom_a;
                else
                    fit_out   <= fit_b;
                    chrom_out <= chrom_b;
                end if;
            end process;
        end Behavioral;
    "#, w_fit = W_FITNESS};
    file.write_all(content.as_bytes())
}

fn generate_cell_file() -> Result<()> {
    let mut file = File::create("vhdl/cell.vhd")?;

    let worst_fitness = "1".repeat(W_FITNESS as usize);
    let max_attacks = (N_QUEENS * (N_QUEENS - 1)) / 2;
    let max_fit_val = (1 << W_FITNESS) - 1;

    let content = formatdoc! {r#"
        library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        use IEEE.NUMERIC_STD.ALL;
        use work.n_queens_types.all;

        entity cell is
            generic (
                CELL_SEED : std_logic_vector(31 downto 0) := x"12345678"
            );
            Port (
                  clk           : in std_logic;
                  reset         : in std_logic;

                  en_init       : in std_logic;
                  en_crossover  : in std_logic;
                  en_mutation   : in std_logic;

                  north_fitness : in unsigned({w_fit}-1 downto 0);
                  north_chrom   : in queen_chrom_t;
                  south_fitness : in unsigned({w_fit}-1 downto 0);
                  south_chrom   : in queen_chrom_t;
                  east_fitness  : in unsigned({w_fit}-1 downto 0);
                  east_chrom    : in queen_chrom_t;
                  west_fitness  : in unsigned({w_fit}-1 downto 0);
                  west_chrom    : in queen_chrom_t;

                  fitness       : out unsigned({w_fit}-1 downto 0);
                  chromosome    : out queen_chrom_t
            );
        end cell;

        architecture Behavioral of cell is

            signal r_chromosome        : queen_chrom_t := (others => (others => '0'));
            signal s_fitness           : unsigned({w_fit}-1 downto 0) := "{worst_fit}";

            signal reg_north_chrom, reg_south_chrom, reg_east_chrom, reg_west_chrom : queen_chrom_t := (others => (others => '0'));
            signal reg_north_fit, reg_south_fit, reg_east_fit, reg_west_fit         : unsigned({w_fit}-1 downto 0) := "{worst_fit}";

            signal child_chrom         : queen_chrom_t;
            signal reg_child_chrom     : queen_chrom_t := (others => (others => '0'));
            signal child_fitness       : unsigned({w_fit}-1 downto 0);

            signal semi1_fit, semi2_fit, best_neighbor_fit, comb_best_parent_fit : unsigned({w_fit}-1 downto 0);
            signal semi1_chrom, semi2_chrom, best_neighbor_chrom, comb_best_parent_chrom : queen_chrom_t;

            signal reg_best_parent_chrom : queen_chrom_t := (others => (others => '0'));

            signal lfsr_reg              : std_logic_vector(63 downto 0) := x"ACE1ACE1" & CELL_SEED;
            signal reg_lfsr_mask         : std_logic_vector(N_QUEENS-1 downto 0) := (others => '0');

            signal reg_child_attacks     : std_logic_vector({max_att}-1 downto 0) := (others => '0');

            type op_mode_type is (OP_IDLE, OP_INIT, OP_CROSS_LATCH_MASK, OP_CROSS_LATCH_CHILD, OP_CROSS_CALC_ATTACKS, OP_CROSS_WAIT_EVAL, OP_CROSS_EVAL, OP_MUT);
            signal current_op : op_mode_type := OP_IDLE;

        begin

            process(clk)
            begin
                if rising_edge(clk) then
                    if reset = '1' then
                        reg_north_fit <= "{worst_fit}";
                        reg_south_fit <= "{worst_fit}";
                        reg_east_fit  <= "{worst_fit}";
                        reg_west_fit  <= "{worst_fit}";
                    else
                        reg_north_chrom <= north_chrom;
                        reg_north_fit   <= north_fitness;
                        reg_south_chrom <= south_chrom;
                        reg_south_fit   <= south_fitness;
                        reg_east_chrom  <= east_chrom;
                        reg_east_fit    <= east_fitness;
                        reg_west_chrom  <= west_chrom;
                        reg_west_fit    <= west_fitness;
                    end if;
                end if;
            end process;

            NS_comp: entity work.cell_comparator port map (fit_a => reg_north_fit, chrom_a => reg_north_chrom, fit_b => reg_south_fit, chrom_b => reg_south_chrom, fit_out => semi1_fit, chrom_out => semi1_chrom);
            EW_comp: entity work.cell_comparator port map (fit_a => reg_east_fit, chrom_a => reg_east_chrom, fit_b => reg_west_fit, chrom_b => reg_west_chrom, fit_out => semi2_fit, chrom_out => semi2_chrom);
            final_neighbor_comp: entity work.cell_comparator port map (fit_a => semi1_fit, chrom_a => semi1_chrom, fit_b => semi2_fit, chrom_b => semi2_chrom, fit_out => best_neighbor_fit, chrom_out => best_neighbor_chrom);
            elitism_comp: entity work.cell_comparator port map (fit_a => s_fitness, chrom_a => r_chromosome, fit_b => best_neighbor_fit, chrom_b => best_neighbor_chrom, fit_out => comb_best_parent_fit, chrom_out => comb_best_parent_chrom);

            process(r_chromosome, reg_best_parent_chrom, reg_lfsr_mask)
            begin
                for i in 0 to N_QUEENS - 1 loop
                    if reg_lfsr_mask(i) = '1' then
                        child_chrom(i) <= reg_best_parent_chrom(i);
                    else
                        child_chrom(i) <= r_chromosome(i);
                    end if;
                end loop;
            end process;

             process (reg_child_attacks, reg_child_chrom)
                variable cnt: natural;
            begin
                cnt := 0;
                for i in 0 to {max_att} - 1 loop
                    if reg_child_attacks(i) = '1' then
                        cnt := cnt + 1;
                    end if;
                end loop;

                for i in 0 to N_QUEENS - 1 loop
                    if reg_child_chrom(i) >= N_QUEENS then
                        cnt := cnt + 5;
                    end if;
                end loop;

                if cnt > {max_val} then
                    cnt := {max_val};
                end if;

                child_fitness <= to_unsigned(cnt, {w_fit});
            end process;

            process (clk)
                variable mult_idx     : unsigned(31 downto 0);
                variable mult_val     : unsigned(31 downto 0);
                variable mutation_idx : integer;
                variable mutation_val : unsigned(W_QUEENS-1 downto 0);
                variable temp_val     : unsigned(W_QUEENS-1 downto 0);
                variable attack_idx   : integer;
            begin
                if rising_edge(clk) then

                    lfsr_reg <= lfsr_reg(62 downto 0) & (lfsr_reg(63) xor lfsr_reg(62) xor lfsr_reg(60) xor lfsr_reg(59));

                    if reset = '1' then
                        r_chromosome          <= (others => (others => '0'));
                        s_fitness             <= "{worst_fit}";
                        reg_best_parent_chrom <= (others => (others => '0'));
                        reg_lfsr_mask         <= (others => '0');
                        reg_child_attacks     <= (others => '0');
                        reg_child_chrom       <= (others => (others => '0'));
                        current_op            <= OP_IDLE;
                        lfsr_reg              <= x"ACE1ACE1" & CELL_SEED;
                    else
                        if current_op = OP_IDLE then
                            if en_init = '1' then current_op <= OP_INIT;
                            elsif en_crossover = '1' then current_op <= OP_CROSS_LATCH_MASK;
                            elsif en_mutation = '1' then current_op <= OP_MUT;
                            end if;
                        end if;

                        if current_op = OP_INIT then
                            for i in 0 to N_QUEENS - 1 loop
                                temp_val := unsigned(lfsr_reg(i*W_QUEENS + W_QUEENS - 1 downto i*W_QUEENS));
                                if temp_val >= N_QUEENS then
                                    temp_val := temp_val - to_unsigned(N_QUEENS, W_QUEENS);
                                end if;
                                r_chromosome(i) <= temp_val;
                            end loop;
                            current_op <= OP_IDLE;
                        end if;

                        if current_op = OP_CROSS_LATCH_MASK then
                            reg_best_parent_chrom <= comb_best_parent_chrom;
                            reg_lfsr_mask         <= lfsr_reg(N_QUEENS-1 downto 0);
                            current_op            <= OP_CROSS_LATCH_CHILD;
                        end if;

                        if current_op = OP_CROSS_LATCH_CHILD then
                            reg_child_chrom <= child_chrom;
                            current_op <= OP_CROSS_CALC_ATTACKS;
                        end if;

                        if current_op = OP_CROSS_CALC_ATTACKS then
                            attack_idx := 0;
                            for i in 0 to N_QUEENS - 1 loop
                                for j in i + 1 to N_QUEENS - 1 loop
                                    if (reg_child_chrom(i) = reg_child_chrom(j)) or
                                       (resize(reg_child_chrom(i), W_QUEENS + 1) + to_unsigned(j - i, W_QUEENS + 1) = resize(reg_child_chrom(j), W_QUEENS + 1)) or
                                       (resize(reg_child_chrom(j), W_QUEENS + 1) + to_unsigned(j - i, W_QUEENS + 1) = resize(reg_child_chrom(i), W_QUEENS + 1)) then
                                        reg_child_attacks(attack_idx) <= '1';
                                    else
                                        reg_child_attacks(attack_idx) <= '0';
                                    end if;
                                    attack_idx := attack_idx + 1;
                                end loop;
                            end loop;

                            current_op <= OP_CROSS_WAIT_EVAL;
                        end if;

                        if current_op = OP_CROSS_WAIT_EVAL then
                            current_op <= OP_CROSS_EVAL;
                        end if;

                        if current_op = OP_CROSS_EVAL then
                            if child_fitness <= s_fitness then
                                r_chromosome <= reg_child_chrom;
                                s_fitness    <= child_fitness;
                            end if;
                            current_op <= OP_IDLE;
                        end if;

                        if current_op = OP_MUT then
                            mult_idx := unsigned(lfsr_reg(15 downto 0)) * to_unsigned(N_QUEENS, 16);
                            mult_val := unsigned(lfsr_reg(31 downto 16)) * to_unsigned(N_QUEENS, 16);

                            mutation_idx := to_integer(mult_idx(31 downto 16));
                            temp_val     := resize(mult_val(31 downto 16), W_QUEENS);

                            if temp_val >= N_QUEENS then
                                temp_val := temp_val - to_unsigned(N_QUEENS, W_QUEENS);
                            end if;

                            r_chromosome(mutation_idx) <= temp_val;
                            s_fitness <= "{worst_fit}";

                            current_op <= OP_IDLE;
                        end if;
                    end if;
                end if;
            end process;

            chromosome <= r_chromosome;
            fitness <= s_fitness;

        end Behavioral;
    "#,
    w_fit = W_FITNESS,
    worst_fit = worst_fitness,
    max_att = max_attacks,
    max_val = max_fit_val
    };

    file.write_all(content.as_bytes())
}


fn generate_cga_file(rows: i32, cols: i32) -> Result<()> {
    let mut file = File::create("vhdl/cga.vhd")?;
    let mut rng = rand::rng();

    let mut signals = String::new();
    for r in 0..rows {
        for c in 0..cols {
            signals.push_str(&format!("    signal fit_{}_{} : unsigned({}-1 downto 0);\n", r, c, W_FITNESS));
            signals.push_str(&format!("    signal chrom_{}_{} : queen_chrom_t;\n", r, c));
        }
    }

    let mut instances = String::new();
    for r in 0..rows {
        for c in 0..cols {
            let n = if r == 0 { rows - 1 } else { r - 1 };
            let s = if r == rows - 1 { 0 } else { r + 1 };
            let w = if c == 0 { cols - 1 } else { c - 1 };
            let e = if c == cols - 1 { 0 } else { c + 1 };
            let seed: u32 = rng.random_range(0..=u32::MAX);

            instances.push_str(&format!(
                "    cell_{r}_{c}: entity work.cell\n        generic map (\n            CELL_SEED => x\"{seed:08X}\"\n        )\n        port map (\n            clk => CLK100MHZ,\n            reset => reset_clean,\n            en_init => en_init,\n            en_crossover => en_crossover,\n            en_mutation => en_mutation,\n            north_fitness => fit_{n}_{c},\n            north_chrom   => chrom_{n}_{c},\n            south_fitness => fit_{s}_{c},\n            south_chrom   => chrom_{s}_{c},\n            east_fitness  => fit_{r}_{e},\n            east_chrom    => chrom_{r}_{e},\n            west_fitness  => fit_{r}_{w},\n            west_chrom    => chrom_{r}_{w},\n            fitness       => fit_{r}_{c},\n            chromosome    => chrom_{r}_{c}\n        );\n\n",
                r=r, c=c, n=n, s=s, e=e, w=w, seed=seed
            ));
        }
    }

    let padding_zeros = "0".repeat((8 - W_QUEENS) as usize);
    let perfect_fitness = "0".repeat(W_FITNESS as usize);

    let content = formatdoc! {r#"
        library IEEE;
        use IEEE.STD_LOGIC_1164.ALL;
        use IEEE.NUMERIC_STD.ALL;
        use work.n_queens_types.all;

        entity cga is
            Port (
                CLK100MHZ : in std_logic;
                btnR      : in std_logic;
                btnL      : in std_logic;
                LED       : out std_logic_vector({w_fit}-1 downto 0);
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

            signal tx_idx     : integer range 0 to {n_queens} + 3 := 0;

            signal cycle_counter : unsigned(31 downto 0) := (others => '0');
            signal is_computing  : std_logic := '0';

        {signals}

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

        {instances}

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
                                    if fit_0_0 = "{perf_fit}" then
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
                                    if fit_0_0 = "{perf_fit}" then
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

                                if tx_idx < {n_queens} then
                                    uart_data <= "{pad}" & std_logic_vector(chrom_0_0(tx_idx));
                                elsif tx_idx = {n_queens} then
                                    uart_data <= std_logic_vector(cycle_counter(31 downto 24));
                                elsif tx_idx = {n_queens} + 1 then
                                    uart_data <= std_logic_vector(cycle_counter(23 downto 16));
                                elsif tx_idx = {n_queens} + 2 then
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
                                    if tx_idx = {n_queens} + 3 then
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
    "#,
    signals = signals,
    instances = instances,
    w_fit = W_FITNESS,
    perf_fit = perfect_fitness,
    pad = padding_zeros,
    n_queens = N_QUEENS
    };

    file.write_all(content.as_bytes())?;
    Ok(())
}
