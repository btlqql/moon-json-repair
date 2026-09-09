///|
test "bare keys are quoted with replayable original spans" {
  let source = "{alpha: 1, _b2: true}"
  let r = repair(source)
  assert_eq(r.output, "{\"alpha\": 1, \"_b2\": true}")
  assert_eq(r.edits.length(), 2)
  assert_eq(r.edits[0].start, 1)
  assert_eq(r.edits[0].end, 6)
  assert_eq(apply_edits(source, r.edits), r.output)
  assert_eq(repair(r.output).edits.length(), 0)
}

///|
test "invalid edit ranges including surrogate splits are refused" {
  for
    e in [
      Edit::{ start: -1, end: 0, replacement: "", code: "TEST", },
      Edit::{ start: 3, end: 2, replacement: "", code: "TEST", },
      Edit::{ start: 0, end: 100, replacement: "", code: "TEST", },
      Edit::{ start: 1, end: 1, replacement: "", code: "TEST", },
    ] {
    let rejected = try {
      ignore(apply_edits("😀x", [e]))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}
