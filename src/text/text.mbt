///|
pub fn offset_into(s : String, line : Int, column : Int) -> Int {
  guard line > 0 && column > 0
  let line = line - 1
  let column = column - 1
  let mut chars = 0
  let mut newlines = 0
  for c in s {
    guard newlines < line else { break }
    chars += 1
    if c == '\n' {
      newlines += 1
    }
  }
  chars + column
}

///|
pub fn replace_section(
  s : String,
  t : String,
  start~ : Int,
  end~ : Int
) -> String {
  let head = s.substring(start=0, end=start)
  let tail = s.substring(start=end)
  head + t + tail
}

///|
pub fn split_lines(s : String) -> Iter[String] {
  let len = s.length()
  let s = if s.ends_with("\r\n") {
    s.substring(start=0, end=len - 2)
  } else if s.ends_with("\n") {
    s.substring(start=0, end=len - 1)
  } else {
    s
  }
  // This ensures compatibility with JavaScript's `.split()`.
  guard not(s.is_empty()) else { Iter::singleton("") }
  s.split("\n").map(fn(s) { s.trim_end("\r") })
}
