///|
fn boundary(input : String, pos : Int) -> Bool {
  if pos <= 0 || pos >= input.length() {
    return true
  }
  let left = input[pos - 1].to_int()
  let right = input[pos].to_int()
  !(left >= 0xD800 && left <= 0xDBFF && right >= 0xDC00 && right <= 0xDFFF)
}

///|
/// Replay ordered edits. Overlap, out-of-bounds and split-surrogate offsets fail.
pub fn apply_edits(
  input : String,
  edits : Array[Edit],
) -> String raise RepairError {
  let out = StringBuilder()
  let mut cursor = 0
  for edit in edits {
    if edit.start < cursor ||
      edit.end < edit.start ||
      edit.end > input.length() ||
      !boundary(input, edit.start) ||
      !boundary(input, edit.end) {
      raise Rejected("INVALID_EDIT", cursor)
    }
    out.write_string(input[cursor:edit.start].to_owned())
    out.write_string(edit.replacement)
    cursor = edit.end
  }
  out.write_string(input[cursor:].to_owned())
  out.to_string()
}

///|
fn Parser::edit(
  self : Parser,
  start : Int,
  end : Int,
  replacement : String,
  code : String,
) -> Unit raise RepairError {
  if self.edits.length() >= self.options.max_edits {
    raise Rejected("EDIT_LIMIT", start)
  }
  let e = Edit::{ start, end, replacement, code, }
  self.edits.push(e)
  let mut i = self.edits.length() - 1
  while i > 0 && self.edits[i - 1].start > start {
    self.edits[i] = self.edits[i - 1]
    i -= 1
  }
  self.edits[i] = e
}

///|
fn identifier_start(c : Int) -> Bool {
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 36
}

///|
fn Parser::key(self : Parser) -> String raise RepairError {
  if self.peek() == 39 && self.options.relaxed {
    return self.single_string()
  }
  if self.peek() == 34 {
    return self.string_token()
  }
  if !self.options.relaxed || !identifier_start(self.peek()) {
    raise Rejected("EXPECTED_KEY", self.pos)
  }
  let start = self.pos
  self.pos += 1
  while identifier_start(self.peek()) ||
        (self.peek() >= 48 && self.peek() <= 57) {
    self.pos += 1
  }
  let key = self.source[start:self.pos].to_owned()
  self.edit(start, self.pos, Json::string(key).stringify(), "QUOTE_KEY")
  key
}
