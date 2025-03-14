///|
pub struct ConsoleLogger {
  priv mut level : Level
} derive(Show)

///|
pub fn ConsoleLogger::new[L : IntoLevel](level : L) -> ConsoleLogger {
  { level: level.into() }
}

///|
let _g : Ref[&Logger?] = Ref::new(None)

///|
pub fn g(logger? : &Logger) -> &Logger {
  if _g.val is None {
    _g.val = Some(logger.or_else(fn() { ConsoleLogger::new(Info) }))
  }
  _g.val.unwrap()
}

///|
pub fn ConsoleLogger::level(self : ConsoleLogger) -> Level {
  self.level
}

///|
pub fn ConsoleLogger::set_level[L : IntoLevel](
  self : ConsoleLogger,
  level : L
) -> Unit {
  self.level = level.into()
}

///|
pub impl BaseLogger for ConsoleLogger with is_level_enabled(self, level) {
  level >= self.level()
}

///|
pub impl BaseLogger for ConsoleLogger with print_json(_, json : Json) -> Unit {
  println(@json.stringify(json))
}

///|
pub impl BaseLogger for ConsoleLogger with log_json(_self, info) {
  let { level, msg, extras } = info
  let level = level.into()
  // A standard Pino log line looks like:
  // ```
  // {"level":30,"time":1522431328992,"msg":"hello world","pid":42,"hostname":"foo","v":1}
  // ```
  let args = {
    "level": level.to_json(),
    "time": @sys.timestamp().to_json(),
    "msg": msg.to_json(),
    "pid": @sys.pid().to_json(),
    "hostname": @sys.hostname().to_json(),
  }
  if extras is Some(extras) {
    for k, v in extras {
      args[k] = v
    }
  }
  args.to_json()
}
