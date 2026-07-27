use std::fs;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::{Observation, Request};

pub fn evaluate(request: &Request) -> Vec<Observation> {
    let contexts = if request.contexts.is_empty() {
        vec![String::new()]
    } else {
        request.contexts.clone()
    };

    let mut last_error = String::new();

    for context in contexts {
        let source = if request.kind == "program" {
            build_source("", request)
        } else {
            build_source(&context, request)
        };

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
            last_error = format!("failed writing temp file: {}", err);
            continue;
        }

        let compile = Command::new("rustc")
            .arg(&source_path)
            .arg("-o")
            .arg(&binary_path)
            .output();

        let compile = match compile {
            Ok(output) => output,
            Err(err) => {
                last_error = format!("rustc failed: {}", err);
                continue;
            }
        };

        if !compile.status.success() {
            last_error = extract_compiler_message(&String::from_utf8_lossy(&compile.stderr));

            let _ = fs::remove_file(&source_path);
            let _ = fs::remove_file(&binary_path);

            if should_expand_context(&last_error) {
                continue;
            }

            break;
        }

        let run = Command::new(&binary_path).output();

        let run = match run {
            Ok(output) => output,
            Err(err) => {
                last_error = format!("execution failed: {}", err);
                continue;
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

        let text = if !stdout.trim().is_empty() {
            let output = stdout.trim();

            if output.contains("--- OMNIVISION RESULT START ---") {
                extract_result(&stdout)
            } else {
                format!("=> {}", output)
            }
        } else {
            "=> executed (no output)".to_string()
        };

        return vec![Observation {
            line: request.cursor_line,
            kind: "result".to_string(),
            text,
        }];
    }

    vec![Observation {
        line: request.cursor_line,
        kind: "error".to_string(),
        text: last_error,
    }]
}

fn build_source(context: &str, request: &Request) -> String {
    match request.kind.as_str() {
        "program" => request.code.clone(),

        "function" => {
            let call = extract_zero_arg_function_call(&request.code);

            match call {
                Some(function_name) => {
                    format!(
                        r#"
{code}

fn main() {{
    println!("--- OMNIVISION RESULT START ---");

    {function_name}();

    println!("--- OMNIVISION RESULT END ---");
}}
"#,
                        code = request.code,
                        function_name = function_name,
                    )
                }

                None => {
                    format!(
                        r#"
{code}

fn main() {{
    println!("--- OMNIVISION RESULT START ---");
    println!("Function requires arguments or could not be called automatically");
    println!("--- OMNIVISION RESULT END ---");
}}
"#,
                        code = request.code,
                    )
                }
            }
        }

        "statement" => {
            format!(
                r#"
fn main() {{
    {context}

    {code}

    println!("--- OMNIVISION EXECUTED ---");
}}
"#,
                context = context,
                code = request.code,
            )
        }

        _ => {
            if context.contains("fn main") {
                format!(
                    r#"
{context}
"#,
                    context = context,
                )
            } else {
                format!(
                    r#"
{context}

fn main() {{
    println!("--- OMNIVISION RESULT START ---");

    {code}

    println!("--- OMNIVISION RESULT END ---");
}}
"#,
                    context = context,
                    code = request.code,
                )
            }
        }
    }
}

fn extract_zero_arg_function_call(code: &str) -> Option<String> {
    for line in code.lines() {
        let line = line.trim();

        if let Some(rest) = line.strip_prefix("fn ") {
            let name = rest.split('(').next()?.trim();

            let args = rest.split('(').nth(1)?.split(')').next()?.trim();

            if args.is_empty() {
                return Some(name.to_string());
            }
        }
    }

    None
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

    if result.is_empty() || result == "()" {
        "=> executed (no output)".to_string()
    } else {
        format!("=> {}", result)
    }
}

fn should_expand_context(error: &str) -> bool {
    error.contains("cannot find value")
        || error.contains("cannot find function")
        || error.contains("cannot find type")
        || error.contains("not found in this scope")
}

fn extract_compiler_message(error: &str) -> String {
    let mut output = Vec::new();

    for line in error.lines() {
        let trimmed = line.trim();

        if trimmed.starts_with("error[") {
            output.push(trimmed.to_string());
        }

        if let Some(index) = trimmed.find("help:") {
            let help = &trimmed[index..];

            output.push(help.to_string());
        }
    }

    if output.is_empty() {
        error.trim().to_string()
    } else {
        output.join("\n")
    }
}
