// Rust highlight sample for tree-sitter-rust

#![allow(dead_code)]

use std::collections::HashMap;
use std::fmt::{self, Display};

const APP_NAME: &str = "rust-syntax-demo";
const MAX_RETRY: u32 = 3;

#[derive(Debug, Clone, PartialEq, Eq)]
enum State {
    Queued,
    Running,
    Done,
    Failed,
}

#[derive(Debug, Clone)]
struct Job {
    id: u64,
    name: String,
    state: State,
    tags: Vec<String>,
}

impl Display for Job {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Job#{}:{} ({:?})", self.id, self.name, self.state)
    }
}

trait Runner {
    fn run(&mut self) -> Result<(), String>;
}

impl Runner for Job {
    fn run(&mut self) -> Result<(), String> {
        self.state = State::Running;

        for _ in 0..MAX_RETRY {
            if self.name.is_empty() {
                self.state = State::Failed;
                return Err("name is empty".to_string());
            }
        }

        self.state = State::Done;
        Ok(())
    }
}

fn classify(value: Option<i32>) -> &'static str {
    match value {
        Some(v) if v > 0 => "positive",
        Some(0) => "zero",
        Some(_) => "negative",
        None => "none",
    }
}

fn parse_pairs(input: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();

    for line in input.lines() {
        if let Some((k, v)) = line.split_once('=') {
            map.insert(k.trim().to_string(), v.trim().to_string());
        }
    }

    map
}

fn main() {
    let mut job = Job {
        id: 1,
        name: String::from("alpha"),
        state: State::Queued,
        tags: vec!["demo".into(), "rust".into()],
    };

    let raw = r#"line1\nline2\t(raw string)"#;
    let escaped = "hello\\nworld\\t\"quoted\"";
    let c = 'r';
    let n = 42_u32;
    let f = 3.14_f64;
    let active = true;

    let input = "name = rust\nlang = rs";
    let pairs = parse_pairs(input);

    println!("{}", APP_NAME);
    println!("{} {:?} {:?}", raw, escaped, job.tags);
    println!("{} {} {} {}", c, n, f, active);
    println!("classify={}", classify(Some(-1)));

    match job.run() {
        Ok(()) => println!("run ok: {}", job),
        Err(e) => eprintln!("run failed: {}", e),
    }

    for (k, v) in &pairs {
        println!("{}={}", k, v);
    }
}
