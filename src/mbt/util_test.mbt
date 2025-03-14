///|
test "extract toplevels" {
  let src =
    #|pub fn Folder::none[A, B](self : Folder[A], _a : A, _b : B) -> FolderResult[A] {
    #|  let _ = self
    #|  Default
    #|}
    #|
    #|pub fn Folder::inline_ext_none[A](
    #|  self : Folder[A],
    #|  _a : A,
    #|  _b : Inline
    #|) -> A!FolderError {
    #|  let _ = self
    #|  raise FolderError("unknown inline extension")
    #|}
  @json.inspect!(toplevel_lines(src), content=[
    [""],
    [
      "pub fn Folder::none[A, B](self : Folder[A], _a : A, _b : B) -> FolderResult[A] {",
      "  let _ = self", "  Default", "}", "",
    ],
    [
      "pub fn Folder::inline_ext_none[A](", "  self : Folder[A],", "  _a : A,", "  _b : Inline",
      ") -> A!FolderError {", "  let _ = self", "  raise FolderError(\"unknown inline extension\")",
      "}",
    ],
  ])
}

///|
test "extract topleves with test block" {
  let src =
    #|// Header
    #|// More header
    #|
    #|test "hash_combine for tuple with primitive types" {
    #|  let hasher = Hasher::new()
    #|  let tuple = (1, "hello")
    #|  hasher..combine(tuple)
    #|  inspect!(hasher.finalize(), content="761901253")
    #|}
    #|
    #|test "hash_combine for tuple with same values" {
    #|  let hasher1 = Hasher::new()
    #|  let hasher2 = Hasher::new()
    #|  let tuple1 = (42, "test")
    #|  let tuple2 = (42, "test")
    #|  hasher1..combine(tuple1)
    #|  hasher2..combine(tuple2)
    #|  assert_eq!(hasher1.finalize(), hasher2.finalize())
    #|}
    #|
    #|test "hash_combine with Option types tuple" {
    #|  let hasher = Hasher::new()
    #|  let tuple = (Some(1), None : Int?)
    #|  hasher..combine(tuple)
    #|  inspect!(hasher.finalize(), content="525273977")
    #|}
    #|
  @json.inspect!(toplevel_lines(src), content=[
    ["// Header", "// More header"],
    [
      "", "test \"hash_combine for tuple with primitive types\" {", "  let hasher = Hasher::new()",
      "  let tuple = (1, \"hello\")", "  hasher..combine(tuple)", "  inspect!(hasher.finalize(), content=\"761901253\")",
      "}", "",
    ],
    [
      "test \"hash_combine for tuple with same values\" {", "  let hasher1 = Hasher::new()",
      "  let hasher2 = Hasher::new()", "  let tuple1 = (42, \"test\")", "  let tuple2 = (42, \"test\")",
      "  hasher1..combine(tuple1)", "  hasher2..combine(tuple2)", "  assert_eq!(hasher1.finalize(), hasher2.finalize())",
      "}", "",
    ],
    [
      "test \"hash_combine with Option types tuple\" {", "  let hasher = Hasher::new()",
      "  let tuple = (Some(1), None : Int?)", "  hasher..combine(tuple)", "  inspect!(hasher.finalize(), content=\"525273977\")",
      "}",
    ],
  ])
}

///|
test "extract toplevels with impl block" {
  let src =
    #|///|
    #|fn endian32(input : Bytes, cur : Int) -> Int {
    #|  input[cur + 0].to_int() |
    #|  (
    #|    (input[cur + 1].to_int() << 8) |
    #|    (input[cur + 2].to_int() << 16) |
    #|    (input[cur + 3].to_int() << 24)
    #|  )
    #|}
    #|
    #|///|
    #|pub impl Hash for String with hash_combine(self, hasher) {
    #|  hasher.combine_string(self)
    #|}
    #|
    #|fn hello() -> String {
    #|  "Hi!"
    #|}
  @json.inspect!(toplevel_lines(src), content=[
    [""],
    [
      "///|", "fn endian32(input : Bytes, cur : Int) -> Int {", "  input[cur + 0].to_int() |",
      "  (", "    (input[cur + 1].to_int() << 8) |", "    (input[cur + 2].to_int() << 16) |",
      "    (input[cur + 3].to_int() << 24)", "  )", "}",
    ],
    [
      "///|", "pub impl Hash for String with hash_combine(self, hasher) {", "  hasher.combine_string(self)",
      "}", "",
    ],
    ["fn hello() -> String {", "  \"Hi!\"", "}"],
  ])
}

