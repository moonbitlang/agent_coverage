///|
pub extern "js" fn join(components : Array[String]) -> String =
  #|(components) => require('node:path').join(...components)

///|
pub extern "js" fn basename(path : String) -> String = "require('node:path').basename"

///|
pub extern "js" fn dirname(path : String) -> String = "require('node:path').dirname"

///|
pub extern "js" fn relative(from : String, to : String) -> String = "require('node:path').relative"

///| Mimics Python's `Path.with_suffix()`: https://stackoverflow.com/a/60139317
pub extern "js" fn with_extension(path : String, extension : String) -> String =
  #|(path_, extension) => {
  #|  const path = require("node:path");
  #|  return path.format({
  #|    ...path.parse(path_),
  #|    base: "",
  #|    ext: "." + extension,
  #|  });
  #|}

///|
pub extern "js" fn with_name(
  path : String,
  name_mapper : (String) -> String
) -> String =
  #|(path_, nameMapper) => {
  #|  const path = require("node:path");
  #|  const oldPath = path.parse(path_);
  #|  return path.format({
  #|    ...oldPath,
  #|    base: "",
  #|    name: nameMapper(oldPath.name),
  #|  });
  #|}

///|
pub extern "js" fn mkdtemp(path : String) -> String =
  #|(path) => require("node:fs").mkdtempSync(path)

///|
test "@path.join" {
  inspect!(join(["a", "b/", "c"]), content="a/b/c")
}

///|
test "@path.basename" {
  inspect!(basename("a/b/c.txt"), content="c.txt")
}

///|
test "@path.dirname" {
  inspect!(dirname("a/b/c.txt"), content="a/b")
}

///|
test "@path.relative" {
  inspect!(relative("a/b/", "a/b/c/d.txt"), content="c/d.txt")
}

///|
test "@path.with_extension" {
  inspect!(with_extension("a/b/c.txt", "rs"), content="a/b/c.rs")
}

///|
test "@path.with_name" {
  inspect!(
    with_name("a/b/c.txt", fn(name) { name + "_new" }),
    content="a/b/c_new.txt",
  )
}
