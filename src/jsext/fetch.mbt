///|
extern "js" fn fetch_ffi(url : String, opts~ : @js.Value) -> @js.Promise = "(url, opts) => fetch(url, opts)"

///|
pub(all) type Response @js.Value

///|
extern "js" fn Response::text_ffi(self : Response) -> @js.Promise = "(self) => self.text()"

///|
pub async fn Response::text(self : Response) -> String! {
  self.text_ffi().wait!!().cast()
}

///|
pub async fn fetch(url : String, opts~ : Json = {}) -> Response! {
  let opts = @js.Value::from_json!(opts)
  fetch_ffi(url, opts~).wait!!().cast()
}
