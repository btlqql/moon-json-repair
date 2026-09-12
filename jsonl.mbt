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
/// Aggregate counters for an incremental JSONL import. Counters describe
/// physical records emitted so far; rejected records are never silently lost.
pub(all) struct JsonlSummary {
  lines : Int
  accepted : Int
  repaired : Int
  unchanged : Int
  rejected : Int
  edits : Int
} derive(Eq, @debug.Debug, ToJson)

///|
/// Stateful, bounded JSONL processor. Text chunks may end anywhere, including
/// between CR and LF. Only the current physical line is retained.
pub struct JsonlProcessor {
  options : Options
  max_lines : Int
  max_line : Int
  mut pending : String
  mut overlong : Bool
  mut saw_input : Bool
  mut ended_with_lf : Bool
  mut finished : Bool
  mut lines : Int
  mut accepted : Int
  mut repaired : Int
  mut unchanged : Int
  mut rejected : Int
  mut edits : Int
}

///|
pub fn JsonlProcessor::new(
  options? : Options = Options::conservative(),
  max_lines? : Int = 1000000,
  max_line? : Int = 1048576,
) -> JsonlProcessor raise RepairError {
  if max_lines < 1 || max_line < 1 || max_line > options.max_input {
    raise Rejected("INVALID_OPTIONS", 0)
  }
  {
    options,
    max_lines,
    max_line,
    pending: "",
    overlong: false,
    saw_input: false,
    ended_with_lf: false,
    finished: false,
    lines: 0,
    accepted: 0,
    repaired: 0,
    unchanged: 0,
    rejected: 0,
    edits: 0,
  }
}

///|
fn JsonlProcessor::emit_line(
  self : JsonlProcessor,
) -> LineResult raise RepairError {
  if self.lines >= self.max_lines {
    raise Rejected("LINE_LIMIT", self.lines)
  }
  self.lines = self.lines + 1
  let row = if self.overlong {
    LineResult::{
      line: self.lines,
      output: None,
      edits: [],
      error_code: Some("LINE_INPUT_LIMIT"),
      error_offset: Some(self.max_line),
    }
  } else {
    try {
      let result = repair(self.pending, options=self.options)
      LineResult::{
        line: self.lines,
        output: Some(result.output),
        edits: result.edits,
        error_code: None,
        error_offset: None,
      }
    } catch {
      Rejected(code, offset) =>
        LineResult::{
          line: self.lines,
          output: None,
          edits: [],
          error_code: Some(code),
          error_offset: Some(offset),
        }
    }
  }
  if row.output is Some(_) {
    self.accepted = self.accepted + 1
    self.edits = self.edits + row.edits.length()
    if row.edits.length() == 0 {
      self.unchanged = self.unchanged + 1
    } else {
      self.repaired = self.repaired + 1
    }
  } else {
    self.rejected = self.rejected + 1
  }
  self.pending = ""
  self.overlong = false
  row
}

///|
/// Feed one decoded text chunk and return only the complete records produced by
/// this call. A line that exceeds max_line is discarded until LF, then emitted
/// as LINE_INPUT_LIMIT so later records can still be processed.
pub fn JsonlProcessor::push(
  self : JsonlProcessor,
  chunk : String,
) -> Array[LineResult] raise RepairError {
  if self.finished {
    raise Rejected("PROCESSOR_FINISHED", self.lines)
  }
  if chunk.length() == 0 {
    return []
  }
  self.saw_input = true
  self.ended_with_lf = false
  let rows : Array[LineResult] = []
  let mut start = 0
  for i = 0; i < chunk.length(); i = i + 1 {
    if chunk[i] == 10 {
      if !self.overlong {
        let segment = chunk[start:i].to_owned()
        if self.pending.length() + segment.length() > self.max_line {
          self.pending = ""
          self.overlong = true
        } else {
          self.pending = self.pending + segment
        }
      }
      rows.push(self.emit_line())
      start = i + 1
      self.ended_with_lf = true
    }
  }
  if start < chunk.length() {
    if !self.overlong {
      let segment = chunk[start:chunk.length()].to_owned()
      if self.pending.length() + segment.length() > self.max_line {
        self.pending = ""
        self.overlong = true
      } else {
        self.pending = self.pending + segment
      }
    }
    self.ended_with_lf = false
  }
  rows
}

///|
/// Flush the final unterminated record. Calling finish twice is rejected.
pub fn JsonlProcessor::finish(
  self : JsonlProcessor,
) -> Array[LineResult] raise RepairError {
  if self.finished {
    raise Rejected("PROCESSOR_FINISHED", self.lines)
  }
  self.finished = true
  if self.saw_input && !self.ended_with_lf {
    [self.emit_line()]
  } else {
    []
  }
}

///|
pub fn JsonlProcessor::summary(self : JsonlProcessor) -> JsonlSummary {
  {
    lines: self.lines,
    accepted: self.accepted,
    repaired: self.repaired,
    unchanged: self.unchanged,
    rejected: self.rejected,
    edits: self.edits,
  }
}

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
