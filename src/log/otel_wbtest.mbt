///|
test "generates OtelAttrVal" {
  @json.inspect!(
    OtelAttrVal::from_json!({
      "string.attribute": "some string",
      "boolean.attribute": true,
      "double.attribute": 637.704,
      "array.attribute": ["many", "values"],
      "map.attribute": { "some.map.key": "some value" },
    })._,
    content={
      "kvlistValue": {
        "values": [
          {
            "key": "string.attribute",
            "value": { "stringValue": "some string" },
          },
          { "key": "boolean.attribute", "value": { "boolValue": true } },
          { "key": "double.attribute", "value": { "doubleValue": 637.704 } },
          {
            "key": "array.attribute",
            "value": {
              "arrayValue": {
                "values": [
                  { "stringValue": "many" },
                  { "stringValue": "values" },
                ],
              },
            },
          },
          {
            "key": "map.attribute",
            "value": {
              "kvlistValue": {
                "values": [
                  {
                    "key": "some.map.key",
                    "value": { "stringValue": "some value" },
                  },
                ],
              },
            },
          },
        ],
      },
    },
  )
}
