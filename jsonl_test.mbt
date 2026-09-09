///|
test "JSONL keeps failure rows and physical line numbers" {
  let rows = repair_jsonl("{a:1}\r\n{b:}\n\n[true,]\n")
  assert_eq(rows.length(), 4)
  assert_eq(rows[0].output, Some("{\"a\":1}\r"))
  assert_eq(rows[1].line, 2)
  assert_true(rows[1].error_code is Some(_))
  assert_true(rows[2].error_code is Some(_))
  assert_eq(rows[3].output, Some("[true]"))
  assert_eq(repair_jsonl("").length(), 0)
  assert_eq(repair_jsonl("\n").length(), 1)
}

///|
test "JSONL cannot silently exceed its batch limit" {
  let refused = try {
    ignore(repair_jsonl("1\n2", max_lines=1))
    false
  } catch {
    _ => true
  }
  assert_true(refused)
}
