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

        let mut gas_values: Vec<i32> = Vec::new();

        for line in lines {
            if let Ok(ip) = line {
                gas_values.push(ip.parse::<i32>().unwrap());
            }
        }

        gas_values.sort();

        let mut contents = gas_values
            .iter()
            .map(|i| i.to_string())
            .collect::<Vec<String>>()
            .join(",");

        contents = "[".to_owned()+&contents+"]";
        let _result = fs::write("data.json", contents);
        
    }
}
