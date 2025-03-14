Below is a list of tips for MoonBit testing:

Usually, there are multiple way to write a test case.

1. You can use `inspect!()` to perform snapshot testing. For example, suppose you're testing a function `f` that returns a record, you can write a test case as follows:

    ```moonbit
    test "test case 1" {
      inspect!(f(1, 2), content="3")
    }
    ```

2. You can also write a customized test utility function to assert the expected and actual values. For example, here is a customized test utility function to assert the approximate equality of two floating-point numbers:

    ```moonbit
    fn assert_approx_eq(
      result : Double,
      expect : Double,
      error : Double
    ) -> Unit!String { // The return type is Unit!String to indicate the test case is successful or failed with a message of type String.
      if (result - expect).abs() < error {
        () // Return Unit on success.
      } else {
        // Raises an message on failure.
        raise "Expecting \\(expect), got \\(result) instead"
      }
    }
    ```

    Then you can use it like:

    ```moonbit
    test "float test case" {
      assert_approx_eq!(g(1, 2), 3.0, 0.01)
    }
    ```

    Assuming \`g(1, 2)\` returns a float number.

3. For test cases that shares some common properties, you shall group them together into a single test block.

   ```moonbit
   test "grouped test to test basic functionality" {
     inspect!(f(1, 2), content="3")
     inspect!(f(2, 2), content="4")
     inspect!(f(2, 5), content="7")
   }

   test "grouped test for edge cases" {
     inspect!(f(0, 0), content="0")
     inspect!(f(-1, 0), content="-1")
   }
   ```

4. When the test case is expected to panic, your test **MUST** begin with `test "panic`:

   ```moonbit
   test "panic <the name of your test>" {
     ignore(the_function_that_should_panic())
   }
   ```

   For example, you may write:

   ```moonbit
   test "panic array_pop_exn_empty" {
     let arr : Array[Int] = Array::new()
     ignore(arr.unsafe_pop())
   }
   ```

Notice, you shall return your test cases wrapped in a fenced code block with the language moonbit. For example:

```moonbit
test "test case 1" {
  inspect!(f(1, 2), content="3")
  inspect!(f(2, 2), content="4")
  inspect!(f(2, 5), content="7")
}
```

- There is no `range()` in MoonBit as in Python. You can use `for i = start; i < stop; i = i + 1` to loop over an range `[start, stop)`.

- Always use `inspect!()` function over assertions like `@test.eq!()`, `@test.ne!()`.

- There is no `assert()` in MoonBit as in Python. You can use `inspect!()` instead.

- Use syntax `f!(a)` instead of `f(a)!`, the latter one is DEPRECATED.

- Use `\n` to partition batches off in `match` statements

- Examples of using `core`:

  ```moonbit
  fn main {
    let unit : Unit = ()
    let a : BigInt = BigInt::from_int64(123456789012345678)
    let b : Byte = b'\xFF'
    let bytes = Bytes::new(10)
    let bytes = Bytes::of_string("Hello, World!")
    let iter : Iter[Char] = Iter::empty()
    let iter = Iter::singleton('1')
    let exb = @buffer.new(size_hint=0)
    iter.each(fn { x => exb.write_char(x) }) // exb "1"
    let iter = Iter::repeat('1')
    let exb = @buffer.new(size_hint=0)
    iter.take(3).each(fn { x => exb.write_char(x) }) // exb "111"
    let arr = Array::make(4, 0) // arr = [0, 0, 0, 0]
    let v : Array[Int] = Array::new(capacity=3)
    let v : Array[Int] = [3, 4, 5]
    v.mapi_inplace(fn(i, x) { x + i }) // v = [3, 5, 7]
    let s : ArrayView[Int] = v[:2] // s = [3, 5]
    let mut sum = 0
    s.each(fn(x : Int) -> Unit { sum = sum + x }) // 8
    println(@math.maximum(1, 2))
    let x : Int? = Option::default()
    let m : @hashmap.T[Int, Int] = @hashmap.new()
    let queue : @queue.T[Int] = @queue.new()
    let a : @rational.T = @rational.new(2L, 3L).unwrap()
    let empty : @sorted_set.T[Int] = @sorted_set.new()
    let data : @hashset.T[String] = @hashset.of(["a", "b", "d", "e"])
    let map : @hashset.T[Int] = loop 0, @hashset.new() {
        100, map => map
        i, map => {
          map.insert(i)
          continue i + 1, map
        }
    }
    let e : @immut/array.T[Int] = @immut/array.new()
    let a : @immut/hashmap.T[Int, Int] = @immut/hashmap.new()
    let list1 : @immut/list.T[Int] = @immut/list.of([1, 2, 3])
    let list2 : @immut/list.T[String] = @immut/list.of(["a", "b", "c"])
    let zipped : @immut/list.T[(Int, String)]? = @immut/list.zip(list1, list2)
    let expected = @immut/list.of([(1, "a"), (2, "b"), (3, "c")])
  }

  test "get" {
    let v = [3]
    inspect!(v.get(-1), content="None")
    inspect!(v.get(0), content="Some(3)")
    inspect!(v.get(1), content="None")
  }

  test "char" {
    let c = 'C'
    inspect!(c, content="'C'")
    inspect!('\x00', content="'\\x00'") // Note that the backslash needs to be escaped
  }
  ```

