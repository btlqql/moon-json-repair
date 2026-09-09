# Ecosystem review and provenance

Checked on 2026-09-09. Search results can change and are not proof of absence.

- MoonCakes live search: `jsonrepair`, `json-repair`, `repair`, `json5`, `hjson`.
  No dedicated `jsonrepair` module was found in the returned results. Fuzzy JSON
  searches returned capped results, so they cannot be called exhaustive.
- GitHub repository/code searches included `json repair language:MoonBit`,
  `jsonrepair language:MoonBit`, `repair_json language:MoonBit`, and JSON5.
- [MBOpenClacky tool executor](https://github.com/hnlyxiaobing/MBOpenClacky/blob/c4b3fa4bcaceb8848bd4037b91dfdde9f5985fe4/lib/agent/tool_executor.mbt)
  contains a bounded internal repair helper for tool arguments. Its source was
  inspected during overlap review. The new library focuses on public reusable
  APIs, ordered original-input edit spans, explicit refusal boundaries, JSONL,
  and host-independent tests. It must not be described as MoonBit's first repair code.
- [MoonParse](https://github.com/caiklonghuan/MoonParse) contains a JSON5 grammar;
  tolerant-format parsing is adjacent, not the same as an auditable edit journal.
- [josdejong/jsonrepair](https://github.com/josdejong/jsonrepair) (ISC license)
  is a functionality/design reference, not a copied implementation. This project
  implements a deliberately smaller behavior set and does not claim upstream
  compatibility. No upstream source or test fixture was imported.
- [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259) describes JSON syntax.
  The implementation delegates lexical string/number validation to MoonBit core.

Moon Tera is a separate prior template-engine project by this maintainer. No code
or history from it is reused here. The old repository's CI configuration was
consulted as an engineering setup reference; that is not new parser functionality.

This is an AI-assisted MoonBit implementation maintained by btlqql. AI assistance
is disclosed; the competition proposal must be written by the human applicant.
Whether the proposed differentiation qualifies is a decision for the organizer,
not a claim guaranteed by this document.
