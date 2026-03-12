library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.n_queens_types.all;

entity cell_comparator is
    Port (
        fit_a     : in unsigned(6-1 downto 0);
        chrom_a   : in queen_chrom_t;
        fit_b     : in unsigned(6-1 downto 0);
        chrom_b   : in queen_chrom_t;
        fit_out   : out unsigned(6-1 downto 0);
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
