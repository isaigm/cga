use rand::{RngExt};
use std::time::Instant; 

const N_QUEENS: usize = 10;
const ROWS: usize = 5;
const COLS: usize = 6;
const MAX_FITNESS: u32 = 63;
const MAX_RUNS: u32 = 30;

#[derive(Clone, Copy)]
struct Cell {
    chromosome: [u8; N_QUEENS],
    fitness: u32,
}

impl Cell {
    fn new() -> Self {
        Cell {
            chromosome: [0; N_QUEENS],
            fitness: MAX_FITNESS,
        }
    }
}

fn calculate_fitness(chrom: &[u8; N_QUEENS]) -> u32 {
    let mut attacks = 0;

    for i in 0..N_QUEENS {
        if chrom[i] >= N_QUEENS as u8 {
            attacks += 5;
        }
    }

    for i in 0..N_QUEENS {
        for j in (i + 1)..N_QUEENS {
            if chrom[i] == chrom[j] {
                attacks += 1;
            } else {
                let diff_row = (chrom[i] as i32 - chrom[j] as i32).abs();
                let diff_col = (i as i32 - j as i32).abs();
                if diff_row == diff_col {
                    attacks += 1;
                }
            }
        }
    }

    if attacks > MAX_FITNESS {
        MAX_FITNESS
    } else {
        attacks
    }
}

fn compare_cells(cell_a: &Cell, cell_b: &Cell) -> Cell {
    if cell_a.fitness <= cell_b.fitness {
        *cell_a
    } else {
        *cell_b
    }
}

fn main() {
    let mut rng = rand::rng();

    for _ in 0..MAX_RUNS {
        let mut grid = vec![vec![Cell::new(); COLS]; ROWS];

        for r in 0..ROWS {
            for c in 0..COLS {
                for i in 0..N_QUEENS {
                    grid[r][c].chromosome[i] = rng.random_range(0..N_QUEENS as u8);
                }
                grid[r][c].fitness = calculate_fitness(&grid[r][c].chromosome);
            }
        }

        let mut generations = 0;
        let mut solution: Option<[u8; N_QUEENS]> = None;

        let start_time = Instant::now();

        loop {
            let mut any_done = false;
            for r in 0..ROWS {
                for c in 0..COLS {
                    if grid[r][c].fitness == 0 {
                        any_done = true;
                        solution = Some(grid[r][c].chromosome);
                        break;
                    }
                }
                if any_done { break; }
            }

            if any_done {
                break;
            }

            generations += 1;
            let mut next_grid = grid.clone();
            let is_mutation_cycle = rng.random_range(0..8) == 0;

            for r in 0..ROWS {
                for c in 0..COLS {
                    if is_mutation_cycle {
                        let mut child_chrom = grid[r][c].chromosome;
                        let mut_idx = rng.random_range(0..N_QUEENS);
                        let mut_val = rng.random_range(0..N_QUEENS as u8);
                        child_chrom[mut_idx] = mut_val;

                        next_grid[r][c].chromosome = child_chrom;
                        next_grid[r][c].fitness = calculate_fitness(&child_chrom);
                    } else {
                        let n = if r == 0 { ROWS - 1 } else { r - 1 };
                        let s = if r == ROWS - 1 { 0 } else { r + 1 };
                        let w = if c == 0 { COLS - 1 } else { c - 1 };
                        let e = if c == COLS - 1 { 0 } else { c + 1 };

                        let north = grid[n][c];
                        let south = grid[s][c];
                        let east  = grid[r][e];
                        let west  = grid[r][w];

                        let semi1 = compare_cells(&north, &south);
                        let semi2 = compare_cells(&east, &west);
                        let best_neighbor = compare_cells(&semi1, &semi2);
                        let best_parent = compare_cells(&grid[r][c], &best_neighbor);

                        let mut child_chrom = [0; N_QUEENS];
                        let mask: u16 = rng.random();

                        for i in 0..N_QUEENS {
                            if (mask & (1 << i)) != 0 {
                                child_chrom[i] = best_parent.chromosome[i];
                            } else {
                                child_chrom[i] = grid[r][c].chromosome[i];
                            }
                        }

                        let child_fitness = calculate_fitness(&child_chrom);

                        if child_fitness <= grid[r][c].fitness {
                            next_grid[r][c].chromosome = child_chrom;
                            next_grid[r][c].fitness = child_fitness;
                        } else {
                            next_grid[r][c] = grid[r][c];
                        }
                    }
                }
            }
            grid = next_grid;
        }

        let elapsed_time = start_time.elapsed();

        if let Some(sol) = solution {
            let hardware_cycles_approx = generations * 7;
            println!(
                "Solution found: {:?} in {} generations (approx {} HW cycles) | Time: {:?}",
                sol, generations, hardware_cycles_approx, elapsed_time
            );
        }
    }
}