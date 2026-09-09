///|
fn main {
  let source = "{name:'Moon', enabled:true,}"
  try {
    let result = @repair.repair(source)
    println(result.output)
    println(result.to_json().stringify())
  } catch {
    @repair.Rejected(code, offset) => println("\{code} at \{offset}")
  }
}
