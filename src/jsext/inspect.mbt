///|
extern "js" fn inspect_ffi(v : @js.Value, opts~ : @js.Object) -> String = "require('node:util').inspect"

///|
pub fn inspect!(v : @js.Value, opts~ : Json = {}) -> String {
  let opts = @js.Object(@json.from_json!(opts))
  inspect_ffi(v, opts~)
}
