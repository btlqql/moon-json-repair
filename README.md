# Moon JSON Repair

MoonBit JSON syntax repair with explicit edit records. Work in progress;
not yet published to MoonCakes or accepted by the September competition.

The intended boundary is syntax recovery, never invention of missing business
values. All offsets refer to UTF-16 code units in the original input. The API
accepts an explicit options value; it never reads environment variables or files.

Planned deliverables: a reusable library, JSONL processing, a command-line tool,
reproducible examples, tests, and CI. See development history for actual progress.

Package: `btlqql/moon_json_repair`. Repository owner: `btlqql`.
