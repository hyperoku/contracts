use std::fs;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

fn main() {
    if let Ok(lines) = read_lines("./gasValuesAdmitted.txt") {
        let mut contents = String::new();
        // concats all lines (numbers) into one string
        for line in lines {
            contents = contents + &line.unwrap() + ",";
        }
        // removes last ","
        contents.pop();
        // enclose brackets
        contents = "[".to_owned()+&contents+"]";
        let _result = fs::write("data.json", contents);
    }
}
