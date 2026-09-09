///|
test "generated malformed inputs preserve repair invariants" {
  let alphabet = "{}[],:\"'ab01 true/\\\n*"
  let mut seed : UInt = 124578
  for trial = 0; trial < 3000; trial = trial + 1 {
    let b = StringBuilder()
    let count = trial % 55
    for _i = 0; _i < count; _i = _i + 1 {
      seed = seed * 1664525U + 1013904223U
      let index = (seed % alphabet.length().reinterpret_as_uint()).reinterpret_as_int()
      b.write_string(alphabet[index:index + 1].to_owned())
    }
    let source = b.to_string()
    let result = Some(
      repair(source, options={
        ..Options::conservative(),
        close_containers: true,
      }),
    ) catch {
      _ => None
    }
    if result is Some(r) {
      assert_true(@json.valid(r.output))
      assert_eq(apply_edits(source, r.edits), r.output)
      assert_eq(repair(r.output, options=Options::strict()).output, r.output)
      assert_eq(repair(r.output).edits.length(), 0)
    }
  }
}

///|
test "generated nested objects exercise successful repairs" {
  for i = 0; i < 100; i = i + 1 {
    let source = "{name:'item\{i}', data:[\{i}, true, /*note*/],}"
    let r = repair(source)
    assert_true(@json.valid(r.output))
    assert_eq(r.edits.length(), 6)
    assert_eq(apply_edits(source, r.edits), r.output)
    assert_eq(repair(r.output).edits.length(), 0)
  }
}

///|
test "mismatched delimiters and truncated scalar tokens never succeed" {
  for
    s in [
      "[1}", "{a:1]", "{a 1}", "[1 2]", "{a:NaN}", "{a:Infinity}", "{a:True}", "{a:None}",
      "[1e+]", "[--2]", "{a:undefined}", "[+1]", "```json\n{}\n```", "prefix {}",
      "{} {}", "[0x10]", "[.5]", "[1.]",
    ] {
    let refused = try {
      ignore(repair(s))
      false
    } catch {
      _ => true
    }
    assert_true(refused)
  }
}
