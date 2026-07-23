use serde::{Deserialize, Serialize};
use std::io::{self, BufRead, Write};

#[derive(Debug, Deserialize)]
struct Request {
    id: u64,

    language: String,
    mode: String,
    code: String,

    #[serde(default)]
    cursor_line: usize,

    #[serde(default)]
    start_line: usize,

    #[serde(default)]
    end_line: usize,
}

#[derive(Debug, Serialize)]
struct Observation {
    line: usize,
    kind: String,
    text: String,
}

#[derive(Debug, Serialize)]
struct Response {
    id: u64,

    success: bool,
    observations: Vec<Observation>,
    error: Option<String>,
}

fn main() {
    let stdin = io::stdin();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(line) => line,
            Err(_) => continue,
        };

        let request: Request = match serde_json::from_str(&line) {
            Ok(req) => req,

            Err(err) => {
                let response = Response {
                    id: 0,
                    success: false,
                    observations: vec![],
                    error: Some(format!("invalid json: {}", err)),
                };

                println!("{}", serde_json::to_string(&response).unwrap());
                io::stdout().flush().unwrap();

                continue;
            }
        };

        let observation_line = match request.mode.as_str() {
            "line" => request.cursor_line,

            "selection" => request.end_line,

            "buffer" => request.start_line,

            _ => 0,
        };

        let response = Response {
            id: request.id,

            success: true,

            observations: vec![Observation {
                line: observation_line,

                kind: "info".to_string(),

                text: format!("evaluated {} bytes", request.code.len()),
            }],

            error: None,
        };

        println!("{}", serde_json::to_string(&response).unwrap());

        io::stdout().flush().unwrap();
    }
}
