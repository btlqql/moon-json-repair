///|
test "single quotes preserve punctuation, Unicode, and escapes" {
  for
    (source, expected) in [
      ("{'name':'Moon'}", "{\"name\":\"Moon\"}"),
      ("'can\\'t'", "\"can't\""),
      ("'say \"hi\"'", "\"say \\\"hi\\\"\""),
      ("'中文😀'", "\"中文😀\""),
      ("'\\n\\t\\u0041'", "\"\\n\\t\\u0041\""),
      ("'https://a/*literal*/'", "\"https://a/*literal*/\""),
    ] {
    let r = repair(source)
    assert_eq(r.output, expected)
    assert_eq(apply_edits(source, r.edits), expected)
    assert_eq(repair(expected).edits.length(), 0)
  }
}

///|
test "strings are never guessed or blindly unescaped" {
  for
    source in [
      "'unfinished", "'bad\\x41'", "'line\nbreak'", "\"unfinished", "\"bad\\q\"",
    ] {
    let rejected = try {
      ignore(repair(source))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}
