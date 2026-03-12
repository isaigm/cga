use macroquad::prelude::*;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const PORT_NAME: &str = "COM5";
const BAUD_RATE: u32 = 115200;
const BOARD_SIZE: usize = 10;
const MSG_SIZE: usize = BOARD_SIZE + 4;
const CELL_SIZE: f32 = 50.0;

struct Line {
    m: f32,
    x: f32,
    y: f32,
}

impl Line {
    fn new(m: f32, x: f32, y: f32) -> Self {
        Self { m, x, y }
    }
    fn get_y(&self, x: f32) -> f32 {
        self.y + self.m * (x - self.x)
    }
    fn get_x(&self, y: f32) -> f32 {
        (y - self.y) / self.m + self.x
    }
}

fn window_conf() -> Conf {
    Conf {
        window_title: "CGA N-Queens Hardware Accelerator".to_owned(),
        window_width: 800,
        window_height: 600,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    let shared_data: Arc<Mutex<Option<([u8; BOARD_SIZE], u32)>>> = Arc::new(Mutex::new(None));
    let data_clone = Arc::clone(&shared_data);

    thread::spawn(move || {
        println!("Trying connection to {}...", PORT_NAME);

        let mut port = match serialport::new(PORT_NAME, BAUD_RATE)
            .timeout(Duration::from_millis(1000))
            .open()
        {
            Ok(p) => {
                println!("FPGA connected");
                p
            }
            Err(e) => {
                eprintln!("Error when opening the port {}: {}", PORT_NAME, e);
                return;
            }
        };

        let mut buffer: [u8; MSG_SIZE] = [0; MSG_SIZE];

        loop {
            match port.read_exact(&mut buffer) {
                Ok(_) => {
                    let mut board = [0u8; BOARD_SIZE];
                    board.copy_from_slice(&buffer[0..BOARD_SIZE]);

                    if board.iter().all(|&val| val < BOARD_SIZE as u8) {
                        let cycles = u32::from_be_bytes([
                            buffer[BOARD_SIZE],
                            buffer[BOARD_SIZE + 1],
                            buffer[BOARD_SIZE + 2],
                            buffer[BOARD_SIZE + 3],
                        ]);

                        let mut data = data_clone.lock().unwrap();
                        *data = Some((board, cycles));
                        println!("Solution received: {:?} in {} cycles", board, cycles);
                    } else {
                        println!("Solution malformed");
                    }
                }
                Err(ref e) if e.kind() == std::io::ErrorKind::TimedOut => {
                    continue;
                }
                Err(e) => {
                    eprintln!("Error reading UART: {:?}", e);
                    thread::sleep(Duration::from_secs(1));
                }
            }
        }
    });

    loop {
        clear_background(DARKGRAY);

        let offset_x = (screen_width() - (BOARD_SIZE as f32 * CELL_SIZE)) / 2.0;
        let offset_y = (screen_height() - (BOARD_SIZE as f32 * CELL_SIZE)) / 2.0;

        for row in 0..BOARD_SIZE {
            for col in 0..BOARD_SIZE {
                let color = if (row + col) % 2 == 0 {
                    Color::new(0.9, 0.8, 0.7, 1.0)
                } else {
                    Color::new(0.4, 0.2, 0.1, 1.0)
                };

                draw_rectangle(
                    offset_x + col as f32 * CELL_SIZE,
                    offset_y + row as f32 * CELL_SIZE,
                    CELL_SIZE,
                    CELL_SIZE,
                    color,
                );
            }
        }

        let current_data = {
            let data = shared_data.lock().unwrap();
            *data
        };

        if let Some((queens, cycles)) = current_data {
            for col in 0..BOARD_SIZE {
                let row = queens[col] as usize;

                let center_x = offset_x + col as f32 * CELL_SIZE + (CELL_SIZE / 2.0);
                let center_y = offset_y + row as f32 * CELL_SIZE + (CELL_SIZE / 2.0);

                let line_color = Color::new(1.0, 0.0, 0.0, 0.15);
                let thickness = 4.0;
                let board_w = BOARD_SIZE as f32 * CELL_SIZE;

                // Líneas de ataque
                draw_line(offset_x, center_y, offset_x + board_w, center_y, thickness, line_color);
                draw_line(center_x, offset_y, center_x, offset_y + board_w, thickness, line_color);

                let mut line = Line::new(-1.0, center_x, center_y);
                let mut first_inter_x = line.get_x(offset_y);
                let mut first_inter_y = line.get_y(offset_x);
                let mut second_inter_x = line.get_x(offset_y + board_w);
                let mut second_inter_y = line.get_y(offset_x + board_w);
                if first_inter_y > offset_y + board_w {
                    draw_line(second_inter_x, offset_y + board_w, offset_x + board_w, second_inter_y, thickness, line_color);
                } else {
                    draw_line(offset_x, first_inter_y, first_inter_x, offset_y, thickness, line_color);
                }

                line.m = 1.0;
                first_inter_x = line.get_x(offset_y + board_w);
                first_inter_y = line.get_y(offset_x);
                second_inter_x = line.get_x(offset_y);
                second_inter_y = line.get_y(offset_x + board_w);
                if first_inter_y < offset_y {
                    draw_line(second_inter_x, offset_y, offset_x + board_w, second_inter_y, thickness, line_color);
                } else {
                    draw_line(offset_x, first_inter_y, first_inter_x, offset_y + board_w, thickness, line_color);
                }

                // Dibujar reina
                draw_circle(center_x, center_y, CELL_SIZE * 0.35, BLACK);
                draw_circle(center_x, center_y, CELL_SIZE * 0.30, GOLD);
                draw_circle(center_x, center_y, CELL_SIZE * 0.10, BLACK);
            }

            let time_ms = (cycles as f64) / 100_000.0;
            let info_text = format!("Solution  found in {} cycles ({:.3} ms)", cycles, time_ms);
            draw_text(&info_text, 20.0, 30.0, 20.0, GREEN);

        } else {
            draw_text("Waiting for the FPGA (UART)...", 20.0, 30.0, 20.0, YELLOW);
        }

        draw_rectangle_lines(
            offset_x,
            offset_y,
            BOARD_SIZE as f32 * CELL_SIZE,
            BOARD_SIZE as f32 * CELL_SIZE,
            5.0,
            BLACK,
        );

        next_frame().await
    }
}