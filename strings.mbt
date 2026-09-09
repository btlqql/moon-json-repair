///|
/// Single-quote recovery is lexical, never a global replacement.
fn Parser::single_string(self : Parser) -> String raise RepairError {
  let start = self.pos
  self.pos += 1
  let out = StringBuilder()
  out.write_string("\"")
  while self.peek() != -1 {
    let c = self.peek()
    self.pos += 1
    if c == 39 {
      out.write_string("\"")
      let candidate = out.to_string()
      let decoded = try {
        match @json.parse(candidate) {
          String(s) => s
          _ => raise Rejected("INVALID_STRING", start)
        }
      } catch {
        _ => raise Rejected("INVALID_STRING", start)
      }
      self.edit(start, self.pos, candidate, "SINGLE_QUOTE")
      return decoded
    } else if c == 92 {
      if self.peek() == -1 {
        raise Rejected("UNCLOSED_STRING", start)
      }
      if self.peek() > 127 {
        raise Rejected("INVALID_STRING", start)
      }
      if self.peek() == 39 {
        out.write_string("'")
      } else {
        out.write_string("\\")
        out.write_string(self.source[self.pos:self.pos + 1].to_owned())
      }
      self.pos += 1
    } else if c == 34 {
      out.write_string("\\\"")
    } else {
      if c >= 0xD800 &&
        c <= 0xDBFF &&
        self.peek() >= 0xDC00 &&
        self.peek() <= 0xDFFF {
        out.write_string(self.source[self.pos - 1:self.pos + 1].to_owned())
        self.pos += 1
        continue
      }
      out.write_string(self.source[self.pos - 1:self.pos].to_owned())
    }
  }
  raise Rejected("UNCLOSED_STRING", start)
}
