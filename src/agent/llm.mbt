// pub trait Llm {
//   async respond_to(Self) -> String
// }

///|
pub struct Message {
  content : String
  /// "user" | "system" | "assistant"
  role : String
} derive(Show, FromJson, ToJson)

///|
pub(all) struct Model {
  api_key : String
  base_url : String
  description : String?
  model : String
  name : String
} derive(Show, FromJson, ToJson)

///|
pub struct Polyglot {
  fetch_text_fn : FetchTextFn
  max_tokens : Int
  model : Model
}

///|
pub typealias FetchTextFn = async (String, Json) -> String!

///|
pub fn Polyglot::new(
  model : Model,
  max_tokens~ : Int = 1024,
  fetch_text_fn~ : FetchTextFn = fetch_text_fn_default
) -> Polyglot {
  { model, fetch_text_fn, max_tokens }
}

///|
pub async fn fetch_text_fn_default!(url : String, opts : Json) -> String {
  @jsext.fetch!!(url, opts~).text!!()
}

///|
pub type! LlmError String

///|
pub async fn Polyglot::respond_to!(
  self : Polyglot,
  message : String,
  role~ : String = "user"
) -> String {
  let wrapped_message = { content: message, role }
  let raw_response_text = self.fetch_response_text!!([wrapped_message])
  try {
    let raw_response = @json.parse!(raw_response_text)
    guard raw_response
      is {
        "choices": [{ "message": { "content": response_text, .. }, .. }, ..],
        ..
      } else {
      raise LlmError("unexpected raw_response format")
    }
    guard response_text.as_string() is Some(response_text) else {
      raise LlmError("response_text is not a string: found `\{response_text}`")
    }
    @log.g().trace(
      "[LLM] received response from `\{self.model.name}`:\n\{response_text}\n\n... for the following prompt:\n\{message}... ",
    )
    response_text
  } catch {
    e => {
      @log.g().error("[LLM] failed to parse response: \{raw_response_text}")
      raise e
    }
  }
}

///|
async fn Polyglot::fetch_response_text!(
  self : Polyglot,
  messages : Array[Message],
  stream~ : Bool = false
) -> String {
  let { max_tokens, model, .. } = self
  let mut messages = messages
  if model.model.starts_with("anthropic.") {
    // NOTE: Claude 3.5 Sonnet does not accept system role.
    // Convert to user role here.
    let normalized = []
    for msg in messages {
      normalized.push({
        ..msg,
        role: if msg.role == "system" {
          "user"
        } else {
          msg.role
        },
      })
    }
    messages = normalized
  }
  (self.fetch_text_fn)!!("\{model.base_url}/chat/completions", {
    "body": @json.stringify({
      "max_tokens": max_tokens.to_json(),
      "messages": messages.to_json(),
      "model": model.model.to_json(),
      "stream": stream.to_json(),
    }).to_json(),
    "headers": {
      "Authorization": "Bearer \{model.api_key}",
      "Content-Type": "application/json",
    },
    "method": "POST",
  })
}
