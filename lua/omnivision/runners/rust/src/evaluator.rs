use std::fs;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::{Observation, Request};

pub fn evaluate(request: &Request) -> Vec<Observation> {
    let has_value = produces_value(&request.code);

    let source = build_source(request);

    eprintln!("========== GENERATED SOURCE ==========");
    eprintln!("{}", source);
    eprintln!("=====================================");

    let id = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis();

    let dir = std::env::temp_dir();

    let source_path = dir.join(format!("omnivision_{}.rs", id));
    let binary_path = dir.join(format!("omnivision_{}", id));

    if let Err(err) = fs::write(&source_path, source) {
        return vec![Observation {
            line: request.cursor_line,
            kind: "error".to_string(),
            text: format!("failed writing temp file: {}", err),
        }];
    }

    let compile = Command::new("rustc")
        .arg(&source_path)
        .arg("-o")
        .arg(&binary_path)
        .output();

    let compile = match compile {
        Ok(output) => output,
        Err(err) => {
            return vec![Observation {
                line: request.cursor_line,
                kind: "error".to_string(),
                text: format!("rustc failed: {}", err),
            }];
        }
    };

    if !compile.status.success() {
        return vec![Observation {
            line: request.cursor_line,
            kind: "error".to_string(),
            text: String::from_utf8_lossy(&compile.stderr).to_string(),
        }];
    }

    let run = Command::new(&binary_path).output();

    let run = match run {
        Ok(output) => output,
        Err(err) => {
            return vec![Observation {
                line: request.cursor_line,
                kind: "error".to_string(),
                text: format!("execution failed: {}", err),
            }];
        }
    };

    let stdout = String::from_utf8_lossy(&run.stdout).to_string();

    let stderr = String::from_utf8_lossy(&run.stderr).trim().to_string();

    let _ = fs::remove_file(&source_path);
    let _ = fs::remove_file(&binary_path);

    if !stderr.is_empty() {
        return vec![Observation {
            line: request.cursor_line,
            kind: "error".to_string(),
            text: stderr,
        }];
    }

    let text = if has_value {
        extract_result(&stdout)
    } else {
        "=> executed (no output)".to_string()
    };

    vec![Observation {
        line: request.cursor_line,
        kind: "result".to_string(),
        text,
    }]
}

fn produces_value(code: &str) -> bool {
    let trimmed = code.trim();

    !trimmed.ends_with(';')
}

fn build_source(request: &Request) -> String {
    format!(
        r#"
fn main() {{
    {context}

    println!("--- OMNIVISION RESULT START ---");

    let result = {{
        {code}
    }};

    println!("{{:?}}", result);

    println!("--- OMNIVISION RESULT END ---");
}}
"#,
        context = request.context,
        code = request.code,
    )
}

fn extract_result(stdout: &str) -> String {
    let start_marker = "--- OMNIVISION RESULT START ---";
    let end_marker = "--- OMNIVISION RESULT END ---";

    let Some(start) = stdout.find(start_marker) else {
        return "=> (no result)".to_string();
    };

    let output = &stdout[start + start_marker.len()..];

    let Some(end) = output.find(end_marker) else {
        return "=> (no result)".to_string();
    };

    let result = output[..end].trim();

    if result.is_empty() {
        "=> (no result)".to_string()
    } else {
        format!("=> {}", result)
    }
}
