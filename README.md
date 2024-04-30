# Fuzzy

Swift library that provides fuzzy string matching optimized for filenames and code symbols in the style of Sublime Text, VSCode, IntelliJ IDEA et al. This library is external dependency-free. It only depends on the Swift standard library (not Foundation).

This library is a port of [sahilm/fuzzy](https://github.com/sahilm/fuzzy) to Swift.

## Features

- Intuitive matching. Results are returned in descending order of match quality. Quality is determined by:
  - The first character in the pattern matches the first character in the match string.
  - The matched character is camel cased.
  - The matched character follows a separator such as an underscore character.
  - The matched character is adjacent to a previous match.

- Speed. Matches are returned in milliseconds. It's perfect for interactive search boxes.

- The positions of matches are returned. Allows you to highlight matching characters.

## Usage

```swift
import Fuzzy

struct Employee: Fuzzy.SourceElement {
    var name: String
    var age: Int

    /// Add comformance to SourceElement
    var searchRepresentation: [Character] {
        Array(name)
    }
}

let employees = [
    Employee(name: "Alice", age: 45),
    Employee(name: "Bob", age: 35),
    Employee(name: "Allie", age: 35),
]

let results = Fuzzy.find(pattern: "ali", in: employees)
for result in results {
    print(result.value.name)
    // Alice
    // Allie
}
```

