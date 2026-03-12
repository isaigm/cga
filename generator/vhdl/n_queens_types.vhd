library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package n_queens_types is
    constant N_QUEENS : integer := 10;
    constant W_QUEENS : integer := 4;

    type queen_chrom_t is array (0 to N_QUEENS-1) of unsigned(W_QUEENS-1 downto 0);
end package n_queens_types;
