///|
pub(all) struct Agent {
  llm : Polyglot // TODO: Should have used the `Llm` trait object
  project : @mbt.Project
}

///|
pub typealias PrevErrs = Map[@mbt.Toplevel, Array[TestError]]

///|
pub typealias FixedTestCases = Map[@mbt.Toplevel, Array[@mbt.Toplevel]]

///|
pub async fn Agent::fix_test_cases!(
  self : Agent,
  prev_errs? : PrevErrs
) -> FixedTestCases {
  guard prev_errs is Some(prev_errs) else { Map::new() }
  let entries = prev_errs.iter2().to_array()
  let raw_resp = @js.async_all!!(
    entries.map(fn {
      (_, es) =>
        async fn!() {
          @js.async_all!!(
            es.map(fn(e) { async fn() { self.fix_test_error!!(e) } }),
          )
        }
    }),
  )
  let res = Map::new()
  for i, ts in raw_resp {
    let (ft, _) = entries[i]
    res[ft] = ts
  }
  res
}

///|
pub(all) struct GeneratedTestCases[A] {
  additions : A
  coverage_data : @mbt.CoverallsData
  errs : Map[@mbt.Toplevel, Array[TestError]]
} derive(Show)

///|
pub async fn Agent::generate_test_cases!(
  self : Agent,
  src_file : String,
  coverage_data : @mbt.CoverallsData,
  prev_errs? : PrevErrs
) -> GeneratedTestCases[Array[@mbt.Toplevel]] {
  let res = {
    additions: Array::new(),
    coverage_data: coverage_data.copy(),
    errs: Map::new(),
  }
  let all_tasks = self.generate_unverified_test_cases!!(
    src_file,
    res.coverage_data,
  )
  let all_tasks = if all_tasks.is_empty() {
    []
  } else {
    all_tasks
    .iter2()
    .concat(self.fix_test_cases!!(prev_errs?).iter2())
    .to_array()
  }
  // FIXME: cannot call async function in `for .. in` loop
  for i = 0; i < all_tasks.length(); i = i + 1 {
    let (toplevel, test_cases) = all_tasks[i]
    // TODO: Could use `Promise.all()` here.
    for i = 0; i < test_cases.length(); i = i + 1 {
      let test_case = test_cases[i]
      let test_result = self.verify_test_case!!(
        src_file,
        test_case,
        res.coverage_data,
      )
      match test_result {
        Err(e) => {
          @log.g().warn(
            "encountered error while testing: \{@json.stringify(indent=2, e.to_json())}",
          )
          res.errs.get_or_init(toplevel, fn() { [] }).push(e)
        }
        Ok({ delta_coverage_data }) =>
          for delta_coverage_data in delta_coverage_data {
            res.additions.push(test_case)
            res.coverage_data.merge_inplace_with!(delta_coverage_data)
          }
      }
    }
  }
  res
}

///|
pub async fn Agent::generate_test_cases_with_initial_gas!(
  self : Agent,
  src_files? : Array[String],
  initial_gas~ : Int,
  coverage_data? : @mbt.CoverallsData
) -> GeneratedTestCases[Map[String, Array[@mbt.Toplevel]]] {
  let res = {
    additions: Map::new(),
    coverage_data: coverage_data.or(self.project.coverage_data!()),
    errs: Map::new(),
  }
  let src_files = match src_files {
    None => self.project_source_files!().to_array()
    Some(fs) => fs
  }
  // FIXME: cannot call async function in `for .. in` loop
  for i = 0; i < src_files.length(); i = i + 1 {
    let src_file = src_files[i]
    let (toplevels, new_coverage_data) = self._generate_test_cases_with_initial_gas!!(
      src_file,
      initial_gas,
      res.coverage_data,
    )
    res.coverage_data.merge_inplace_with!(new_coverage_data)
    res.additions[src_file] = toplevels // TODO: Could use `Promise.all()` here.
    @log.g().info("finished generating test cases for: \{src_file}")
  }
  res
}

