///|
extern "js" fn require_ffi(path : String) -> @js.Value = "(path) => require(path)"

///|
pub fn require(path : String, keys~ : Array[String] = []) -> @js.Value {
  keys.fold(init=require_ffi(path), fn {
    acc, key => @js.get_with_string(acc, key)
  })
}
