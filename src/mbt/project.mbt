///|
pub typealias Toplevel = String

///|
pub typealias ToplevelLines = Array[String]

///|
pub let coveralls_json = "coveralls.json"

///|
pub typealias CoverallsFileCoverage = Array[CoverallsLineCoverage]

///|
pub typealias CoverallsLineCoverage = @text.JsonOption[Int]

///|
pub struct CoverallsSourceFile {
  coverage : CoverallsFileCoverage
  name : String
  source_digest : String
} derive(Show, FromJson, ToJson)

///|
pub struct CoverallsJson {
  source_files : Array[CoverallsSourceFile]
} derive(Show, FromJson, ToJson)

///|
pub struct MoonModJSON {
  name : String
  source : String?
} derive(Show, FromJson, ToJson)

///|
pub struct MoonPkgJSON {
  import_ : Array[String]?
  test_import : Array[String]?
  test_import_all : Bool?
} derive (
  Show,
  FromJson(rename_fields="kebab-case", fields(import_(rename="import"))),
  ToJson(rename_fields="kebab-case", fields(import_(rename="import"))),
)

///|
pub struct CoverallsData {
  source_files : Map[String, CoverallsFileCoverage]
} derive(Show, FromJson, ToJson)

///|
pub fn CoverallsData::new(
  src_files? : Map[String, CoverallsFileCoverage]
) -> CoverallsData {
  { source_files: src_files.or_else(fn() { Map::new() }) }
}

///|
pub fn CoverallsData::from_raw(data : CoverallsJson) -> CoverallsData {
  {
    source_files: Map::from_iter(
      data.source_files.iter().map(fn(f) { (f.name, f.coverage) }),
    ),
  }
}

///|
pub fn CoverallsData::copy(self : CoverallsData) -> CoverallsData {
  { source_files: Map::from_iter(self.source_files.iter()) }
}

///|
pub fn CoverallsData::merge_inplace_with!(
  self : CoverallsData,
  other : CoverallsData
) -> Unit {
  for src_file, delta_cov in other.source_files {
    match self.source_files[src_file] {
      Some(cov) => {
        assert_eq!(cov.length(), delta_cov.length())
        for i, c in delta_cov {
          let ci = cov[i]
          assert_eq!(ci._.is_empty(), c._.is_empty())
          guard ci._ is Some(ci) else { continue }
          guard c._ is Some(c) else { continue }
          guard c != 0 else { continue }
          cov[i] = Some(ci + c)
        }
      }
      None => self.source_files[src_file] = delta_cov.copy()
    }
  }
}

///|
pub fn CoverallsData::merge!(
  self : CoverallsData,
  other : CoverallsData
) -> CoverallsData {
  self.copy()..merge_inplace_with!(other)
}

///|
pub fn CoverallsData::raw_coverage(
  self : CoverallsData,
  src_file : String
) -> CoverallsFileCoverage? {
  self.source_files.get(src_file)
}

///|
pub fn CoverallsData::readable_coverage_toplevels(
  self : CoverallsData,
  src_file : String,
  src_text : String
) -> ToplevelLines {
  let coverage = self.raw_coverage(src_file).unwrap()
  let toplevels1 = match toplevel_lines(src_text) {
    [[""], .. rest] | [.. rest] => rest
  }
  let res = []
  let mut i = 0
  for toplevel in toplevels1 {
    let mut curr = ""
    for line in toplevel {
      let header = if coverage[i]._ == Some(0) { "[UNCOVERED]" } else { "" }
      curr += "L\{i + 1}\{header} \{line}\n"
      i += 1
    }
    res.push(curr)
  }
  res
}

///|
pub fn CoverallsData::summary(self : CoverallsData) -> Map[String, Double] {
  let res = Map::new()
  for src_file, cs in self.source_files {
    let mut total = 0
    let mut covered = 0
    for c in cs {
      guard c._ is Some(c) else { continue }
      total += 1
      if c > 0 {
        covered += 1
      }
    }
    res[src_file] = covered.to_double() / total.to_double()
  }
  res
}

