# Design and boundaries

The parser walks the original UTF-16 string with a cursor. Objects and arrays
use bounded recursive descent. String escapes are validated by MoonBit core's
JSON parser. Scalar spellings are validated but never rewritten through Double.
Object keys are decoded to detect duplicate names, including escaped aliases.

Edits form a separate journal. On successful parse, `apply_edits` constructs
the output from unchanged source slices and replacements. On failure, no partial
output is returned. Late removal of a comma before comments uses ordered edit
insertion; EOF insertions retain their inner-to-outer order.

Rules are intentionally narrower than general-purpose heuristic JSON repair.
The first release does not insert missing middle commas or values, close strings,
unwrap Markdown fences, merge root documents, convert Python literals, support
JSONP, or evaluate expressions. Container closure is opt-in because a truncated
number may still be a complete JSON token, e.g. `12` could have been `123`.

Limits bound recursion, input, line count, per-line size, and edit count. The
batch API keeps its aggregate bound; `JsonlProcessor` is a state machine that
retains only the incomplete current line, emits complete records per push, and
discards an overlong record until LF before continuing. The core does no IO;
the JS host incrementally decodes JSONL in 64 KiB chunks and writes output/exit status. It never
executes input, performs network calls, or automatically overwrites source files.
Success reports contain source-derived replacement data and repaired values;
treat reports as sensitive whenever input is sensitive. Error messages do not
echo input. Downstream schema checks and permission checks remain mandatory.

Testing layers:

1. Fixed regression cases for each rule and each refusal boundary.
2. Replay, idempotence, strict reparse and valid-output invariants on deterministic
   generated data, including successful combinations.
3. CLI integration using Node's independent JSON parser to inspect output.
4. A deterministic 2,000-record import scenario validates line conservation,
   replay, failure isolation, and continuation after an overlong line.
5. CI check/build/test across four MoonBit backends; CLI uses Node 24.

These tests are not a proof of complete JSON standard conformance. Differential
compatibility with upstream jsonrepair has not been claimed or completed.
