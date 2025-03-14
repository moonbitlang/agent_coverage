///|
extern "js" fn env_ffi() -> @js.Value = "() => process.env"

///|
pub fn env(key : String) -> String? {
  let got : @js.Value = env_ffi().get_with_string(key)
  guard not(got.is_undefined()) else { None }
  got.cast()
}
