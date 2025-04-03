///|
test "extract_code_from_raw_resp" {
  inspect!(
    extract_code_from_raw_resp(
      "Some header:\n```moonbit\nfn main() {\n  println(\"Hello, world!\")\n}\n```\n... some footer",
    ),
    content=
      #|
      #|fn main() {
      #|  println("Hello, world!")
      #|}
      #|
    ,
  )
  inspect!(
    extract_code_from_raw_resp(
      "Some header:\n```moonbit\nfn main() {\n  println(\"Hello, world!\")\n}",
    ),
    content=
      #|
      #|fn main() {
      #|  println("Hello, world!")
      #|}
    ,
  )
  inspect!(
    extract_code_from_raw_resp("\nfn main() {\n  println(\"Hello, world!\")\n}"),
    content=
      #|
      #|fn main() {
      #|  println("Hello, world!")
      #|}
    ,
  )
  let raw =
    #|Based on the task and the provided interfaces, I'll write test cases to cover the uncovered lines (line 17) in the excerpt. Here's my solution:
    #|
    #|```moonbit
    #|test "hash_tuple2" {
    #|  let hasher = Hasher::new()
    #|  let t = (123, "abc")
    #|  hasher..combine(t)
    #|  inspect!(hasher.finalize(), content="546135774")
    #|}
    #|```
    #|
    #|This test case triggers line 17 by:
    #|
    #|1. Creating a tuple containing two hashable values (Int and String)
    #|2. Creating a hasher with a well-defined seed
    #|3. Using the cascade operator (`..`) to call the `combine` method on the tuple
    #|4. Finalizing the hasher to get a deterministic hash value
    #|5. Using `inspect!` to verify the hash value is consistent
    #|
    #|This test ensures that the `Hash` implementation for tuples is working correctly by verifying that the hash value remains consistent across different runs.
    #|
    #|Note that we don't need to directly test `hash_combine` since it's implicitly tested through the `Hash::combine` trait method.
  inspect!(
    extract_code_from_raw_resp(raw),
    content=
      #|
      #|test "hash_tuple2" {
      #|  let hasher = Hasher::new()
      #|  let t = (123, "abc")
      #|  hasher..combine(t)
      #|  inspect!(hasher.finalize(), content="546135774")
      #|}
      #|
    ,
  )
}

///|
test "fix ExpectError" {
  let e = ExpectError(
    code=
      #|test "to_ascii_lower uppercase to lowercase" {
      #|  inspect!(to_ascii_lower('A'), content="'a'")
      #|  inspect!(to_ascii_lower('Z'))
      #|  inspect!(to_ascii_lower('M'), content="'W'")
      #|}
    ,
    expect_failures=[
      {
        filename: "ascii_test.mbt",
        index: "0",
        message: {
          actual: "'z'",
          args_loc: [
            Some("/path/to/my/code/cmark/src/char/ascii_test.mbt:3:12-3:31"),
            None,
            None,
            None,
          ],
          expect: "",
          loc: "/path/to/my/code/cmark/src/char/ascii_test.mbt:3:3-3:32",
        },
        pkg: "rami3l/cmark/char",
        test_name: "to_ascii_lower uppercase to lowercase",
      },
      {
        filename: "ascii_test.mbt",
        index: "0",
        message: {
          actual: "'m'",
          args_loc: [
            Some("/path/to/my/code/cmark/src/char/ascii_test.mbt:4:12-4:31"),
            Some("/path/to/my/code/cmark/src/char/ascii_test.mbt:4:41-4:46"),
            None,
            None,
          ],
          expect: "'W'",
          loc: "/path/to/my/code/cmark/src/char/ascii_test.mbt:4:3-4:47",
        },
        pkg: "rami3l/cmark/char",
        test_name: "to_ascii_lower uppercase to lowercase",
      },
    ],
  )
  inspect!(
    fix_expect_error!(e),
    content=
      #|test "to_ascii_lower uppercase to lowercase" {
      #|  inspect!(to_ascii_lower('A'), content="'a'")
      #|  inspect!(to_ascii_lower('Z'), content="'z'")
      #|  inspect!(to_ascii_lower('M'), content="'m'")
      #|}
    ,
  )
}

///|
test "fix ExpectError with multiline string" {
  let e = ExpectError(
    code=
      #|test {
      #|  inspect!(
      #|    "hello" + "\n\n" + "  world",
      #|    content=
      #|      #|hello
      #|      #| baz
      #|    ,
      #|  )
      #|}
    ,
    expect_failures=[
      {
        filename: "ascii_test.mbt",
        index: "0",
        message: {
          actual: "hello\n\n  world",
          args_loc: [
            Some("/path/to/my/code/cmark/src/char/ascii_test.mbt:3:5-3:33"),
            Some("/path/to/my/code/cmark/src/char/ascii_test.mbt:5:7-6:13"),
            None,
            None,
          ],
          expect: "hello\n baz",
          loc: "/path/to/my/code/cmark/src/char/ascii_test.mbt:4:3-4:47",
        },
        pkg: "rami3l/cmark/char",
        test_name: "0",
      },
    ],
  )
  inspect!(
    fix_expect_error!(e),
    content=
      #|test {
      #|  inspect!(
      #|    "hello" + "\n\n" + "  world",
      #|    content=
      #|      "hello\n\n  world"
      #|    ,
      #|  )
      #|}
    ,
  )
}