///|
pub async fn Agent::generate_unverified_test_cases!(
  self : Agent,
  src_file : String,
  coverage : @mbt.CoverallsData
) -> FixedTestCases {
  let package_ = self.project.package_name!(src_file)
  let imports = self.project.imports!(package_)
  let src_text = @fs.read_file_to_string!(self.project.qualified_path(src_file))
  let coverage_toplevels = coverage.readable_coverage_toplevels(
    src_file, src_text,
  )
  fn read_mbti!(pkg : String) -> String? {
    let mbti_path = self.project.package_mbti_path!(pkg, force_full=true)
    guard mbti_path is Some(mbti_path) else { None }
    guard @fs.path_exists(mbti_path) else { None }
    Some(@fs.read_file_to_string!(mbti_path))
  }

  fn mbti_intro!(pkg : String) -> String? {
    guard read_mbti!(pkg) is Some(got) else { None }
    Some(
      "Here is the public API interface of the imported package `@\{pkg}`\n\n\{got}",
    )
  }

  let imported_interfaces = []
  for i in imports {
    for got in mbti_intro!(i) {
      imported_interfaces.push(got)
    }
  }
  let base_params = {
    "coverage": coverage_toplevels.to_json(),
    "importedInterfaces": String::concat(separator="\n\n", imported_interfaces).to_json(),
    "interface": read_mbti!(package_).to_json(),
    "name": src_file.to_json(),
    "package": package_.to_json(),
    "project": self.project.module_base_name!().to_json(),
    "qualify": (if self.project.has_test_import_all!(package_) {
      ""
    } else {
      "As a result, each reference to the given functions must be made by prepending `@\{package_}`. For example, you should call the `add()` function like so: `@\{package_}.add()`"
    }).to_json(),
    "system": @prompt.system.to_json(),
  }
  async fn invoke!(llm : Polyglot, excerpt : String) -> String {
    let first_line = excerpt.trim_space().split("\n").head().unwrap()
    @log.g().info("generating test cases for toplevel at \{first_line}...")
    let message = @prompt.gen_tests_template.render!(
      base_params..set("excerpt", excerpt.to_json()).to_json(),
    )
    let response = llm.respond_to!!(message)
    extract_code_from_raw_resp(response)
  }

  let candidates = coverage_toplevels.filter_map(fn(t) {
    guard @mbt.fn_name(t) is Some(f) && not(@mbt.is_fully_covered(t)) else {
      None
    }
    Some((f, t))
  })
  @log.g().info(
    "found \{candidates.length()} uncovered functions in `\{src_file}`",
  )
  let res = Map::new()
  guard not(candidates.is_empty()) else { res }
  let raw_resp = @js.async_all!!(
    candidates.map(fn {
      (_, excerpt) => async fn!() { invoke!!(self.llm, excerpt) }
    }),
  )
  for i, ft in candidates {
    let (f, _) = ft
    let addition = raw_resp[i]
    res.get_or_init(f, fn() { [] }).push_iter(@mbt.toplevels(addition).iter())
  }
  res
}

///|
pub async fn Agent::verify_test_case!(
  self : Agent,
  src_file : String,
  test_case : @mbt.Toplevel,
  coverage_data : @mbt.CoverallsData,
  replacements? : Map[String, String]
) -> TestResult {
  let project_name = self.project.module_base_name!()
  let package_base_name = self.project.package_name!(src_file)
  let package_name = self.project.package_name!(src_file, full=true)
  let mut target_dir : String? = None
  let mut test_case = test_case
  try {
    // Set up the temporary target directory.
    target_dir = Some(
      @path.mkdtemp(
        @path.join([
          @jsext.temp_dir(),
          "agent_coverage-\{project_name}-\{package_base_name}-".replace_all(
            old="/",
            new="-",
          ),
        ]),
      ),
    )
    guard target_dir is Some(target_dir)
    let random_prefix = @path.basename(target_dir).replace_all(old="-", new="_")

    // Apply the replacements and format the test case.
    let patch_mbt = @path.join([target_dir, "patch_test.mbt"])
    @log.g().debug("generating test file at \{patch_mbt}...")
    if replacements is Some(rs) {
      for r in rs {
        test_case = test_case.replace(old=r.0, new=r.1)
      }
    }
    let test_case = @mbt.moonfmt!(test_case)
    // Write the formatted test case to the final JSON patch file.
    let patch_json = @path.with_extension(patch_mbt, "json")
    @fs.write_string_to_file!(
      patch_json,
      @json.stringify({
        "drops": [],
        "patches": [
          {
            "content": test_case.to_json(),
            "name": "\{random_prefix}_\{@path.basename(patch_mbt)}",
          },
        ],
      }),
    )

    // Build the test case with the patch.
    let moon_test_base_args = [
      "--target-dir=\{target_dir}",
      "test",
      "--enable-coverage",
      // "--no-render",
      "--test-failure-json",
      "-p=\{package_name}",
      "--patch-file=\{patch_json}",
    ]
    let build_output = self.arun!!(
      "moon",
      moon_test_base_args + ["--build-only"],
    )
    let build_status = (
      build_output.get_with_string("status") : @js.Optional[Int]).to_option()
    guard build_status == Some(0) else {
      return Err(
        CompileError(
          code=test_case,
          exit_state=build_status,
          stderr=(
              build_output.get_with_string("stderr") : @js.Optional[@js.Value])
            .to_option()
            .map_or("", Show::to_string),
          stdout=(
              build_output.get_with_string("stdout") : @js.Optional[@js.Value])
            .to_option()
            .map_or("", Show::to_string),
        ),
      )
      // TODO: Handle ICEs.
    }

    // Run the test case with the patch.
    let run_output = self.arun!!("moon", moon_test_base_args)
    let run_status = (run_output.get_with_string("status") : @js.Optional[Int]).to_option()
    guard run_status == Some(0) else {
      let stdout = (
          run_output.get_with_string("stdout") : @js.Optional[@js.Value])
        .to_option()
        .map_or("", Show::to_string)
      guard not(stdout.contains("@EXPECT_FAILED")) else {
        let out_jsons = extract_jsons_from_test_stdout(stdout)
        return Err(ExpectError(code=test_case, expect_failures=out_jsons))
      }
      return Err(
        RuntimeError(
          code=test_case,
          exit_state=run_status,
          stdout~,
          stderr=(run_output.get_with_string("stderr") : @js.Optional[@js.Value])
            .to_option()
            .map_or("", Show::to_string),
        ),
      )
    }

    // Generate and analyze the coverage report.
    let patched_coveralls_json = @path.join([target_dir, "coveralls.json"])
    let trace_files = @fs.read_dir!(target_dir).filter_map(fn(rel) {
      guard @jsext.Re::new(
        #|^.*\/moonbit_coverage_.*\.txt"$
        ,
      ).test_(rel) else {
        None
      }
      Some(@path.join([target_dir, rel]))
    })
    let _ = self.arun!!(
      "moon",
      [
        "--target-dir=\{target_dir}",
        "coverage",
        "report",
        "-f=coveralls",
        "-o=\{patched_coveralls_json}",
      ] +
      trace_files.map(fn(tf) { "-t=\{tf}" }),
    )

    // Extract the coverage data from coveralls JSON.
    let delta = @mbt.CoverallsData::from_raw(
      @json.from_json!(
        @json.parse!(@fs.read_file_to_string!(patched_coveralls_json)),
      ),
    )
    let delta_coverage = delta.source_files[src_file].unwrap()
    let coverage = coverage_data.source_files[src_file].unwrap()
    assert_eq!(coverage.length(), delta_coverage.length())
    let has_new_coverage = for i, c in coverage {
      let dc = delta_coverage[i]
      if c._ == Some(0) && dc._.map_or(false, fn(dc) { dc > 0 }) {
        break true
      }
    } else {
      false
    }
    let delta_coverage_data = if has_new_coverage {
      @log.g().debug(
        "new coverage found at \{src_file}, this addition will be accepted",
      )
      Some(delta)
    } else {
      @log.g().info(
        "no new coverage found at \{src_file} by the following addition:\n\{test_case}",
      )
      None
    }

    // Clean up the temporary target directory.
    @fs.remove_dir!(target_dir)
    Ok({ delta_coverage_data, })
  } catch {
    e => {
      if target_dir is Some(path) {
        @fs.remove_dir!(path)
      }
      raise e
    }
  }
}