///|
test "extract function names from toplevels" {
  let covered = "L83 pub fn is_ascii_hexdigit(c : Char) -> Bool {\n" +
    "L84   is_ascii_digit(c) || ('A' <= c && c <= 'F') || ('a' <= c && c <= 'f')\n" +
    "L85 }\n" +
    "L86 \n"
  let uncovered = "L87 pub fn ascii_hexdigit_to_int(c : Char) -> Int {\n" +
    "L88   match c {\n" +
    "L89     '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>\n" +
    "L90       c.to_int() - 0x30\n" +
    "L91     'A' | 'B' | 'C' | 'D' | 'E' | 'F' => c.to_int() - 0x37\n" +
    "L92     'a' | 'b' | 'c' | 'd' | 'e' | 'f' => c.to_int() - 0x57\n" +
    "L93[UNCOVERED]     _ => panic()\n" +
    "L94   }\n" +
    "L95 }\n"
  let an_impl = "L97 pub impl Hash for String with hash_combine(self, hasher) {\n" +
    "L98   hasher.combine_string(self)\n" +
    "L99 }\n"
  let trait_object_method = "L101 pub fn &Logger::write_object[Obj : Show](self : &Logger, obj : Obj) -> Unit { obj.output(self) }\n"
  let not_a_function = "L96 let answer = 42;\n"
  inspect!(
    fn_name(covered),
    content=
      #|Some("is_ascii_hexdigit")
    ,
  )
  inspect!(
    fn_name(uncovered),
    content=
      #|Some("ascii_hexdigit_to_int")
    ,
  )
  inspect!(
    fn_name(trait_object_method),
    content=
      #|Some("&Logger::write_object")
    ,
  )
  inspect!(
    fn_name(an_impl),
    content=
      #|Some("hash_combine")
    ,
  )
  inspect!(fn_name(not_a_function), content="None")
}

///|
test "moonfmt" {
  inspect!(
    moonfmt!(
      #|fn hello() -> String { "Hi!" }
      ,
    ),
    content=
      #|///|
      #|fn hello() -> String {
      #|  "Hi!"
      #|}
      #|
    ,
  )
  inspect!(
    moonfmt!(
      #|
      #|fn hello() -> String { "Hi!" }
      ,
    ),
    content=
      #|///|
      #|fn hello() -> String {
      #|  "Hi!"
      #|}
      #|
    ,
  )
}

///|
test "distinguish between covered and uncovered functions" {
  let covered = "L83 pub fn is_ascii_hexdigit(c : Char) -> Bool {\n" +
    "L84   is_ascii_digit(c) || ('A' <= c && c <= 'F') || ('a' <= c && c <= 'f')\n" +
    "L85 }\n" +
    "L86 \n"
  let uncovered = "L87 pub fn ascii_hexdigit_to_int(c : Char) -> Int {\n" +
    "L88   match c {\n" +
    "L89     '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>\n" +
    "L90       c.to_int() - 0x30\n" +
    "L91     'A' | 'B' | 'C' | 'D' | 'E' | 'F' => c.to_int() - 0x37\n" +
    "L92     'a' | 'b' | 'c' | 'd' | 'e' | 'f' => c.to_int() - 0x57\n" +
    "L93[UNCOVERED]     _ => panic()\n" +
    "L94   }\n" +
    "L95 }\n"
  inspect!(is_fully_covered(covered), content="true")
  inspect!(is_fully_covered(uncovered), content="false")
}