///|
test "extract_jsons_from_test_stdout" {
  let null = Null
  let stdout =
    #|{"package":"rami3l/cmark/char","filename":"ascii_test.mbt","index":"0","test_name":"to_ascii_lower uppercase to lowercase","message":"@EXPECT_FAILED {\"loc\": \"/path/to/my/code/cmark/src/char/ascii_test.mbt:4:3-4:47\", \"args_loc\": \"[\\\"/path/to/my/code/cmark/src/char/ascii_test.mbt:4:12-4:31\\\", \\\"/path/to/my/code/cmark/src/char/ascii_test.mbt:4:41-4:46\\\", null, null]\", \"expect\": \"'M'\", \"actual\": \"'m'\"}"}
    #|expect test failed at /path/to/my/code/cmark/src/char/ascii_test.mbt:4:3-4:47
    #|Diff:
    #|----
    #|'Mm'
    #|----
    #|
    #|{"package":"rami3l/cmark/char","filename":"ascii_test.mbt","index":"1","test_name":"to_ascii_upper: convert lowercase to uppercase","message":"@EXPECT_FAILED {\"loc\": \"/path/to/my/code/cmark/src/char/ascii_test.mbt:9:3-9:47\", \"args_loc\": \"[\\\"/path/to/my/code/cmark/src/char/ascii_test.mbt:9:12-9:31\\\", \\\"/path/to/my/code/cmark/src/char/ascii_test.mbt:9:41-9:46\\\", null, null]\", \"expect\": \"'G'\", \"actual\": \"'Z'\"}"}
    #|expect test failed at /path/to/my/code/cmark/src/char/ascii_test.mbt:9:3-9:47
    #|Diff:
    #|----
    #|'GZ'
    #|----
  @json.inspect!(extract_jsons_from_test_stdout(stdout), content=[
    {
      "filename": "ascii_test.mbt",
      "index": "0",
      "message": {
        "actual": "'m'",
        "args_loc": [
          "/path/to/my/code/cmark/src/char/ascii_test.mbt:4:12-4:31", "/path/to/my/code/cmark/src/char/ascii_test.mbt:4:41-4:46",
          null, null,
        ],
        "expect": "'M'",
        "loc": "/path/to/my/code/cmark/src/char/ascii_test.mbt:4:3-4:47",
      },
      "package": "rami3l/cmark/char",
      "test_name": "to_ascii_lower uppercase to lowercase",
    },
    {
      "filename": "ascii_test.mbt",
      "index": "1",
      "message": {
        "actual": "'Z'",
        "args_loc": [
          "/path/to/my/code/cmark/src/char/ascii_test.mbt:9:12-9:31", "/path/to/my/code/cmark/src/char/ascii_test.mbt:9:41-9:46",
          null, null,
        ],
        "expect": "'G'",
        "loc": "/path/to/my/code/cmark/src/char/ascii_test.mbt:9:3-9:47",
      },
      "package": "rami3l/cmark/char",
      "test_name": "to_ascii_upper: convert lowercase to uppercase",
    },
  ])
}

///|
test "extract_jsons_from_test_stdout line not JSON" {
  let null = Null
  let stdout =
    #|{"package":"rami3l/cmark/cmark_base","filename":"agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt","index":"0","test_name":"html_block_start_7_open_tag with tag followed by non-blank","message":"@EXPECT_FAILED {\"loc\": \"/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:3-3:42\", \"args_loc\": \"[\\\"/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:12-3:13\\\", \\\"/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:23-3:41\\\", null, null]\", \"expect\": \"\\\"<custom>text\\\"\", \"actual\": \"<custom>text\"}"}
    #|expect test failed at /Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:3-3:42
    #|Diff:
    #|----
    #|"<custom>text"
    #|----
  @json.inspect!(extract_jsons_from_test_stdout(stdout), content=[
    {
      "filename": "agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt",
      "index": "0",
      "message": {
        "actual": "<custom>text",
        "args_loc": [
          "/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:12-3:13",
          "/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:23-3:41",
          null, null,
        ],
        "expect": "\"<custom>text\"",
        "loc": "/Users/rami3l/Documents/Code/marbit/src/cmark_base/agent_coverage_cmark_cmark_base_xqsCRd_patch_test.mbt:3:3-3:42",
      },
      "package": "rami3l/cmark/cmark_base",
      "test_name": "html_block_start_7_open_tag with tag followed by non-blank",
    },
  ])
}
