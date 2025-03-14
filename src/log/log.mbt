///|
pub(open) trait BaseLogger {
  is_level_enabled(Self, Level) -> Bool
  print_json(Self, Json) -> Unit
  log_json(Self, Info) -> Json
}

///|
pub struct Info {
  level : Level
  msg : String
  extras : Map[String, Json]?
}

///|
pub(open) trait Logger: BaseLogger {
  log(Self, Info) -> Unit
}

///|
impl Logger with log(self, info) {
  guard self.is_level_enabled(info.level) else { return }
  self.print_json(self.log_json(info))
}

///|
pub fn &Logger::trace(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Trace.into(), msg, extras })
}

///|
pub fn &Logger::debug(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Debug.into(), msg, extras })
}

///|
pub fn &Logger::info(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Info.into(), msg, extras })
}

///|
pub fn &Logger::warn(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Warn.into(), msg, extras })
}

///|
pub fn &Logger::error(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Error.into(), msg, extras })
}

///|
pub fn &Logger::fatal(
  self : &Logger,
  msg : String,
  extras? : Map[String, Json]
) -> Unit {
  self.log({ level: Fatal.into(), msg, extras })
}
