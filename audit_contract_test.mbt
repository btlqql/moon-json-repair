///|
test "audit contract preserves original whitespace and numeric spelling" {
  let source = " {\"id\":9007199254740993, \"n\":1.2300e+02} \n"
  let result = repair(source)
  assert_eq(result.output, source)
  assert_eq(result.edits.length(), 0)
  let relaxed = "{id:9007199254740993, n:1.2300e+02,}"
  let fixed = repair(relaxed)
  assert_eq(fixed.output, "{\"id\":9007199254740993, \"n\":1.2300e+02}")
  assert_eq(apply_edits(relaxed, fixed.edits), fixed.output)
}

///|
test "audit contract replays mixed repairs against original UTF-16 input" {
  let source = "{label:'😀', /* note */ enabled:true,}"
  let result = repair(source)
  assert_eq(apply_edits(source, result.edits), result.output)
  assert_eq(repair(result.output).edits.length(), 0)
  assert_true(result.edits.any(e => e.code == "REMOVE_COMMENT"))
  assert_true(result.edits.any(e => e.code == "SINGLE_QUOTE"))
  assert_true(result.edits.any(e => e.code == "TRAILING_COMMA"))
}

///|
test "audit contract refuses duplicate keys instead of selecting a value" {
  let rejected = try {
    ignore(repair("{\"role\":\"user\",\"role\":\"admin\"}"))
    false
  } catch {
    Rejected("DUPLICATE_KEY", offset) => offset > 0
    _ => false
  }
  assert_true(rejected)
}
