# Changelog

## 0.1.1 — review evidence, 2026-09-12

- Correct the ecosystem review to include tiye/json5 and explicitly acknowledge overlap.
- Add an audit example and three contract tests for existing source-preservation/replay/refusal behavior.
- Unify local and CI verification in a fail-fast Node script; record reproducibility evidence.
- Correct proposal technical facts and leave human-authored rationale for the applicant.
- No parser behavior changes; these additions are not in the published 0.1.0 archive.

## 0.1.0 — initial implementation

- Bounded recursive-descent JSON syntax validation, duplicate-key protection.
- Bare-key and single-quote recovery, comment and trailing-comma removal.
- Explicit opt-in container closure; no inferred missing scalar values.
- Original UTF-16 edit journal with replay validation.
- Per-line JSONL outcomes and Node CLI with bounded UTF-8 reads.
- Fixed and generated tests, runnable examples, multi-backend CI configuration.

Publication and CI status must be checked independently; this entry is not a
claim of competition acceptance or completed MoonCakes publication.