- `if let` is not allowed. Instead of writing `if let Some(a) = b { ... }`, you should write

  ```moonbit
  match b {
    Some(a) => { ... }
    None => { ... }
  }
  ```

- Implicitly ignoring the return value of a function call is not allowed, you should explicitly ignore the return value by assigning it to `_`.
  ```moonbit
  let _ = f()
  ```

- When declaring function parameters, `_` is not a valid parameter name. You might try `__` instead.

- `mut` cannot modify variables that will not be rebound, otherwise the compiler will report an error.

  Generally, types like `@hashmap.T[Int, Int]` do not need `mut`

  ```moonbit
  let map: @hashmap.T[Int, Int] = @hashmap.new()
  // if no `map = ...` , `let mut map` is wrong
  ```

- operation `++`/`--`/`+=`/`-=` is not allowed in MoonBit
  use `i = i + 1` instead of `i++` or `++i` or `i += 1`

- There is no `import` statement in moonbit.

- When you see something like the following in the error stdout:
  ```json
  {
    "package": "some/package",
    "filename": "patch_test.mbt",
    "index": "0",
    "test_name": "map_doc with empty block",
    "message": "@EXPECT_FAILED {\"loc\": \"/path/to/patch_test.mbt:5:3-8:4\", \"args_loc\": \"[\\\"/path/to/patch_test.mbt:6:5-6:17\\\", \\\"/path/to/patch_test.mbt:7:13-7:162\\\", null, null]\", \"expect\": \"Blocks({ v: Nil, meta: Meta { id: 0, loc: TextLoc { file: \\\"\\\", first_byte: 0, last_byte: 0, first_line: (0, 0), last_line: (0, 0) }, dict: {} } })\", \"actual\": \"Blocks(Node::new(@list.of([])))\"}"
  }
  ```

  ... this means you've gotten the following text block successfully compiled, and the result almost right:
  ```moonbit
  test "map_doc with empty document" {
    let mapper = Mapper::new()
    let doc = Doc::empty()
    let result = mapper.map_doc(doc)
    inspect!(
      result.block,
      content="Blocks({ v: [], meta: { id: 0, loc: { file: \"\", first_byte: 0, last_byte: 0, first_line: (0, 0), last_line: (0, 0) }, dict: { } } })",
    )
  }
  ```

  ... in this case, do nothing but replace the `content=` at Line 7, Column 13 to Line 7, Column 162 (`7:13-7:162`) by the `actual` value like so:
  ```moonbit
  test "map_doc with empty document" {
    let mapper = Mapper::new()
    let doc = Doc::empty()
    let result = mapper.map_doc(doc)
    inspect!(
      result.block,
      content="Blocks(Node::new(@list.of([])))",
    )
  }
  ```
