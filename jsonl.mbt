///|
/// One JSONL line's result. Error offsets and edit ranges are line-local UTF-16.
pub(all) struct LineResult {
  line : Int
  output : String?
  edits : Array[Edit]
  error_code : String?
  error_offset : Int?
} derive(Eq, @debug.Debug, ToJson)

///|
/// Process each physical line independently; blank interior lines are errors.
/// A final newline does not create a phantom record. Aggregate input is bounded.
pub fn repair_jsonl(
  input : String,
  options? : Options = Options::conservative(),
  max_lines? : Int = 10000,
) -> Array[LineResult] raise RepairError {
  if max_lines < 1 {
    raise Rejected("INVALID_OPTIONS", 0)
  }
  if input.length() > options.max_input {
    raise Rejected("INPUT_LIMIT", 0)
  }
  if input.length() == 0 {
    return []
  }
  let lines = input.split("\n").to_array()
  let count = if input.has_suffix("\n") {
    lines.length() - 1
  } else {
    lines.length()
  }
  if count > max_lines {
    raise Rejected("LINE_LIMIT", 0)
  }
  let result : Array[LineResult] = []
  for i = 0; i < count; i = i + 1 {
    let row = try {
      let r = repair(lines[i].to_owned(), options~)
      LineResult::{
        line: i + 1,
        output: Some(r.output),
        edits: r.edits,
        error_code: None,
        error_offset: None,
      }
    } catch {
      Rejected(code, offset) =>
        {
          line: i + 1,
          output: None,
          edits: [],
          error_code: Some(code),
          error_offset: Some(offset),
        }
    }
    result.push(row)
  }
  result
}