///|
pub struct Project {
  cwd : String
} derive(Show)

///|
pub fn Project::new(cwd : String) -> Project {
  { cwd, }
}

///|
pub fn Project::coverage_data!(self : Project) -> CoverallsData {
  CoverallsData::from_raw(self.coverage_json!())
}

///|
pub fn Project::coverage_json!(self : Project) -> CoverallsJson {
  let _ = self.run("moon", ["coverage", "clean"])
  let _ = self.run("moon", ["test", "--enable-coverage"])
  let _ = self.run("moon", ["info"])
  let target_coveralls_json = @path.join(["target", coveralls_json])
  let _ = self.run("moon", [
    "coverage",
    "report",
    "-f=coveralls",
    "-o=\{target_coveralls_json}",
  ])
  @json.from_json!(
    @json.parse!(
      @fs.read_file_to_string!(self.qualified_path(target_coveralls_json)),
    ),
  )
}

///|
pub fn Project::has_test_import_all!(
  self : Project,
  package_name : String
) -> Bool {
  let moon_pkg_json = self.moon_pkg_json!(package_name)
  moon_pkg_json.test_import_all.or(true)
}

///|
pub fn Project::imports!(
  self : Project,
  package_name : String,
  use_mbti~ : Bool = true,
  recursive~ : Bool = true
) -> Set[String] {
  guard recursive else {
    let regular_imports = if use_mbti {
      imports_from_mbti(
        @fs.read_file_to_string!(self.package_mbti_path!(package_name).unwrap()),
      ).iter()
    } else {
      self.moon_pkg_json!(package_name).import_.map_or_else(
        Iter::empty,
        Array::iter,
      )
    }
    let imports = self.moon_pkg_json!(package_name).test_import.map_or_else(
      fn() { Set::new() },
      Set::from_array,
    )
    for imp in regular_imports {
      imports.add(imp)
    }
    imports
  }
  let seen = Set::new()
  let mod = self.module_name!()
  for st = [package_name]; not(st.is_empty()); {
    let curr = st.pop().unwrap()
    let full_pkgs = self.imports!(curr, use_mbti~, recursive=false)
    for full_pkg in full_pkgs {
      // Only handle imports within the same module
      guard full_pkg.starts_with(mod) else { continue }
      let pkg = full_pkg.substring(start=mod.length() + 1)
      // Only handle unseen imports
      guard not(seen.contains(pkg)) else { continue }
      seen.add(pkg)
      st.push(pkg)
    }
  }
  seen
}

///| The short name of the module/project, as defined in `moon.mod.json`.
///
/// Example: `cmark`
pub fn Project::module_base_name!(self : Project) -> String {
  @path.basename(self.module_name!())
}

///|
/// The name of the module/project, as defined in `moon.mod.json`.
///
/// Example: `rami3l/cmark`
pub fn Project::module_name!(self : Project) -> String {
  self.moon_mod_json!().name
}

///|
pub fn Project::moon_mod_json!(self : Project) -> MoonModJSON {
  @json.from_json!(
    @json.parse!(@fs.read_file_to_string!(self.qualified_path("moon.mod.json"))),
  )
}

///|
pub fn Project::moon_pkg_json!(
  self : Project,
  package_name : String
) -> MoonPkgJSON {
  @json.from_json!(
    @json.parse!(
      @fs.read_file_to_string!(
        @path.join([self.package_dir!(package_name), "moon.pkg.json"]),
      ),
    ),
  )
}

///|
pub fn Project::package_base_name!(
  self : Project,
  source_file : String
) -> String {
  let package_dir = @path.dirname(self.qualified_path(source_file))
  @path.relative(self.source_dir!(), package_dir)
}

///|
pub fn Project::package_dir!(self : Project, package_name : String) -> String {
  @path.join([self.source_dir!(), self.strip_package_name!(package_name)])
}