///|
test "extract imports from a standard `.mbti`" {
  let mbti =
    #|package rami3l/cmark/cmark_renderer
    #|
    #|alias @moonbitlang/core/buffer as @buffer
    #|alias @rami3l/cmark/cmark as @cmark
    #|
    #|// Values
    #|
    #|// Types and methods
    #|pub(all) struct Context {
    #|  renderer : Renderer
    #|  state : Map[String, Json]
    #|  b : @buffer.T
    #|  doc : @cmark.Doc
    #|}
    #|impl Context {
    #|  block(Self, @cmark.Block) -> Unit!
    #|  byte(Self, Byte) -> Unit
    #|  char(Self, Char) -> Unit
    #|  doc(Self, @cmark.Doc) -> Unit!
    #|  init(Self, @cmark.Doc) -> Unit
    #|  inline(Self, @cmark.Inline) -> Unit!
    #|  new(Renderer, @buffer.T) -> Self
    #|  string(Self, String) -> Unit
    #|}
    #|
    #|pub(all) type! RenderError String
    #|impl Show for RenderError
    #|
    #|pub(all) struct Renderer {
    #|  init_context : (Context, @cmark.Doc) -> Unit
    #|  inline : (Context, @cmark.Inline) -> Bool!
    #|  block : (Context, @cmark.Block) -> Bool!
    #|  doc : (Context, @cmark.Doc) -> Bool!
    #|}
    #|impl Renderer {
    #|  buffer_add_doc(Self, @buffer.T, @cmark.Doc) -> Unit!
    #|  compose(Self, Self) -> Self
    #|  doc_to_string(Self, @cmark.Doc) -> String!
    #|  new(init_context~ : (Context, @cmark.Doc) -> Unit = .., inline~ : (Context, @cmark.Inline) -> Bool! = .., block~ : (Context, @cmark.Block) -> Bool! = .., doc~ : (Context, @cmark.Doc) -> Bool! = ..) -> Self
    #|}
    #|
    #|// Type aliases
    #|pub typealias BlockFn = (Context, @cmark.Block) -> Bool!
    #|
    #|pub typealias DocFn = (Context, @cmark.Doc) -> Bool!
    #|
    #|pub typealias InitContextFn = (Context, @cmark.Doc) -> Unit
    #|
    #|pub typealias InlineFn = (Context, @cmark.Inline) -> Bool!
    #|
    #|// Traits
    #|
  inspect!(
    imports_from_mbti(mbti),
    content=
      #|{"moonbitlang/core/builtin", "moonbitlang/core/buffer", "rami3l/cmark/cmark"}
    ,
  )
}

///|
test "extract imports from a `--no-alias` `.mbti`" {
  let mbti =
    #|package rami3l/cmark/cmark_renderer
    #|
    #|// Values
    #|
    #|// Types and methods
    #|pub(all) struct Context {
    #|  renderer : Renderer
    #|  state : Map[String, Json]
    #|  b : @moonbitlang/core/buffer.T
    #|  doc : @rami3l/cmark/cmark.Doc
    #|}
    #|impl Context {
    #|  block(Self, @rami3l/cmark/cmark.Block) -> Unit!
    #|  byte(Self, Byte) -> Unit
    #|  char(Self, Char) -> Unit
    #|  doc(Self, @rami3l/cmark/cmark.Doc) -> Unit!
    #|  init(Self, @rami3l/cmark/cmark.Doc) -> Unit
    #|  inline(Self, @rami3l/cmark/cmark.Inline) -> Unit!
    #|  new(Renderer, @moonbitlang/core/buffer.T) -> Self
    #|  string(Self, String) -> Unit
    #|}
    #|
    #|pub(all) type! RenderError String
    #|impl Show for RenderError
    #|
    #|pub(all) struct Renderer {
    #|  init_context : (Context, @rami3l/cmark/cmark.Doc) -> Unit
    #|  inline : (Context, @rami3l/cmark/cmark.Inline) -> Bool!
    #|  block : (Context, @rami3l/cmark/cmark.Block) -> Bool!
    #|  doc : (Context, @rami3l/cmark/cmark.Doc) -> Bool!
    #|}
    #|impl Renderer {
    #|  buffer_add_doc(Self, @moonbitlang/core/buffer.T, @rami3l/cmark/cmark.Doc) -> Unit!
    #|  compose(Self, Self) -> Self
    #|  doc_to_string(Self, @rami3l/cmark/cmark.Doc) -> String!
    #|  new(init_context~ : (Context, @rami3l/cmark/cmark.Doc) -> Unit = .., inline~ : (Context, @rami3l/cmark/cmark.Inline) -> Bool! = .., block~ : (Context, @rami3l/cmark/cmark.Block) -> Bool! = .., doc~ : (Context, @rami3l/cmark/cmark.Doc) -> Bool! = ..) -> Self
    #|}
    #|
    #|// Type aliases
    #|pub typealias BlockFn = (Context, @rami3l/cmark/cmark.Block) -> Bool!
    #|
    #|pub typealias DocFn = (Context, @rami3l/cmark/cmark.Doc) -> Bool!
    #|
    #|pub typealias InitContextFn = (Context, @rami3l/cmark/cmark.Doc) -> Unit
    #|
    #|pub typealias InlineFn = (Context, @rami3l/cmark/cmark.Inline) -> Bool!
    #|
    #|// Traits
  inspect!(
    imports_from_mbti(mbti),
    content=
      #|{"moonbitlang/core/builtin", "moonbitlang/core/buffer", "rami3l/cmark/cmark"}
    ,
  )
}
