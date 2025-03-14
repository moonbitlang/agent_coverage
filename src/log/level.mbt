///|
pub type Level Int derive(Show, Eq, Compare)

///|
pub impl ToJson for Level with to_json(self) {
  self._.to_json()
}

///|
pub trait IntoLevel {
  into(Self) -> Level
}

///|
pub impl IntoLevel for Level with into(self) -> Level {
  self
}

///|
pub enum PresetLogLevel {
  Trace
  Debug
  Info
  Warn
  Error
  Fatal
} derive(Show, Eq, Compare)

///|
pub impl IntoLevel for PresetLogLevel with into(self) -> Level {
  Level::from_preset(self)
}

///|
pub fn Level::from_preset(p : PresetLogLevel) -> Level {
  match p {
    Trace => 10
    Debug => 20
    Info => 30
    Warn => 40
    Error => 50
    Fatal => 60
  }
}
