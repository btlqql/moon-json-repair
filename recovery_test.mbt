///|
test "container closure is explicit opt-in and replay order is inner first" {
  let opts = { ..Options::conservative(), close_containers: true, }
  for
    (s, expected) in [
      ("[1", "[1]"),
      ("{a:[1,{b:true", "{\"a\":[1,{\"b\":true}]}"),
    ] {
    let refused = try {
      ignore(repair(s))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
    let r = repair(s, options=opts)
    assert_eq(r.output, expected)
    assert_eq(apply_edits(s, r.edits), expected)
    assert_eq(repair(expected).edits.length(), 0)
  }
}

///|
test "closure does not fabricate missing values or finish tokens" {
  let opts = { ..Options::conservative(), close_containers: true, }
  for s in ["{", "[", "{a:", "[1,", "[tru", "[1e", "['abc", "[1}", "{a:1]"] {
    let refused = try {
      ignore(repair(s, options=opts))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
  }
}

///|
test "resource limits fail explicitly" {
  for
    (s, opts) in [
      ("null", { ..Options::conservative(), max_input: 3, }),
      ("[[1]]", { ..Options::conservative(), max_depth: 1, }),
      ("{a:1}", { ..Options::conservative(), max_edits: 0, }),
      ("null", { ..Options::conservative(), max_depth: 257, }),
      ("null", { ..Options::conservative(), max_edits: -1, }),
    ] {
    let refused = try {
      ignore(repair(s, options=opts))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
  }
}
