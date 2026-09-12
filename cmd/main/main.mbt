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
/// Streaming handles live only inside this CLI process. TextDecoder retains
/// incomplete UTF-8 sequences between reads, so MoonBit always receives valid
/// decoded chunks.
extern "js" fn open_stream(path : String) -> Int =
  #| (path) => {
  #|   try {
  #|     const fs = process.getBuiltinModule('node:fs');
  #|     const fd = path === '-' ? 0 : fs.openSync(path, 'r');
  #|     globalThis.__moonJsonRepairStreams ??= new Map();
  #|     globalThis.__moonJsonRepairNext ??= 1;
  #|     const id = globalThis.__moonJsonRepairNext++;
  #|     globalThis.__moonJsonRepairStreams.set(id, {
  #|       fd, own: fd !== 0, decoder: new TextDecoder('utf-8', {fatal:true, ignoreBOM:true}),
  #|       eof: false, failed: false
  #|     });
  #|     return id;
  #|   } catch { return -1; }
  #| }

///|
extern "js" fn read_stream_chunk(handle : Int) -> String? =
  #| (handle) => {
  #|   const state = globalThis.__moonJsonRepairStreams?.get(handle);
  #|   if (!state || state.failed || state.eof) return undefined;
  #|   try {
  #|     const fs = process.getBuiltinModule('node:fs');
  #|     while (true) {
  #|       const buffer = Buffer.allocUnsafe(65536);
  #|       const n = fs.readSync(state.fd, buffer, 0, buffer.length, null);
  #|       if (n === 0) {
  #|         state.eof = true;
  #|         const tail = state.decoder.decode();
  #|         return tail.length === 0 ? undefined : tail;
  #|       }
  #|       const text = state.decoder.decode(buffer.subarray(0, n), {stream:true});
  #|       if (text.length !== 0) return text;
  #|     }
  #|   } catch { state.failed = true; return undefined; }
  #| }

///|
extern "js" fn stream_failed(handle : Int) -> Bool =
  #| (handle) => globalThis.__moonJsonRepairStreams?.get(handle)?.failed === true

///|
extern "js" fn close_stream(handle : Int) -> Unit =
  #| (handle) => {
  #|   const streams = globalThis.__moonJsonRepairStreams;
  #|   const state = streams?.get(handle);
  #|   if (!state) return;
  #|   if (state.own) {
  #|     try { process.getBuiltinModule('node:fs').closeSync(state.fd); } catch {}
  #|   }
  #|   streams.delete(handle);
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
  let mut summary = false
  let mut path : String? = None
  let mut literal = false
  for i = 2; i < args.length(); i = i + 1 {
    let arg = args[i]
    if !literal && arg == "--help" {
      println(
        "Moon JSON Repair 0.2.0\nUsage: node main.js [--strict] [--close-containers] [--jsonl] [--summary] [--report] [--] [FILE|-]\nDefault: UTF-8 stdin, conservative repair, stdout only; never overwrites input.\nJSONL streams 64 KiB chunks and emits per-line records; --summary writes aggregate JSON to stderr.\nExit: 0 success, 1 refused/partial, 2 usage/IO.\n--close-containers guesses container endings only; review all edits before use.",
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
    } else if !literal && arg == "--summary" {
      summary = true
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
  if summary && !jsonl {
    stderr("USAGE_ERROR: --summary requires --jsonl")
    exit_code(2)
    return
  }
  let opts = {
    ..@repair.Options::conservative(),
    relaxed: !strict,
    close_containers: close,
  }
  try {
    if jsonl {
      let handle = open_stream(path.unwrap_or("-"))
      if handle < 0 {
        stderr("INPUT_ERROR: input cannot be opened")
        exit_code(2)
        return
      }
      let processor = @repair.JsonlProcessor::new(options=opts)
      while true {
        match read_stream_chunk(handle) {
          Some(chunk) =>
            for row in processor.push(chunk) {
              println(row.to_json().stringify())
              if row.error_code is Some(_) {
                exit_code(1)
              }
            }
          None => break
        }
      }
      let failed = stream_failed(handle)
      close_stream(handle)
      if failed {
        stderr("INPUT_ERROR: input read failed or contains malformed UTF-8")
        exit_code(2)
        return
      }
      for row in processor.finish() {
        println(row.to_json().stringify())
        if row.error_code is Some(_) {
          exit_code(1)
        }
      }
      if summary {
        stderr(processor.summary().to_json().stringify())
      }
    } else {
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
