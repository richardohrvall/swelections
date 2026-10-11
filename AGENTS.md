# Repository rules

`swelections` is an R package and reproducible workflow for Swedish election data.
See [CONTRIBUTING.md](CONTRIBUTING.md), [development/README.md](development/README.md)
and [development/CANONICAL_DATA.md](development/CANONICAL_DATA.md).

- Use R for implementation, acquisition, preparation, diagnostics, validation and
  canonical builds. Do not introduce Python or a Python runtime dependency.
- Stay within the authorised task and filesystem scope. Agent instructions are
  not a security boundary. Ask before unrelated or destructive work.
- Preserve raw sources and historical snapshots unchanged. Keep raw archives,
  caches, generated reports and canonical assets out of Git. Small intentional
  test fixtures and documented build lookups are exceptions.
- Preserve election values, candidate identities, keys, missingness and validated
  behaviour. Do not change public schemas or observation units without approval.
- Keep the fixed election result separate from later mandate-period events.
  Apply only explicitly approved, scoped identity harmonisation rules; retain
  source identifiers and provenance. Do not infer identity from names alone.
- Preserve `NA`, verified zero and false as distinct states. Do not reconcile
  unexplained official-source discrepancies by overwriting source values.
- Support English and Swedish interfaces through shared implementation. Canonical
  column names are English; column-name translation must not translate source values.
- `standard` is broad and analysis-friendly. `full` adds source detail. Standard
  must remain a projection of full with identical keys and shared values.
- Geography must describe its actual role. Distinguish candidacy geography from
  elected geography; do not add redundant aliases or rows for geographic context.
- Never hard-code a developer archive path in package code. Explicit source
  selection overrides automatic selection; canonical auto-eligibility is explicit.
- Prefer small changes and deterministic fixtures. Keep independent R validators
  separate from production normalisation where practical. Run relevant tests,
  package checks and diff checks before claiming completion.
- Exploratory local notebooks are workbenches, not production code or user docs.
- Do not commit, push, tag, rewrite history or publish releases without explicit
  authorisation. Before a data release, build from a clean committed tree and
  validate manifest provenance, asset checksums and canonical/raw equivalence.
