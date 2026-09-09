///|
priv struct Parser {
  source : String
  options : Options
  mut pos : Int
  edits : Array[Edit]
}

///|
fn Parser::peek(self : Parser) -> Int {
  if self.pos >= self.source.length() {
    -1
  } else {
    self.source[self.pos].to_int()
  }
}

///|
fn Parser::skip_space(self : Parser) -> Unit raise RepairError {
  while true {
    while self.peek() == 32 ||
          self.peek() == 9 ||
          self.peek() == 10 ||
          self.peek() == 13 {
      self.pos += 1
    }
    if !self.options.relaxed ||
      self.peek() != 47 ||
      self.pos + 1 >= self.source.length() {
      return
    }
    let start = self.pos
    let next = self.source[self.pos + 1].to_int()
    if next == 47 {
      self.pos += 2
      while self.peek() != -1 && self.peek() != 10 && self.peek() != 13 {
        self.pos += 1
      }
    } else if next == 42 {
      self.pos += 2
      while true {
        if self.peek() == -1 {
          raise Rejected("UNCLOSED_COMMENT", start)
        }
        if self.peek() == 42 &&
          self.pos + 1 < self.source.length() &&
          self.source[self.pos + 1].to_int() == 47 {
          self.pos += 2
          break
        }
        self.pos += 1
      }
    } else {
      return
    }
    self.edit(start, self.pos, " ", "REMOVE_COMMENT")
  }
}

///|
fn Parser::string_token(self : Parser) -> String raise RepairError {
  let start = self.pos
  self.pos += 1
  while self.peek() != -1 {
    let c = self.peek()
    self.pos += 1
    if c == 92 {
      if self.peek() == -1 {
        raise Rejected("UNCLOSED_STRING", start)
      }
      self.pos += 1
    } else if c == 34 {
      let raw = self.source[start:self.pos].to_owned()
      try {
        match @json.parse(raw) {
          String(s) => return s
          _ => raise Rejected("INVALID_STRING", start)
        }
      } catch {
        _ => raise Rejected("INVALID_STRING", start)
      }
    }
  }
  raise Rejected("UNCLOSED_STRING", start)
}

///|
fn Parser::value(self : Parser, depth : Int) -> Unit raise RepairError {
  self.skip_space()
  match self.peek() {
    123 => self.object(depth + 1)
    91 => self.array(depth + 1)
    34 => ignore(self.string_token())
    39 if self.options.relaxed => ignore(self.single_string())
    -1 => raise Rejected("MISSING_VALUE", self.pos)
    _ => {
      let start = self.pos
      while self.peek() != -1 &&
            self.peek() != 44 &&
            self.peek() != 93 &&
            self.peek() != 125 &&
            self.peek() != 32 &&
            self.peek() != 9 &&
            self.peek() != 10 &&
            self.peek() != 13 &&
            self.peek() != 47 {
        self.pos += 1
      }
      let token = self.source[start:self.pos].to_owned()
      if token.length() == 0 || !@json.valid(token) {
        raise Rejected("INVALID_VALUE", start)
      }
    }
  }
}

///|
fn Parser::object(self : Parser, depth : Int) -> Unit raise RepairError {
  if depth > self.options.max_depth {
    raise Rejected("DEPTH_LIMIT", self.pos)
  }
  self.pos += 1
  self.skip_space()
  if self.peek() == 125 {
    self.pos += 1
    return
  }
  let keys : Map[String, Bool] = Map([])
  while true {
    self.skip_space()
    let key_pos = self.pos
    let key = self.key()
    if keys.contains(key) {
      raise Rejected("DUPLICATE_KEY", key_pos)
    }
    keys[key] = true
    self.skip_space()
    if self.peek() != 58 {
      raise Rejected("EXPECTED_COLON", self.pos)
    }
    self.pos += 1
    self.value(depth)
    self.skip_space()
    match self.peek() {
      125 => {
        self.pos += 1
        return
      }
      44 => {
        let comma = self.pos
        self.pos += 1
        self.skip_space()
        if self.peek() == 125 && self.options.relaxed {
          self.edit(comma, comma + 1, "", "TRAILING_COMMA")
          self.pos += 1
          return
        }
      }
      _ => raise Rejected("EXPECTED_OBJECT_END", self.pos)
    }
  }
}

///|
fn Parser::array(self : Parser, depth : Int) -> Unit raise RepairError {
  if depth > self.options.max_depth {
    raise Rejected("DEPTH_LIMIT", self.pos)
  }
  self.pos += 1
  self.skip_space()
  if self.peek() == 93 {
    self.pos += 1
    return
  }
  while true {
    self.value(depth)
    self.skip_space()
    match self.peek() {
      93 => {
        self.pos += 1
        return
      }
      44 => {
        let comma = self.pos
        self.pos += 1
        self.skip_space()
        if self.peek() == 93 && self.options.relaxed {
          self.edit(comma, comma + 1, "", "TRAILING_COMMA")
          self.pos += 1
          return
        }
      }
      _ => raise Rejected("EXPECTED_ARRAY_END", self.pos)
    }
  }
}

///|
/// Valid input is preserved exactly, including number spelling and whitespace.
pub fn repair(
  input : String,
  options? : Options = Options::conservative(),
) -> RepairResult raise RepairError {
  if options.max_input < 0 ||
    options.max_depth < 1 ||
    options.max_depth > 256 ||
    options.max_edits < 0 {
    raise Rejected("INVALID_OPTIONS", 0)
  }
  if input.length() > options.max_input {
    raise Rejected("INPUT_LIMIT", 0)
  }
  let p = Parser::{ source: input, options, pos: 0, edits: [], }
  p.value(0)
  p.skip_space()
  if p.peek() != -1 {
    raise Rejected("EXTRA_CONTENT", p.pos)
  }
  { output: apply_edits(input, p.edits), edits: p.edits, }
}
