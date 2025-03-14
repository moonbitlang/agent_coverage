///|
pub extern "js" fn pid() -> Int =
  #|() => require("process").pid

///|
pub extern "js" fn hostname() -> String =
  #|require("os").hostname

///|
pub extern "js" fn timestamp() -> Int =
  #| Date.now

///|
pub fn rand() -> @random.Rand {
  let base_bytes = @buffer.new(size_hint=32)
  b"ABCDEFGHIJKLMNOPQRSTUVWXYZ12"
  .iter()
  .concat(timestamp().to_be_bytes().iter())
  .each(fn(b) { base_bytes.write_byte(b) })
  @random.new(seed=base_bytes.to_bytes())
}
