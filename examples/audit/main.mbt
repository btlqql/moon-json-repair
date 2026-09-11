///|
fn main {
  let source = "{id:9007199254740993, n:1.2300e+02, label:'Moon',}"
  let result = try! @repair.repair(source)
  println("Input: " + source)
  println("Output: " + result.output)
  println("Original UTF-16 edit spans: " + result.to_json().stringify())
  let replayed = try! @repair.apply_edits(source, result.edits)
  println("Replay equals output: " + (replayed == result.output).to_string())
  let strict = try! @repair.repair(
    result.output,
    options=@repair.Options::strict(),
  )
  println("Strict recheck edits: " + strict.edits.length().to_string())
  try {
    ignore(@repair.repair("{\"role\":\"user\",\"role\":\"admin\"}"))
    println("Unexpected duplicate-key acceptance")
  } catch {
    @repair.Rejected(code, offset) => println("Refusal: \{code} at \{offset}")
  }
}
