///|
test "incremental JSONL accepts arbitrary chunk boundaries and reports summary" {
  let stream = JsonlProcessor::new(max_line=64)
  let rows : Array[LineResult] = []
  rows.append(stream.push("{id:1}\r"))
  rows.append(stream.push("\n{\"id\":2}\n{bad:"))
  rows.append(stream.push("}\n"))
  rows.append(stream.finish())
  assert_eq(rows.length(), 3)
  assert_eq(rows[0].line, 1)
  assert_eq(rows[0].output, Some("{\"id\":1}\r"))
  assert_eq(rows[1].output, Some("{\"id\":2}"))
  assert_eq(rows[2].output, None)
  assert_eq(rows[2].error_code, Some("INVALID_VALUE"))
  assert_eq(stream.summary(), JsonlSummary::{
    lines: 3,
    accepted: 2,
    repaired: 1,
    unchanged: 1,
    rejected: 1,
    edits: 1,
  })
}

///|
test "overlong JSONL record is isolated and later records continue" {
  let stream = JsonlProcessor::new(max_line=8)
  let rows : Array[LineResult] = []
  rows.append(stream.push("{long_key:"))
  rows.append(stream.push("12345}\n{a:"))
  rows.append(stream.push("1}\n"))
  rows.append(stream.finish())
  assert_eq(rows.length(), 2)
  assert_eq(rows[0].error_code, Some("LINE_INPUT_LIMIT"))
  assert_eq(rows[0].error_offset, Some(8))
  assert_eq(rows[1].output, Some("{\"a\":1}"))
  assert_eq(stream.summary().rejected, 1)
  assert_eq(stream.summary().accepted, 1)
}

///|
test "unterminated final record is flushed exactly once" {
  let stream = JsonlProcessor::new()
  assert_eq(stream.push("{a:1}"), [])
  assert_eq(stream.finish().length(), 1)
  let finished_refused = try {
    ignore(stream.finish())
    false
  } catch {
    Rejected(code, offset) => code == "PROCESSOR_FINISHED" && offset == 1
  }
  assert_true(finished_refused)
  let late_refused = try {
    ignore(stream.push("\n"))
    false
  } catch {
    Rejected(code, offset) => code == "PROCESSOR_FINISHED" && offset == 1
  }
  assert_true(late_refused)
}

///|
test "empty input and trailing LF do not create phantom records" {
  let empty = JsonlProcessor::new()
  assert_eq(empty.finish(), [])
  let ended = JsonlProcessor::new()
  assert_eq(ended.push("{a:1}\n").length(), 1)
  assert_eq(ended.finish(), [])
  assert_eq(ended.summary().lines, 1)
}

///|
test "stream line limit is enforced across pushes" {
  let stream = JsonlProcessor::new(max_lines=2)
  assert_eq(stream.push("1\n2\n").length(), 2)
  let refused = try {
    ignore(stream.push("3\n"))
    false
  } catch {
    Rejected(code, offset) => code == "LINE_LIMIT" && offset == 2
  }
  assert_true(refused)
}

///|
test "invalid incremental options are rejected" {
  let zero_refused = try {
    ignore(JsonlProcessor::new(max_line=0))
    false
  } catch {
    Rejected(code, offset) => code == "INVALID_OPTIONS" && offset == 0
  }
  assert_true(zero_refused)
  let small = { ..Options::conservative(), max_input: 4, }
  let mismatch_refused = try {
    ignore(JsonlProcessor::new(options=small, max_line=5))
    false
  } catch {
    Rejected(code, offset) => code == "INVALID_OPTIONS" && offset == 0
  }
  assert_true(mismatch_refused)
}
