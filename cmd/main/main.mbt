///|
/// Node is only used for IO. All repair decisions run in MoonBit.
extern "js" fn read_source(path : String) -> String? =
  #| (path) => {
  #|   let fd;
  #|   try {
  #|     const fs = process.getBuiltinModule('node:fs');
  #|     fd = path === '-' ? 0 : fs.openSync(path, 'r');
  #|     const chunks = []; let total = 0;
  #|     while (true) {
  #|       const chunk = Buffer.alloc(65536);
  #|       const n = fs.readSync(fd, chunk, 0, chunk.length, null);
  #|       if (n === 0) break;
  #|       total += n;
  #|       if (total > 4194304) return undefined;
  #|       chunks.push(chunk.subarray(0, n));
  #|     }
  #|     return new TextDecoder('utf-8', {fatal:true, ignoreBOM:true}).decode(Buffer.concat(chunks));
  #|   } catch { return undefined; }
  #|   finally {
  #|     if (fd !== undefined && fd !== 0) {
  #|       try { process.getBuiltinModule('node:fs').closeSync(fd); } catch {}
  #|     }
  #|   }
  #| }

///|
extern "js" fn exit_code(code : Int) -> Unit =
  #| (code) => { process.exitCode = code; }

///|
extern "js" fn stderr(text : String) -> Unit =
  #| (text) => { process.stderr.write(text + '\n'); }

///|
fn run() -> Unit {
  let args = @env.args()
  let mut strict = false
  let mut close = false
  let mut jsonl = false
  let mut report = false
  let mut path : String? = None
  let mut literal = false
  for i = 2; i < args.length(); i = i + 1 {
    let arg = args[i]
    if !literal && arg == "--help" {
      println(
        "Moon JSON Repair 0.1.0\nUsage: node main.js [--strict] [--close-containers] [--jsonl] [--report] [--] [FILE|-]\nDefault: UTF-8 stdin, conservative repair, stdout only; never overwrites input.\nJSONL always emits per-line report records. Exit: 0 success, 1 refused/partial, 2 usage/IO.\n--close-containers guesses container endings only; review all edits before use.",
      )
      return
    } else if !literal && arg == "--strict" {
      strict = true
    } else if !literal && arg == "--close-containers" {
      close = true
    } else if !literal && arg == "--jsonl" {
      jsonl = true
    } else if !literal && arg == "--report" {
      report = true
    } else if !literal && arg == "--" {
      literal = true
    } else if (!literal && arg.has_prefix("-") && arg != "-") || path is Some(_) {
      stderr("USAGE_ERROR: use --help; only one input is accepted")
      exit_code(2)
      return
    } else {
      path = Some(arg)
    }
  }
  if strict && close {
    stderr("USAGE_ERROR: --strict conflicts with --close-containers")
    exit_code(2)
    return
  }
  let input = match read_source(path.unwrap_or("-")) {
    Some(s) => s
    None => {
      stderr(
        "INPUT_ERROR: unreadable input, invalid UTF-8, unsupported Node runtime, or byte limit exceeded",
      )
      exit_code(2)
      return
    }
  }
  let opts = {
    ..@repair.Options::conservative(),
    relaxed: !strict,
    close_containers: close,
  }
  try {
    if jsonl {
      let rows = @repair.repair_jsonl(input, options=opts)
      for row in rows {
        println(row.to_json().stringify())
        if row.error_code is Some(_) {
          exit_code(1)
        }
      }
    } else {
      let result = @repair.repair(input, options=opts)
      if report {
        println(result.to_json().stringify())
      } else {
        println(result.output)
      }
    }
  } catch {
    @repair.Rejected(code, offset) => {
      stderr(({ "error": code, "offset": offset } : Json).stringify())
      exit_code(1)
    }
  }
}

///|
fn main {
  run()
}
