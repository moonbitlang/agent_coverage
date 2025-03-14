///|
test "offset_into" {
  inspect!(offset_into("hello\nworld", 1, 1), content="0")
  inspect!(offset_into("hello\nworld", 2, 1), content="6")
  inspect!(offset_into("hello\nworld", 2, 6), content="11")
}

///|
test "panic offset_into/line_zero" {
  ignore(offset_into("hello\nworld", 0, 1))
}

///|
test "panic offset_into/column_zero" {
  ignore(offset_into("hello\nworld", 1, 0))
}

///|
test "panic offset_into/both_zero" {
  ignore(offset_into("hello\nworld", 0, 0))
}

///|
test {
  let s = "hello world"
  let t = "goodbye"
  inspect!(replace_section(s, t, start=0, end=5), content="goodbye world")
}

///|
test "split_lines/unix" {
  inspect!(
    split_lines("hello\nworld\ngoodbye").to_array(),
    content=
      #|["hello", "world", "goodbye"]
    ,
  )
  inspect!(
    split_lines("hello\r\nworld\r\ngoodbye").to_array(),
    content=
      #|["hello", "world", "goodbye"]
    ,
  )
  inspect!(
    split_lines("hello\r\nworld\r\ngoodbye\n").to_array(),
    content=
      #|["hello", "world", "goodbye"]
    ,
  )

  // Empty string
  inspect!(
    split_lines("").to_array(),
    content=
      #|[""]
    ,
  )
  // Single line without newline
  inspect!(split_lines("hello").to_array(), content="[\"hello\"]")
  // Single line with newline
  inspect!(split_lines("hello\n").to_array(), content="[\"hello\"]")
  // Single line with CRLF
  inspect!(split_lines("hello\r\n").to_array(), content="[\"hello\"]")
}
