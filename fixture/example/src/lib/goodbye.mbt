///|
fn no() -> Bool {
  false
}

///|
pub fn goodbye(with_suffix~ : Bool = no()) -> String {
  let goodbye = "Goodbye"
  guard with_suffix else { goodbye }
  goodbye + ", cruel world!"
}