///|
/// Returns the path to the `.mbti` file of a package.
///
/// ## Parameters
///
/// - `package_name`: This parameter can be any of the following:
///   - The full package name starting with the full module/project name
///     (e.g. `rami3l/cmark/cmark_renderer`).
///   - The full package name starting with `moonbitlang/core`.
///   - If `force_full` is set to `false`, the short package name (e.g. `cmark_renderer`).
///
/// - `force_full`: Whether to force the full package name.
///   If this flag is set to `true` and `packageName`
///   does not start with the module/project name or `moonbitlang/core`,
///   this function will return `None`.
pub fn Project::package_mbti_path!(
  self : Project,
  package_name : String,
  force_full~ : Bool = false
) -> String? {
  let mut package_name = package_name
  if not(self.is_moonbitlang_core!()) &&
    package_name.starts_with(moonbitlang_core) {
    package_name = package_name.substring(start=moonbitlang_core.length() + 1)
    return Some(
      @path.join(
        [moon_core_path()]
        ..push_iter(package_name.split("/"))
        ..push(@path.basename(package_name) + ".mbti"),
      ),
    )
  }
  let module_name = self.module_name!()
  if package_name.starts_with(module_name) {
    guard not(force_full) else { return None }
    package_name = package_name.substring(start=module_name.length() + 1)
  }
  Some(
    @path.join([
      self.package_dir!(package_name),
      @path.basename(package_name) + ".mbti",
    ]),
  )
}

///|
fn Project::is_moonbitlang_core!(self : Project) -> Bool {
  self.moon_mod_json!().name == moonbitlang_core
}

///|
pub fn Project::package_name!(
  self : Project,
  source_file : String,
  full~ : Bool = false
) -> String {
  let name = self.package_base_name!(source_file)
  guard full else { name }
  @path.join([self.module_name!(), name])
}

///|
pub fn Project::qualified_path(self : Project, relative : String) -> String {
  @path.join([self.cwd, relative])
}

///|
pub fn Project::source_dir!(self : Project) -> String {
  self.qualified_path(self.moon_mod_json!().source.or("."))
}

///|
pub fn Project::strip_package_name!(
  self : Project,
  package_name : String
) -> String {
  let module_name = self.module_name!()
  if package_name.starts_with("\{module_name}/") {
    package_name.substring(start=module_name.length() + 1)
  } else {
    package_name
  }
}

///|
pub fn Project::target_dir(self : Project) -> String {
  self.qualified_path("target")
}

///|
pub fn Project::run(
  self : Project,
  cmd : String,
  args : Array[String],
  opts? : Iter2[String, String]
) -> @js.Value {
  self._run(spawn_sync_ffi, cmd, args, opts?)
}

///|
extern "js" fn spawn_sync_ffi(
  cmd : String,
  args : Array[String],
  opts : @js.Object
) -> @js.Value = "require('node:child_process').spawnSync"

///|
pub async fn Project::arun(
  self : Project,
  cmd : String,
  args : Array[String],
  opts? : Iter2[String, String]
) -> @js.Value! {
  self._run(spawn_ffi, cmd, args, opts?).wait!!()
}

///|
extern "js" fn spawn_ffi(
  cmd : String,
  args : Array[String],
  opts : @js.Object
) -> @js.Promise =
  #|async (...args) => {
  #|  const child = require('node:child_process').spawn(...args);
  #|  let stdout = "";
  #|  for await (const chunk of child.stdout) { stdout += chunk; }
  #|  let stderr = "";
  #|  for await (const chunk of child.stderr) { stderr += chunk; }
  #|  const status = await new Promise((resolve, reject) => { child.on('close', resolve); });
  #|  return { stdout, stderr, status };
  #|}

///|
fn Project::_run[T](
  self : Project,
  spawnFn : (String, Array[String], @js.Object) -> T,
  cmd : String,
  args : Array[String],
  opts? : Iter2[String, String]
) -> T {
  let opts1 = @js.Object::from_iter2(
    { "cwd": self.cwd, "stdio": "pipe" }.iter2(),
  )
  for opts in opts {
    opts1.extend_iter2(opts)
  }
  let cmd_str = String::concat(separator=" ", [cmd] + args)
  @log.g().debug("running subcommand: \{cmd_str}")
  spawnFn(cmd, args, opts1)
}
