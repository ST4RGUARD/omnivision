use serde::{Deserialize, Serialize};
use std::io::{self, BufRead, Write};
mod evaluator;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub id: usize,

    pub language: String,
    pub mode: String,
    pub code: String,
    pub filename: String,

    #[serde(default)]
    pub context: String,

    #[serde(default)]
    pub cursor_line: usize,

    #[serde(default)]
    pub start_line: usize,

    #[serde(default)]
    pub end_line: usize,
}

#[derive(Debug, Serialize)]
pub struct Observation {
    pub line: usize,
    pub kind: String,
    pub text: String,
}

#[derive(Debug, Serialize)]
pub struct Response {
    id: usize,
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

        let response = Response {
            id: request.id,
            success: true,
            observations: evaluator::evaluate(&request),
            error: None,
        };

        println!("{}", serde_json::to_string(&response).unwrap());

        io::stdout().flush().unwrap();
    }
}
