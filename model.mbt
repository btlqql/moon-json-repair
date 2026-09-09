///|
/// An edit uses half-open UTF-16 offsets in the ORIGINAL input.
pub(all) struct Edit {
  start : Int
  end : Int
  replacement : String
  code : String
} derive(Eq, @debug.Debug, ToJson)

///|
/// Successful output is syntax-valid JSON, not schema-validated business data.
pub(all) struct RepairResult {
  output : String
  edits : Array[Edit]
} derive(Eq, @debug.Debug, ToJson)

///|
/// Stable refusal code and original UTF-16 offset; no input data in errors.
pub(all) suberror RepairError {
  Rejected(String, Int)
} derive(Eq, @debug.Debug)

///|
/// No heuristic is enabled in strict mode.
pub(all) struct Options {
  relaxed : Bool
  close_containers : Bool
  max_input : Int
  max_depth : Int
  max_edits : Int
} derive(Eq, @debug.Debug)

///|
pub fn Options::conservative() -> Options {
  {
    relaxed: true,
    close_containers: false,
    max_input: 1048576,
    max_depth: 128,
    max_edits: 10000,
  }
}

///|
pub fn Options::strict() -> Options {
  { ..Options::conservative(), relaxed: false, }
}
