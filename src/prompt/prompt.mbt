///|
let template_path = "src/prompt"

///|
priv extern type HandleBars

///|
pub(all) type HandleBarsTemplate (@js.Object) -> String

///|
fn HandleBars::new() -> HandleBars {
  @js.require("handleBars").cast()
}

///|
let hbs : HandleBars = HandleBars::new()

///|
fn HandleBars::compile(
  self : HandleBars,
  template : String
) -> HandleBarsTemplate {
  @js.Value::cast_from(self).apply_with_string("compile", [template])
}

///|
pub fn HandleBarsTemplate::render!(
  self : HandleBarsTemplate,
  data : Json
) -> String {
  (self._)(@js.Object::from_value_unchecked(@json.from_json!(data)))
}

///|
pub let coverage_template : HandleBarsTemplate = hbs.compile(
  @fs.read_file_to_string?(template_path + "/coverage.hbs").unwrap(),
)

///|
pub let gen_tests_template : HandleBarsTemplate = hbs.compile(
  @fs.read_file_to_string?(template_path + "/gen_tests.hbs").unwrap(),
)

///|
pub let fix_tests_template : HandleBarsTemplate = hbs.compile(
  @fs.read_file_to_string?(template_path + "/fix_tests.hbs").unwrap(),
)

///|
pub const UNCOVERED_MARKER = "[UNCOVERED]"

///|
pub let coverage : String = coverage_template
  .render?({ "uncoveredMarker": UNCOVERED_MARKER.to_json() })
  .unwrap()

///|
pub let patch : String = @fs.read_file_to_string?(template_path + "/patch.md").unwrap()

///|
pub let syntax : String = @fs.read_file_to_string?(template_path + "/syntax.md").unwrap()

///|
pub let system_header : String = @fs.read_file_to_string?(
  template_path + "/system_header.md",
).unwrap()

///|
pub let system : String = system_header + syntax + coverage + patch
