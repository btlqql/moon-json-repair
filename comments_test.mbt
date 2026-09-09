///|
test "comments and trailing commas produce nonoverlapping edits" {
  for
    (s, expected) in [
      ("[1,]", "[1]"),
      ("{x:1,}", "{\"x\":1}"),
      ("[1,/* note */ ]", "[1  ]"),
      ("/*start*/[1//note\n,2]//end", " [1 \n,2] "),
      ("{a:/*value*/true}", "{\"a\": true}"),
    ] {
    let r = repair(s)
    assert_eq(r.output, expected)
    assert_eq(apply_edits(s, r.edits), expected)
    assert_eq(repair(r.output).edits.length(), 0)
  }
}

///|
test "comments do not modify strings or join values" {
  let literal = "{\"url\":\"https://a/*b*/\"}"
  assert_eq(repair(literal).output, literal)
  for s in ["1/*x*/2", "[1,,2]", "[/*", "//only comment", "[1,/*x*/]"] {
    let refused = try {
      ignore(repair(s, options=Options::strict()))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
  }
  for s in ["1/*x*/2", "[1,,2]", "[/*", "//only comment"] {
    let refused = try {
      ignore(repair(s))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
  }
}
