///|
pub struct ExpectFailure {
  filename : String
  index : String
  message : ExpectFailureMessage
  package : String
  test_name : String
} derive(Show, FromJson, ToJson)

///|
pub struct ExpectFailureMessage {
  actual : String
  args_loc : Array[@text.JsonOption[String]]
  expect : String
  loc : String
} derive(Show, FromJson, ToJson)

///|
pub type! TestError {
  CompileError(
    code~ : String,
    exit_state~ : Int?,
    stderr~ : String,
    stdout~ : String
  )
  ExpectError(code~ : String, expect_failures~ : Array[ExpectFailure])
  RuntimeError(
    code~ : String,
    exit_state~ : Int?,
    stderr~ : String,
    stdout~ : String
  )
} derive(Show, ToJson)

///|
pub struct TestOk {
  delta_coverage_data : @mbt.CoverallsData?
}

///|
pub typealias TestResult = Result[TestOk, TestError]
