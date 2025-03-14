///|
pub(all) type Re @js.Value

///|
pub extern "js" fn Re::new(s : String, flags~ : String = "") -> Re = "(s, flags) => new RegExp(s, flags)"

///|
pub extern "js" fn Re::match_(self : Re, s : String) -> Array[String] = "(pat, s) => s.match(pat) ?? []"

///|
pub extern "js" fn Re::match_all(self : Re, s : String) -> Array[Array[String]] = "(pat, s) => [...s.matchAll(pat)]"

///|
pub extern "js" fn Re::split(self : Re, s : String) -> Array[String] = "(pat, s) => s.split(pat)"

///|
pub extern "js" fn Re::replace_all(
  self : Re,
  s : String,
  to_s : String
) -> String = "(pat, s, to_s) => s.replaceAll(pat, to_s)"

///|
pub extern "js" fn Re::test_(self : Re, s : String) -> Bool = "(pat, s) => pat.test(s)"
