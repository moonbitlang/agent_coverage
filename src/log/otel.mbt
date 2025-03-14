///|
pub struct OtelLogger {
  priv mut level : Level
  /// The OpenTelemetry HTTP endpoint, usually the one using the `4318` port.
  priv log_endpoint : String
  priv service_name : String
  priv rand : @random.Rand
}

///|
pub fn OtelLogger::new[L : IntoLevel](
  level : L,
  service_name~ : String,
  otlp_endpoint~ : String
) -> OtelLogger {
  {
    level: level.into(),
    rand: @sys.rand(),
    service_name,
    log_endpoint: otlp_endpoint + "/v1/logs",
  }
}

///|
pub fn OtelLogger::level(self : OtelLogger) -> Level {
  self.level
}

///|
pub fn OtelLogger::set_level[L : IntoLevel](
  self : OtelLogger,
  level : L
) -> Unit {
  self.level = level.into()
}

///|
pub impl BaseLogger for OtelLogger with is_level_enabled(self, level) {
  level >= self.level()
}

///|
const HEX : String = "0123456789ABCDEF"

///|
fn OtelLogger::gen_hex(self : OtelLogger, len~ : Int) -> String {
  let res = StringBuilder::new(size_hint=len)
  for _ in 0..<len {
    res.write_char(HEX[self.rand.int(limit=HEX.length())])
  }
  res.to_string()
}

///|
fn OtelLogger::gen_trace_id(self : OtelLogger) -> String {
  self.gen_hex(len=32)
}

///|
fn OtelLogger::gen_span_id(self : OtelLogger) -> String {
  self.gen_hex(len=16)
}

///|
/// https://www.hyperdx.io/blog/testing-sending-opentelemetry-events-curl
/// https://github.com/open-telemetry/opentelemetry-proto/blob/d7770822d70c7bd47a6891fc9faacc66fc4af3d3/examples/logs.json
pub impl BaseLogger for OtelLogger with log_json(self, info) {
  let { level, msg, extras } = info
  let attributes = []
  if extras is Some(extras) {
    for k, v in extras {
      attributes.push(
        (
          { "key": k.to_json(), "value": OtelAttrVal::from_json?(v).unwrap()._ } :
          Json),
      )
    }
  }
  {
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {
              "key": "service.name",
              "value": { "stringValue": self.service_name.to_json() },
            },
          ],
        },
        "scopeLogs": [
          {
            "logRecords": [
              {
                // https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-severitynumber
                "severityNumber": (level._ / 10 * 4).to_json(),
                "traceId": self.gen_trace_id().to_json(),
                "spanId": self.gen_span_id().to_json(),
                "body": { "stringValue": msg.to_json() },
                "attributes": Array(attributes),
              },
            ],
          },
        ],
      },
    ],
  }
}

///|
pub impl BaseLogger for OtelLogger with print_json(
  self : OtelLogger,
  json : Json
) -> Unit {
  @js.async_run(fn() {
    try {
      @jsext.fetch!!(self.log_endpoint, opts={
        "method": "POST",
        "headers": { "Content-Type": "application/json" },
        "body": json.stringify().to_json(),
      })
      |> ignore
    } catch {
      e => println("ERROR in `OtelLogger::print_json`: \{e}")
    }
  })
}

///|
priv type OtelAttrVal Json

///|
fn OtelAttrVal::from_json!(json : Json) -> OtelAttrVal {
  @json.from_json!(json)
}

///|
impl @json.FromJson for OtelAttrVal with from_json(json, path) {
  match json {
    String(_) as s => { "stringValue": s }
    Number(_) as n => { "doubleValue": n }
    True | False as b => { "boolValue": b }
    Array(vs) => {
      let values = Array::new()..reserve_capacity(vs.length())
      for v in vs {
        let value : OtelAttrVal = @json.from_json!(v, path~)
        values.push(value._)
      }
      { "arrayValue": { "values": Array(values) } }
    }
    Object(kvs) => {
      let values : Array[Json] = Array::new()..reserve_capacity(kvs.size())
      for k, v in kvs {
        let value : OtelAttrVal = @json.from_json!(v, path~)
        values.push({ "key": String(k), "value": value._ })
      }
      { "kvlistValue": { "values": Array(values) } }
    }
    Null => Null
  }
}
