///|
pub extern "js" fn home_dir() -> String = "() => require('os').homedir()"

///|
pub extern "js" fn temp_dir() -> String = "() => require('os').tmpdir()"
