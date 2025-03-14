///|
pub(all) type JsonOption[A] A? derive(Show)

///|
pub impl[A : @json.FromJson] @json.FromJson for JsonOption[A] with from_json(
  json,
  path
) {
  match json {
    Json::Null => None
    other => Some(@json.from_json!(other, path~))
  }
}

///|
pub impl[A : ToJson] ToJson for JsonOption[A] with to_json(self) {
  match self._ {
    None => Json::Null
    Some(value) => value.to_json()
  }
}
