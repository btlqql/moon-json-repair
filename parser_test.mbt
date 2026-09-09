///|
test "valid JSON is unchanged, including large integers and Unicode" {
  for
    source in [
      "null", "true", "-0", "1e+42", "9007199254740993", " [1, false, null, {\"中文😀\":\"ok\"}] \n",
      "{}", "[]",
    ] {
    let r = repair(source)
    assert_eq(r.output, source)
    assert_eq(r.edits.length(), 0)
  }
}

///|
test "strict refusal and duplicate key protection" {
  for
    source in [
      "", "[1,]", "{a:1}", "{'a':1}", "01", "NaN", "[1 2]", "{\"x\":}", "{\"x\":1,\"x\":2}",
      "{\"x\":1,\"\\u0078\":2}", "true false",
    ] {
    let rejected = try {
      ignore(repair(source, options=Options::strict()))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}
