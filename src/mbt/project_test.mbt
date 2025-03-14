///|
test "MoonPkgJSON" {
  @json.inspect!(
    MoonPkgJSON::{
      import_: Some(["hello", "world"]),
      test_import: Some(["goodbye", "world"]),
      test_import_all: Some(true),
    },
    content={
      "import": ["hello", "world"],
      "test-import": ["goodbye", "world"],
      "test-import-all": true,
    },
  )
}

///|
test "CoverallsData from_json and merge" {
  let null = Null
  let data = CoverallsData::from_raw(
    @json.from_json!({
      "source_files": [
        {
          "name": "src/lib/goodbye.mbt",
          "source_digest": "23da2d5d18c64b6bf65f43c6fd5fcfa2",
          "coverage": [null, null, 1, 1, 0, null],
        },
        {
          "name": "src/lib/hello.mbt",
          "source_digest": "977fce672b22006a8be03a2277a8f1a5",
          "coverage": [null, null, 0, null],
        },
      ],
    }),
  )
  @json.inspect!(data, content={
    "source_files": {
      "src/lib/goodbye.mbt": [null, null, 1, 1, 0, null],
      "src/lib/hello.mbt": [null, null, 0, null],
    },
  })
  @json.inspect!(data.summary(), content={
    "src/lib/goodbye.mbt": 0.6666666666666666,
    "src/lib/hello.mbt": 0,
  })
  @json.inspect!(
    data.merge!(
      CoverallsData::new(src_files={
        "src/lib/hello.mbt": @json.from_json!([null, null, 9, null]),
        "src/lib/six.mbt": @json.from_json!([null, 6, null]),
        "src/lib/goodbye.mbt": @json.from_json!([null, null, 42, 1, 0, null]),
      }),
    ),
    content={
      "source_files": {
        "src/lib/goodbye.mbt": [null, null, 43, 2, 0, null],
        "src/lib/hello.mbt": [null, null, 9, null],
        "src/lib/six.mbt": [null, 6, null],
      },
    },
  )
}

///|
test "CoverallsData readable_coverage_toplevels" {
  let null = Null
  let data = CoverallsData::from_raw(
    @json.from_json!({
      "source_files": [
        {
          "name": "src/lib/goodbye.mbt",
          "source_digest": "35a91a76f986c81b9c5e9f7941714682",
          "coverage": [null, null, 2, null, null, null, null, 1, 1, 1, null],
        },
      ],
    }),
  )
  @json.inspect!(
    data.readable_coverage_toplevels(
      "src/lib/goodbye.mbt",
      #|// File
      #|// Header
      #|
      #|///|
      #|let goodbye = "Goodbye"
      #|
      #|pub fn goodbye(with_suffix~ : Bool = false) -> String {
      #|  guard with_suffix else { goodbye }
      #|  goodbye + ", cruel world!"
      #|}
      ,
    ),
    content=[
      "L1 // File\nL2 // Header\n", "L3 ///|\nL4 let goodbye = \"Goodbye\"\nL5 \n",
      "L6 pub fn goodbye(with_suffix~ : Bool = false) -> String {\nL7   guard with_suffix else { goodbye }\nL8   goodbye + \", cruel world!\"\nL9 }\n",
    ],
  )
}

///|
test "Project coverage_json" {
  let null = Null
  let project = Project::new("fixture/example")
  @json.inspect!(project.coverage_json!(), content={
    "source_files": [
      {
        "coverage": [null, null, 1, null, null, null, null, 1, 1, 0, null],
        "name": "src/lib/goodbye.mbt",
        "source_digest": "35a91a76f986c81b9c5e9f7941714682",
      },
      {
        "coverage": [null, null, 0, null],
        "name": "src/lib/hello.mbt",
        "source_digest": "977fce672b22006a8be03a2277a8f1a5",
      },
    ],
  })
}
