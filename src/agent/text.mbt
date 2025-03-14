///|
fn fix_expect_error!(e : TestError) -> String {
  guard e is ExpectError(code~, expect_failures=expectFailures)
  let mut code = code
  for f in expectFailures {
    match f.message.args_loc[1]._ { // `content=` should always be the second argument.
      Some(content_arg_loc_str) => {
        // inspect!(arg0, content=arg1)
        guard {
            guard @jsext.Re::new(
                #|:(\d+):(\d+)-(\d+):(\d+)
                ,
              ).match_(content_arg_loc_str)
              is [_, .. fields]
            let acc = []
            for f in fields {
              acc.push(@strconv.parse_int!(f))
            }
            acc
          }
          is [ln, col, ln1, col1]
        let start = @text.offset_into(code, ln, col)
        let end = @text.offset_into(code, ln1, col1)
        let arg1 = f.message.actual
        code = @text.replace_section(
          code,
          moonbit_string_repr(arg1),
          start~,
          end~,
        )
      }
      None => {
        // inspect!(arg0)
        // In this case, we should directly append the second argument to the first one.
        guard {
            guard @jsext.Re::new(
                #|:(\d+):(\d+)-(\d+):(\d+)
                ,
              ).match_(f.message.args_loc[0]._.unwrap())
              is [_, .. fields]
            let acc = []
            for f in fields {
              acc.push(@strconv.parse_int!(f))
            }
            acc
          }
          is [ln, col, ln1, col1]
        let start = @text.offset_into(code, ln, col)
        let end = @text.offset_into(code, ln1, col1)
        let arg0 = code.substring(start~, end~)
        let arg1 = f.message.actual
        code = @text.replace_section(
          code,
          "\{arg0}, content=\{moonbit_string_repr(arg1)}",
          start~,
          end~,
        )
      }
    }
  }
  code
}

///|
fn moonbit_string_repr(s : String) -> String {
  @json.stringify(s.to_json())
}

///|
fn extract_code_from_raw_resp(raw_resp : String) -> String {
  let start_pat = "```moonbit"
  let mut start = raw_resp.index_of(start_pat)
  guard start >= 0 else { raw_resp }
  start += start_pat.length()
  let raw_resp = raw_resp.substring(start~)
  let end_pat = "```"
  guard raw_resp.index_of(end_pat) is end && end >= 0 else { raw_resp }
  raw_resp.substring(end~)
}

///|
pub type! JsonCustomParseError String

///|
fn extract_jsons_from_test_stdout(stdout : String) -> Array[ExpectFailure] {
  let res = []
  for ln in @text.split_lines(stdout) {
    try {
      // Try to parse the current line as JSON
      guard @json.parse!(ln) is Object(partial) else { continue }
      guard partial.get("message") is Some(message_text) else {
        raise JsonCustomParseError(
          "invalid `ExpectFailure`: the `message` field is missing",
        )
      }
      guard message_text.as_string() is Some(message_text) else {
        raise JsonCustomParseError(
          "invalid `ExpectFailure`: the `message` field is not a string",
        )
      }
      let prefix = "@EXPECT_FAILED "
      assert_true?(message_text.starts_with(prefix)).unwrap()
      guard @json.parse!(message_text.substring(start=prefix.length()))
        is Object(partial_message)
      let message = partial_message..set(
        "args_loc",
        @json.parse!(partial_message["args_loc"].unwrap().as_string().unwrap()),
      )
      let full = partial..set("message", Object(message))
      res.push(@json.from_json!(Object(full)))
    } catch {
      // TODO: Do we have any kind of error that we don't want to handle?
      e => {
        @log.g().trace("\{e}")
        continue
      }
    }
  }
  res
}
