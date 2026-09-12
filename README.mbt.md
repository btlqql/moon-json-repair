# Moon JSON Repair

Conservative JSON syntax recovery with replayable edits. Pure MoonBit core,
zero third-party package dependencies. A Node 24 CLI is included under `cmd/main`.
No claim of full JSON5 or jsonrepair compatibility.

## Consumer example

After adding `btlqql/moon_json_repair@0.1.1`, import it in your `moon.pkg`:

```text
import {
  "btlqql/moon_json_repair" @repair,
}
```

```moonbit nocheck
///|
fn main {
  let result = try! @repair.repair("{name:'Moon',}")
  println(result.output)
  println(result.to_json().stringify())
}
```

The source repository contains this working example in `examples/basic`.

## Public API

- `repair(input, options?) -> RepairResult raise RepairError`
- `apply_edits(input, edits) -> String raise RepairError`
- `repair_jsonl(input, options?, max_lines?) -> Array[LineResult] raise RepairError`
- `JsonlProcessor::new(options?, max_lines?, max_line?) -> JsonlProcessor`
- `JsonlProcessor::push(chunk)`, `finish()`, and `summary()`
- `Options::conservative()` and `Options::strict()`

`RepairResult` contains output and edits. An `Edit` has start/end (half-open
UTF-16 offsets in the original input), replacement, and a stable code. Multiple
insertions at the same position are applied in array order, inner container first.
Replay validates ranges and refuses overlaps and surrogate-pair splitting.
Edits are NOT bound cryptographically to their source; callers must retain and
use the exact original input. Do not apply them to a different revision.

Default repair limits: 1,048,576 UTF-16 code units, depth 128 (configurable
1..256), and 10,000 edits. The batch JSONL API retains a 10,000-line default
and bounds the whole input. `JsonlProcessor` instead retains only the current
line, defaults to 1,000,000 lines and 1,048,576 code units per line, and emits
an explicit `LINE_INPUT_LIMIT` result before continuing with later lines.
The Node CLI streams JSONL in decoded 64 KiB byte chunks; non-JSONL CLI input
remains capped at 4 MiB. Malformed UTF-8 is rejected in both modes.

`relaxed` enables bare ASCII identifier keys, single-quoted strings, comments,
and trailing commas. `close_containers` defaults false and only works when
relaxed mode is enabled. It can close containers after a complete value at EOF;
it never completes strings, literals, empty containers, or values after commas.
Missing middle commas/colons/values, duplicate keys, and extra root content fail.
Numbers are not round-tripped through floating-point serialization.

Failures raise `Rejected(code, offset)` without echoing source data. JSONL reports
line-local offsets and one-based physical line numbers; a trailing newline is
not an extra record. Blank interior lines fail. In JSON reports, absent optional
fields are omitted: success has `output`, failure has `error_code/error_offset`.
`JsonlSummary` reports lines, accepted, repaired, unchanged, rejected, and edits.

Repair success only establishes JSON syntax. It does not establish original
intent, schema validity, authorization, or safe tool arguments. Review edits and
validate schema and policy before consuming repaired data.

License: Apache-2.0. See repository `docs/provenance.md` for design references,
ecosystem overlap findings, and AI-assisted development disclosure.