///|
async fn Agent::_generate_test_cases_with_initial_gas(
  self : Agent,
  src_file : String,
  initial_gas : Int,
  coverage_data : @mbt.CoverallsData
) -> (Array[@mbt.Toplevel], @mbt.CoverallsData) {
  let toplevels = []
  let mut errs = Map::new()
  let mut curr_coverage_data = coverage_data.copy()
  try {
    for gas = initial_gas; gas > 0; {
      @log.g().info("working on `\{src_file}` with gas \{gas}...")
      let { additions, coverage_data: new_coverage_data, errs: new_errs } = self.generate_test_cases!!(
        src_file,
        curr_coverage_data,
        prev_errs=errs,
      )
      errs = new_errs
      guard not(additions.is_empty()) else { continue gas - 1 }
      curr_coverage_data = new_coverage_data
      @log.g().info(
        "successfully added \{additions.length()} new test cases for `\{src_file}`...",
      )
      toplevels.push_iter(additions.iter())
      continue initial_gas
    }
  } catch {
    @js.Error_(e) =>
      @log.g().error(
        "error while generating test cases for `\{src_file}`: \{@jsext.inspect?(e).unwrap()}",
      )
    e =>
      @log.g().error(
        "error while generating test cases for `\{src_file}`: \{e}",
      )
  }
  (toplevels, curr_coverage_data)
}

///|
async fn Agent::fix_test_error!(self : Agent, e : TestError) -> String {
  guard e
    is (CompileError(code=excerpt, stderr~, stdout~, ..)
    | RuntimeError(code=excerpt, stderr~, stdout~, ..)) else {
    fix_expect_error!(e)
  }
  guard ({ "system": @prompt.system.to_json() } : Json) is Object(base_params)
  let excerpt = excerpt.trim_space()
  let first_line = excerpt.split("\n").head().or(excerpt)
  @log.g().info("fixing test case \{first_line}...")
  let message = @prompt.fix_tests_template.render!(
    base_params
    ..set("excerpt", excerpt.to_json())
    ..set("stderr", stderr.to_json())
    ..set("stdout", stdout.to_json())
    .to_json(),
  )
  extract_code_from_raw_resp(self.llm.respond_to!!(message))
}

///|
fn Agent::project_source_files!(self : Agent) -> Iter[String] {
  self.project.coverage_data!().source_files.keys()
}

///|
fn Agent::run(
  self : Agent,
  cmd : String,
  args : Array[String],
  opts? : Iter2[String, String]
) -> @js.Value {
  self.project.run(cmd, args, opts?)
}

///|
async fn Agent::arun!(
  self : Agent,
  cmd : String,
  args : Array[String],
  opts? : Iter2[String, String]
) -> @js.Value {
  self.project.arun!!(cmd, args, opts?)
}
