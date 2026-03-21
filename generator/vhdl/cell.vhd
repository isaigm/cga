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

          north_fitness : in unsigned(6-1 downto 0);
          north_chrom   : in queen_chrom_t;
          south_fitness : in unsigned(6-1 downto 0);
          south_chrom   : in queen_chrom_t;
          east_fitness  : in unsigned(6-1 downto 0);
          east_chrom    : in queen_chrom_t;
          west_fitness  : in unsigned(6-1 downto 0);
          west_chrom    : in queen_chrom_t;

          fitness       : out unsigned(6-1 downto 0);
          chromosome    : out queen_chrom_t
    );
end cell;

architecture Behavioral of cell is

    signal r_chromosome        : queen_chrom_t := (others => (others => '0'));
    signal s_fitness           : unsigned(6-1 downto 0) := "111111";

    signal reg_north_chrom, reg_south_chrom, reg_east_chrom, reg_west_chrom : queen_chrom_t := (others => (others => '0'));
    signal reg_north_fit, reg_south_fit, reg_east_fit, reg_west_fit         : unsigned(6-1 downto 0) := "111111";

    signal child_chrom         : queen_chrom_t;
    signal reg_child_chrom     : queen_chrom_t := (others => (others => '0'));
    signal child_fitness       : unsigned(6-1 downto 0);

    signal semi1_fit, semi2_fit, best_neighbor_fit, comb_best_parent_fit : unsigned(6-1 downto 0);
    signal semi1_chrom, semi2_chrom, best_neighbor_chrom, comb_best_parent_chrom : queen_chrom_t;

    signal reg_best_parent_chrom : queen_chrom_t := (others => (others => '0'));

    signal lfsr_reg              : std_logic_vector(63 downto 0) := x"ACE1ACE1" & CELL_SEED;
    signal reg_lfsr_mask         : std_logic_vector(N_QUEENS-1 downto 0) := (others => '0');

    signal reg_child_attacks     : std_logic_vector(45-1 downto 0) := (others => '0');

    type op_mode_type is (OP_IDLE, OP_INIT, OP_CROSS_LATCH_MASK, OP_CROSS_LATCH_CHILD, OP_CROSS_CALC_ATTACKS, OP_CROSS_WAIT_EVAL, OP_CROSS_EVAL, OP_MUT);
    signal current_op : op_mode_type := OP_IDLE;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg_north_fit <= "111111";
                reg_south_fit <= "111111";
                reg_east_fit  <= "111111";
                reg_west_fit  <= "111111";
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
        for i in 0 to 45 - 1 loop
            if reg_child_attacks(i) = '1' then
                cnt := cnt + 1;
            end if;
        end loop;

        for i in 0 to N_QUEENS - 1 loop
            if reg_child_chrom(i) >= N_QUEENS then
                cnt := cnt + 5;
            end if;
        end loop;

        if cnt > 63 then
            cnt := 63;
        end if;

        child_fitness <= to_unsigned(cnt, 6);
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
                s_fitness             <= "111111";
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
                    s_fitness <= "111111";

                    current_op <= OP_IDLE;
                end if;
            end if;
        end if;
    end process;

    chromosome <= r_chromosome;
    fitness <= s_fitness;

end Behavioral;
