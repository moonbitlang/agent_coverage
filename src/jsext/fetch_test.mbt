///|
test "fetch test with GET" {
  @js.async_test(async fn!() {
    let url = "https://httpbin.org/get"
    guard @json.parse!(@jsext.fetch!!(url).text!!()) is { "url": url1, .. }
    assert_eq!(url1.as_string(), Some(url))
  })
}

///|
test "fetch test with POST" {
  @js.async_test(async fn!() {
    let url = "https://httpbin.org/post"
    let body = "Hello, World!"
    guard @json.parse!(
        @jsext.fetch!!(url, opts={ "method": "POST", "body": body.to_json() }).text!!(),
      )
      is { "url": url1, "data": data1, .. }
    assert_eq!(url1.as_string(), Some(url))
    assert_eq!(data1.as_string(), Some(body))
  })
}
