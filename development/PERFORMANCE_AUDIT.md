# Performance audit

19–20 October 2026. Initial read-only audit, followed by the implementation of priorities 1, 2 and 3 documented below.
The working-tree mandate-history implementation is included. During the initial audit no production R,
API, schema, source data or canonical asset was edited. No commit or push.

## Method and scope

- R 4.6.1 (Windows x64, Windows 11), repository dependencies and `pkgload::load_all()`.
- Sequential `system.time`-equivalent elapsed/CPU measurements, explicit garbage
  collection outside each timed call, and separate `Rprof(interval = 0.01)` runs.
  No benchmark processes ran concurrently. No network or download latency is included.
- Existing validated local manifests for RKL 2014/2018/2022 and EU 2024. Raw
  comparisons use preserved RKL 2018 sources, pinned R-only 2022 prepared inputs,
  and the active corrected 2026 RF archive documented in
  [RF_2026_SOURCE_CORRECTION.md](RF_2026_SOURCE_CORRECTION.md).
- Seven main APIs measured for canonical 2018/2022 (KF) and raw 2018 (RD), plus
  full-district, post-filtered municipality, multi-election and three-year cases.
  Membership histories measured for all three supported periods; dated member/
  vacancy queries also measured for KF 2018.
- Typically two or three calls per scenario, with the final call profiled.
  The separate repeat experiment includes four unprofiled 2018 KF candidate calls
  and three unprofiled elected calls. Distinguish unprofiled elapsed times from
  profiler attribution: sample percentages are not exact wall-clock percentages.
- These are local-machine observations, not service-level guarantees. File-system
  caches were not flushed; these are not cold-disk/download measurements. Timings
  vary across sessions. No peak-memory benchmark was performed; object sizes below
  describe returned R objects only.
- No exhaustive performance census of every historical year, stage, zero-expansion
  variant or remote source was attempted. Conclusions apply to measured paths;
  shared-reader implications for other years require subsequent regression tests.

Reproducible R scripts, all repetitions, profiles, session information and logs
are preserved locally outside Git under
`<project>/.local-data/performance-audit-20261019/`. Run `benchmark.R` and then
`additional.R` sequentially from the repository root with project dependencies
and the documented local inputs. The scripts intentionally pin the preserved
prototype manifests and audited membership snapshots; they are local audit
workbenches, not portable package entry points.

There are 62 successful scenarios (public calls and isolated experiments),
covering 164 completed measurements. One long runner ended during a profiled
RF preference-vote repetition without recording an R exception or a result.
That unfinished sample is excluded; the repetition and remaining cases completed
in a separate process (`resume.R`). The RF preference repeat took 133.99 s in
that process versus 212.92 s in the earlier unprofiled call. This is process/run
variation, not an optimisation gain. `local_history.R` adds the raw-history control.

Two initial 2022 raw trials used the generic historical archive, which lacks
`2022/val2022/index.md5`. Their explicit missing-source errors remain in the log
and are excluded from performance conclusions. Correct-source trials use the
already prepared pinned 2022 build input directory; no sources were rebuilt.

## Representative measurements

### Canonical API

Seconds, existing local cache. KF except where stated; standard English output.
Ranges include the initial profiling series, and the later unprofiled repeat
series is identified explicitly rather than silently choosing the fastest call.

| API/scenario | Observed elapsed seconds | Returned rows |
| --- | ---: | ---: |
| `results(2018, "KF", level="municipality")` | 0.10–0.44 | 3,391 |
| `seats(2018, "KF")` | 0.03–0.26 | 3,317 |
| `candidacies(2018, "KF")` | 0.21–0.27 | 71,021 |
| `candidates(2018, "KF")` | 9.85–11.03 in four unprofiled repeat calls; initial unprofiled calls 20.34–21.14 | 53,400 |
| `elected(2018, "KF")` | 9.86–10.14 in three unprofiled repeat calls; initial unprofiled calls 5.91–6.19 | 12,678 |
| `substitutes(2018, "KF")` | 0.03–0.05 | 61,329 |
| `preference_votes(2018, "KF")` | 0.19–0.25 | 66,183 |
| `results(2022, "KF", level="municipality")` | 0.08 | 5,539 |
| `seats(2022, "KF")` | 0.03 | 2,548 |
| `candidacies(2022, "KF")` | 0.10–0.12 | 66,166 |
| `candidates(2022, "KF")` | 0.52–0.64 | 52,001 |
| `elected(2022, "KF")` | 0.45–0.46 | 12,597 |
| `substitutes(2022, "KF")` | 0.06–0.10 | 62,905 |
| `preference_votes(2022, "KF")` | 0.14–0.16 | 63,098 |
| KF 2018 district results, whole country | 0.09–0.11 | 80,069 |
| Same call followed by Stockholm municipality filter | 0.09–0.11 | 8,668 |
| `candidates(2018)` with all RD/RF/KF | 0.03–0.06 | 72,255 |
| Candidates for 2014+2018+2022, all RD/RF/KF | 1.30–1.34 | 215,125 |
| KF district results for 2014+2018+2022 | 0.53–0.65 | 247,264 |
| RD 2018 district preference observations | 0.62–0.68 | 339,845 |
| KF 2022 candidates without result enrichment | 0.48–0.53 | 52,001 |

The candidate selection anomaly is real: the all-election 2018 request returns
materialised data directly, whereas explicit election selection rebuilds the
candidate base. A selected KF request is therefore much slower despite returning
fewer rows. Three-year requests without that recalculation are already fast.

The API currently has no municipality argument. The one-municipality case is
`subset(results(..., level="district"), municipality_code == "0180")`; it still
reads the whole national table. Its returned object is 1.91 MiB versus 17.67 MiB
for all municipalities, but its acquisition cost is unchanged. A narrower
returned object must not be mistaken for pushed-down source selection.

### Raw XML 2018

| API/scenario | Unprofiled elapsed seconds | Profiled repeat seconds | Rows |
| --- | ---: | ---: | ---: |
| RD municipality party results | 7.38 | 7.21 | 6,203 |
| RD seats | 3.56 | 3.54 | 270 |
| RD candidacies | 3.73 | 3.48 | 42,267 |
| RD candidates | 90.86 | 90.17 | 6,305 |
| RD elected | 89.81 | 99.58 | 349 |
| RD substitutes | 9.73 | 9.78 | 1,339 |
| RD area preference observations | 79.83 | 78.61 | 36,598 |
| KF district party results | 149.17 | 148.59 | 80,069 |

Input examples: the preserved 2018 final ZIP is 48,715,055 bytes and the candidacy
SKV is 28,483,765 bytes. Large wall times are not explained simply by file size:
XML namespace discovery dominates the slow national preference parsing path.
The KF district canonical view has the same 80,069 rows but reads in about 0.1 s.
This compares source routes, not the timing of an implemented raw-reader fix.

### Mandate-period APIs

Original-result route is canonical; membership exports remain local.
2022 explicitly uses the audited late-term sources, not the early 2022 snapshot.

| Scenario | Elapsed seconds | Rows |
| --- | ---: | ---: |
| `mandathistorik(2018)` all RD/RF/KF | 15.88 / 16.14 | 18,422 intervals |
| `ledamoter_vid("2020-01-01", ar=2018, val="KF")` | 12.03 / 12.15 | 12,664 occupied |
| `tomma_stolar_vid("2020-01-01", ar=2018, val="KF")` | 12.08 / 12.18 | 36 vacant |
| `mandathistorik(2014)` all RD/RF/KF | 14.17, one profiled call | 18,684 intervals |
| `mandathistorik(2022)` all RD/RF/KF | 11.93, one profiled call | 18,079 intervals |

A separate default raw-source control,
`mandathistorik(2018, val="KF", source="local", data_dir=archive)`, took
**36.46 s** in one profiled call and returned **15,943 intervals**. About 81% of
its sampled time is in reading/constructing the original result inputs, including
about 49% in elected/substitute XML relation parsing; about 18% is in the history
engine. The 12–16 s figures above must not be read as timings of the default raw
route. Source choice matters, and repeated date queries rebuild these inputs too.

For 2018 all-election history, approximately 52% of sampled time is in
`.mh_original()`/the canonical elected candidate-base recalculation, and 45% in
`.mh_build()`. Source discovery/CSV reading is about 1%; normalisation about 2%.
For 2014 and 2022, `.mh_build()` accounts for about 90% of sampled time.
`fill_party()` alone accounts for about 32% of the 2018 total and 43% of the 2022
total: repeated row-level searches through the party reference are material.
Dated queries reconstruct and validate the complete selected history each time;
the eventual date/status filter is a negligible part of the current cost.

## Prioritised proposals

### 1. Reuse document namespaces during historical XML parsing — high priority

**Current cost:** RD 2018 candidates/elected roughly 90 s, area preference votes
roughly 80 s, KF district results roughly 149 s.

**Evidence:** `xml_ns.xml_document` accounts for approximately 83% of sampled
RD candidate time, 79% of elected time, 88% of preference time and 50% of KF
district-result time. `xml_find_all()` and `xml_attr()` repeatedly discover
namespaces for nodes belonging to the same document. Actual XML deserialisation
is a much smaller component. In particular `.xml2018_person_parti()` repeats
XPath access to the same list's `PERSONVAL` nodes to obtain IDs and vote counts.

**Change:** calculate namespaces once per document and pass them explicitly to
XPath/attribute readers; reuse each list's selected node set for its attributes.
Start with the measured 2018 reader, then test genuinely shared historical
readers separately. Do not blindly disable namespaces in arbitrary sources.

**Expected benefit:** potentially several-fold for national preference parsing
and a substantial reduction for district results. Profile proportions indicate
large headroom but are not a promised end-to-end speedup. A standalone equal-value
XML experiment is recorded below; no complete optimised public reader was run.

**Risk/API:** no API change required. Preserve namespace interpretation, node
order, all validation rules, missingness and returned attributes. Test every
shared year/reader before broadening the change. No new dependency is needed.

### 2. Reuse materialised 2018 canonical candidate summaries — high priority

**Current cost:** selected KF candidates/elected around 10 s in the unprofiled
repeat series, although all-election candidates return in 0.03–0.06 s.

**Evidence:** `.kandidater_bas()` accounts for about 99% of sampled selected
canonical elected time; Parquet reading is less than 1% in that profile. The
2022 backend already demonstrates a materially cheaper materialised-base pattern.

**Change:** take stable candidate fields from the existing validated candidate
asset and recalculate only the selection-dependent cross-election counts, with
strict key matching and existing output ordering. Reuse this for elected
selection and the corresponding original-result inputs to membership history.

**Measured diagnostic:** the standalone materialised base took 0.42–0.47 s
versus about 10 s for the existing KF grouped base. Every base column, type,
attribute and row order compared exactly (`identical`) for RD, RF, KF, KF+RF
and all three types. This is a diagnostic function, not an installed replacement.
The diagnostic reads its input tables before the substep timing.

**Expected benefit:** about 20-fold in the measured base substep; a plausible
end-to-end target is below 1–2 s for selected canonical KF candidates/elected,
subject to measuring an actual implementation. It also removes roughly half
the sampled cost of 2018 history construction. These gains are not additive to
caching benefits below.

**Risk/API:** no new assets or public API should be needed. Preserve election
subset semantics, historical missingness, candidate names/IDs, source ordering
and standard/full equivalence. The five exact-output comparisons support the
proposal but do not replace full regression validation after implementation.

### 3. Reduce repeated 2026 RF transformations — high priority

**Current cost:** a full regional `candidates(2026, "RF", source="local")`
request takes 215.28 s unprofiled and 218.01 s in its profiled repeat for 12,855 rows.
The corrected current RF sources are used; this is not a remote-download test. Elected output takes 69.59 / 70.34 s, with about 80% of sampled time in the relation parser. Substitute output takes 56.42 / 57.69 s, with about 97% in that parser (about 94% on tibble-construction stacks).

**Evidence:** `.personrostomraden_2026()` occupies about 69% of sampled time:
`.personrostomradesunderlag_2026()` about 33% and
`.personrostomraden_avstamda_2026()` about 31%. These are nested inclusive
percentages and must not be added to their parent. `parse_valda_ersattare_2026()`
occupies another 26%; it constructs both relation tables although the candidate
consumer uses the elected component. Across the whole call `tibble::tibble()`
is on approximately 48% of sampled stacks. ZIP/JSON reading is only about 2.5%.

**Change:** retain the district/list/area checks but build their required typed
columns in batches and reuse already parsed inputs within the request. The
relation parser currently creates one metadata-heavy tibble per elected/
substitute row: build invariant metadata once per group and populate typed
vectors instead. Avoid materialising unused substitute outputs when a consumer
needs elected relations only, while retaining equivalent source validation.

There is a small, concrete reuse opportunity already supported by the code:
`.personrostomraden_avstamda_2026()` accepts parsed `mandatlistor` and
`distriktsunderlag`; the detailed preference path passes them, but the area
path builds mandate-list data within the check and then again for its own
aggregation. Compute that same representation once and pass it to both users.
Do not pass the differently shaped aggregate `underlag` as detailed district
input. Mandate-list construction occupies about 7.5% of sampled total time, so
removing just this duplicated part cannot explain a dramatic whole-call gain.

**Expected benefit:** a first target of 20–40% less total work (tens of seconds)
is plausible for batch construction/selective materialisation plus reuse, but
is an estimate, not an implemented end-to-end benchmark. Start with small,
measurable parser changes and profile again; do not introduce an elaborate
request framework solely to remove a small duplicated list pass.

**Risk/API:** internal changes should suffice. Preserve all RF source-conflict
checks, official/source missingness, list and candidate keys, row ordering,
relationships and the established candidate-wide enrichment scope. No new
canonical builder, source update, candidate-identity rule or public API is needed.

### 4. Reduce repeated mandate-history work — worthwhile, in two steps

**Current cost:** 12–16 s per query, including a query returning only 36 vacancies.

**First-build change:** replace repeated party-reference scans with a precomputed
strict lookup keyed by election, geography and party abbreviation, retaining
candidate-based fallback and ambiguity errors. Keep the existing chain,
re-election, allocation and vacancy controls. For 2018, proposal 2 should come
first; it removes unrelated candidate summary work before changing the history
engine. Review per-chair tibble slicing only if it remains significant afterward.

**Expected first-build benefit:** the party scans occupy about 32–43% of sampled
whole-call time. This establishes a substantial optimisation target, not a
measured replacement speedup. A 20–40% reduction is a planning estimate for the
lookup change, conditional on equivalent checks and little new overhead.

**Repeat-query change:** optionally reuse the fully validated interval table for
unchanged inputs. Merely caching CSV reads misses the bottleneck. A local
experiment using an already built full history returned one dated snapshot in
0–0.02 s and ten monthly snapshots in 0.06–0.09 s. Zero here means below the timer's
resolution, not literally free work. These timings exclude acquisition, source
checking and history construction; they are not timings of an optimised public API.

**Expected repeat benefit:** subsequent requests could plausibly fall below
0.5 s with cheap source checks; this must be measured after implementation.
The full 2018 returned history occupies about 7.9 MiB, so a bounded history cache
is feasible, but it is still a design/maintenance decision.

**Risk/API:** no change to chair population, date boundaries, original vacancy
handling, corrections or source-date coverage is acceptable. Cache keys need
source content identities, source selection, original manifest identity, year,
election selection and implementation version. Newly added/latest snapshots and
changed files must invalidate the entry. Keep memory bounded and provide an
explicit invalidation mechanism. First optimise simple proven repeated work;
do not add a persistent disk-cache architecture solely for this audit.

### 5. Share parsed inputs within one compound raw request — secondary

Candidate/elected/preference readers compose other readers. In 2018,
`.xml2018_kandidatresultat()` calls the full preference reader, which reloads the
candidacy file and rebuilds a candidate base already available to its caller.
The relation and preference readers also revisit the same result source. Pass a
small internal request context or already parsed inputs instead of re-entering
public readers. Do not shrink the enrichment scope to elected geography: that
would reintroduce the previously corrected KF scope bug.

The opportunity is real in the call graph, but namespace work dominates the
current 2018 raw profile. Measure again after proposal 1; do not promise that
removing a repeated file read alone fixes a 90-second request. For example,
candidacy reloads occupy about 8% of sampled raw RD candidate time.

The 2022 canonical selected-candidate branch also fetches the candidate asset
twice. A request-local reuse is simple, but the whole request is already around
0.5 s. Treat this as opportunistic maintenance, not a leading performance project.
Any caching must retain checksum verification and source freshness semantics.

## Changes not recommended now

- Do not redesign standard/full or English/Swedish naming for speed. Presentation
  is not the dominant cost in the slow profiles.
- Do not redesign Parquet partitioning or remove SHA256 verification to save
  hundredths of a second. Most canonical tables already load quickly.
- Do not add a new municipality-filter argument solely on the current benchmark:
  canonical full-country district results are already about 0.1 s. A source-level
  filter could benefit raw XML users, but requires a separate API decision and
  careful preservation of global candidate enrichment and completeness controls.
- Do not add parallel downloads, new data-frame engines, C++ or Python. The
  leading opportunities are repeated work in the current R implementation.
- Do not disable any source, population, join-cardinality or vacancy validation.
- Do not extrapolate measured 2018 performance to every historical source without
  further targeted measurements; no exhaustive raw-source year sweep is needed
  before starting the concrete high-priority fixes.

## Additional measured paths

### Active corrected RF 2026 raw source

| API/scenario | Unprofiled seconds | Profiled repeat seconds | Rows |
| --- | ---: | ---: | ---: |
| results | 3.42 | 3.06 | 704 |
| seats | 2.72 | 2.73 | 569 |
| candidacies | 1.20 | 0.99 | 76,204 |
| candidates | 215.28 | 218.01 | 12,855 |
| elected | 69.59 | 70.34 | 1,720 |
| substitutes | 56.42 | 57.69 | 15,183 |
| preference_votes | 212.92 | 133.99 | 58,354 |
| results-district | 30.16 | 29.92 | 85,426 |

These are RF-only requests over all preserved current regions, not single-region
tests and not requests to the pre-correction source. Public source validation
remained enabled. The dominant transformation cost is documented in proposal 3.

### Pinned 2022 raw, EU 2024 and presentation controls

| Scenario | Recorded elapsed seconds | Rows |
| --- | ---: | ---: |
| EU-2024-canonical-preference-area | 0.02–0.11 | 631 |
| EU-2024-canonical-results-district | 0.09–0.28 | 95,167 |
| canonical-2018-results-full | 0.08–0.14 | 80,069 |
| canonical-2018-results-swedish | 0.09–0.16 | 80,069 |
| raw-pinned-2022-RD-results | 1.69–1.74 | 1,122 |
| raw-pinned-2022-RD-elected | 10.37–10.53 | 349 |
| canonical-2018-RD-candidates | 0.80–0.82 | 6,305 |
| canonical-2018-RD-elected | 0.75–0.81 | 349 |
| canonical-2018-RD-substitutes | 0.01–0.04 | 1,339 |
| canonical-2018-RD-preference_votes | 0.08–0.12 | 36,598 |

These controls support the scope limits above: fast presentation/canonical paths
do not justify a broad rewrite. The pinned 2022 cases replace the two excluded
source-location trials; a missing-file error is never treated as a performance result.

### Isolated namespace experiment

For 100 real RD 2018 ballot-list nodes, the default namespace discovery took 0.78–0.80 s; explicit reuse of the document namespace mapping took 0.00–0.01 s. Candidate-ID and preference-vote attribute vectors compared exactly with `identical()` before timing. The source document has no declared namespaces. The namespace mapping is computed once outside the timed inner loop; an implemented reader must still compute/validate it once per document.

This is a low-level experiment, not an end-to-end optimised result or preference
reader. No existing XML helper was patched or replaced during the experiment.

## Audit outcome

Prioritise namespace reuse, materialised 2018 canonical candidate summaries,
and batch/reused 2026 relation/person-vote structures. Improve first-build
history lookups before deciding on bounded validated-history caching for
repeated snapshots. Most canonical result, seat, candidacy, substitute and
preference requests already perform adequately in the measured scenarios.

No production optimisation was made during the initial audit. Full package tests/R CMD check were not
rerun for this documentation-only audit; the previously reported implementation
validation remains separate. Diagnostic exact-output comparisons ran in the
ignored R tooling, with no raw/canonical rebuild or source recovery.

## Implemented priorities 1 and 2

Only these two priorities were implemented. The RF 2026 transformation work and
mandate-history engine/cache proposals remain deferred. Public arguments,
selection rules, schemas, names, source values, candidate identities and raw-data
validation rules are unchanged. No sources or canonical assets were rebuilt.

### XML access

The historical XML helpers now pass an explicit empty namespace mapping for
unqualified XPath expressions. Namespace bindings do not affect these queries;
previously xml2 rediscovered them by scanning the document at each call. Queries
with namespace prefixes retain xml2's normal namespace discovery. XPath axes
such as `ancestor-or-self::` are distinguished from prefixes. No namespace is
stripped from the XML, and XML attribute access is unchanged.

2018 result, mandate, candidate relation and preference readers use these
helpers. Already selected `PERSONVAL` nodes are reused for list candidate IDs
and votes instead of selecting the same nodes twice. Existing source validation,
including list/party sums, duplicate keys, malformed values and vacancies,
remains enabled. There is no persistent XML cache.

### Canonical candidate summaries

Selected 2018 `candidates()` and `elected()` requests reuse the materialised
candidate summaries. Only `election_types_count`/`multiple_election_types`
(`antal_valtyper`/`flera_valtyper`) depend on the requested election types and
are recalculated from valid candidacies. Other summaries are confined to a
single election type and remain unchanged by that selection.

`include_results = FALSE` retains the original base columns and candidacy-order
keys; column names are obtained from a one-row base rather than recomputing the
entire population. Invalid candidacies do not affect counts. Candidate-key
checks, elected relations and elected geography are preserved. The 2014/2022
canonical backends and 2026 parsing code were not changed.

### Isolated steps and exact public comparisons

Before editing, the complete production R tree was frozen locally. Sequential
fresh-process benchmarks call the actual public APIs with `detail = "full"`,
English names, `progress = FALSE`, the same sources and manifests, and garbage
collection outside the timer. Each post-change result must be `identical()` to
the frozen pre-change RDS, including attributes, types, row/column order and NA.

| Public call | Before (s) | XML only (s) | XML + canonical (s) | Rows |
| --- | ---: | ---: | ---: | ---: |
| raw KF `results()`, district | 347.34 | 155.67 | 155.26 | 80,069 |
| raw RD `candidates()` | 153.38 | 23.36 | 22.44 | 6,305 |
| raw RD `elected()` | 130.25 | 23.28 | 23.58 | 349 |
| raw RD `preference_votes()`, area | 106.19 | 12.89 | 13.05 | 36,598 |
| raw RD `seats()` | 4.72 | 1.50 | 1.48 | 270 |
| raw RD `substitutes()` | 14.47 | 7.45 | 7.34 | 1,339 |
| canonical KF `candidates()` | 12.34 | 12.16 | 0.77 | 53,400 |
| canonical KF `elected()` | 11.85 | 11.70 | 0.75 | 12,678 |

All eight comparisons passed at each step. These are full-view paired runs,
separate from the original standard-view audit. They establish end-to-end gains,
not just improvements in an isolated namespace or aggregation experiment.
Absolute times differ from the initial audit; do not compare sessions as though
they were controlled cold-cache runs.

Evidence and R-only diagnostic runners are retained locally under
`<project>/.local-data/performance-optimisation-20261019/`: `compare.R`, the
frozen baseline R files and RDS outputs, per-stage CSV/logs, repeated original
audit scenarios, profiles, selection regressions and validation logs. These are
ignored local development outputs, not additional build inputs.

### Repeated original audit scenarios

The original standard-English scenarios were repeated sequentially after both
changes: 50 unprofiled public calls across 20 scenarios. These are separate
measurements from the paired full-view table above.

| Standard public scenario | Initial audit seconds | Repeated after seconds |
| --- | ---: | ---: |
| raw RD candidates | 90.17–90.86 | 21.63–22.86 |
| raw RD elected | 89.81–99.58 | 21.69–22.34 |
| raw RD preference votes | 78.61–79.83 | 12.61–12.94 |
| raw RD seats | 3.54–3.56 | 1.35–1.41 |
| raw RD substitutes | 9.73–9.78 | 6.97–7.27 |
| raw KF district results | 148.59–149.17 | 142.89–145.28 |
| raw RD municipality results | 7.21–7.38 | 11.22–12.70 |
| raw RD candidacies (unchanged reader) | 3.48–3.73 | 5.83–6.00 |
| canonical KF candidates | 9.85–11.03, separate unprofiled repeat | 0.62–0.72 |
| canonical KF elected | 9.86–10.14, separate unprofiled repeat | 0.56–0.62 |
| canonical RD candidates | 0.80–0.82 | 0.17–0.20 |
| canonical RD elected | 0.75–0.81 | 0.18–0.19 |
| canonical candidates, all 2018 elections | 0.03–0.06 | 0.07–0.10 |
| canonical candidates, 2014+2018+2022 | 1.30–1.34 | 1.80–2.22 |
| canonical KF district results, same three years | 0.53–0.65 | 0.62–0.82 |

There is a substantial repeated public gain for selected candidates/elected and
raw RD preference votes. The original-audit versus repeated-standard comparison
does **not** establish a material KF district-results gain; the stronger gain
in the fresh paired full runs must not be presented as a universal steady-state
speedup. Likewise, no gain is claimed for raw municipality results or the
unchanged candidacy reader. The latter and the unchanged all-election/multi-year
paths demonstrate session/I/O variability; timings alone are not evidence that
those algorithms changed. Returned populations are unchanged.

The other canonical KF controls remain short: results 0.10–0.26 s, seats
0.03–0.04 s, candidacies 0.11–0.14 s, substitutes 0.05–0.06 s and preference
votes 0.25–0.31 s. No optimisation is claimed for those paths. Namespace
discovery has no sampled entry in the post-change raw-RD candidate profile,
compared with its dominant share in the original audit.

The complete repeated-run CSV was consolidated from the preserved per-call log
after fixing accumulation in the local benchmark runner; all 50 recorded calls
are retained. No timing was discarded or replaced by an isolated experiment.

### Validation and change inventory

- Complete ordinary test suite: **3,875 passed, 16 explicit external-data skips,
  zero failures, errors or warnings**. The 43 new assertions cover namespace
  semantics, node order, stored summaries, selection-dependent counts, base-only
  columns/order, elected geography/relations, key-error checks and legacy errors for missing source columns.
- Installed-source-package `R CMD check --no-manual --no-vignettes`: **Status:
  OK**, zero errors/warnings/notes. Its test run also reports 3,875 passes and
  16 explicit skips. A package staging copy respects `.Rbuildignore`; no raw
  collection or canonical assets are included.
- **96 additional public comparisons** against the frozen legacy canonical
  backend pass: eight election selections (including NULL, mixed and reversed
  selections), candidates with/without results, elected, standard/full and
  English/Swedish. These compare the complete objects with `identical()`.
- Manifest integrity: **9,529 source records** checked against MD5/SHA256 across
  RKL 2010/2014/2018/2022, and **92 canonical asset** size/SHA256 checks.
  Counts are manifest records, not a claim that every record is a distinct file.
  The verifier resolves 2022 corrected ZIP-member identities and expired
  temporary build paths through the hash-matching preserved original ZIPs;
  these are not missing source data and no sources were downloaded/replaced.
- All **20 frozen 2018 Parquet assets** also pass exact data/type/attribute
  round trips through temporary diagnostic files. Protected assets are never
  overwritten.

Production changes relative to the frozen audit R tree are exactly:

1. `R/xml_2018.R`: unqualified/qualified XPath helpers and their shared callers.
2. `R/valresultat_2018.R`: use the XPath helper for the selected result root.
3. `R/mandat_2018.R`: use the XPath helpers for mandate nodes/relations.
4. `R/personroster_2018.R`: use the XPath helpers and reuse selected list nodes.
5. `R/personroster_xml_distrikt_2018.R`: use the XPath helpers for district data.
6. `R/kandidatresultat_2018.R`: use the XPath helpers for elected/substitute nodes.
7. `R/canonical_backend.R`: reuse 2018 summaries and recalculate selected counts.

`tests/testthat/test-performance-2018.R` is new; this document is updated.
The previously uncommitted mandate-history implementation/docs/exports/tests
remain separate and untouched. All other production R hashes match the audit
snapshot, including the 2026 readers and membership-history engine. No dependency,
API, canonical schema, candidate-ID or source-selection change was made.
No commit, push, release or tag.

Additional actual-source shared-reader controls:

- RKL 2010 RD final: **20 recorded passes, zero discrepancies**. These cover all
  seven public functions, final geographic results and aggregates, base-only
  candidates, mandates, all four area preference variants and reported district
  preferences. Each recorded public comparison checks full/standard,
  English/Swedish, types, keys and missingness. The subsequent optional complete
  country-wide district zero expansion was deliberately stopped to bound memory;
  it is not reported as a completed sweep or a source failure. Zero-expansion
  logic was not changed and is covered by fixture tests and the representative
  2018 integration panel.
- RKL 2014 KF final: **20 recorded passes, zero discrepancies**, completed.
  All seven functions, five final result levels, elected/substitute relations,
  municipality/constituency mandates, area preference variants, reported district
  list/non-list variants and municipality preference aggregation reproduce the
  protected canonical reference. This extra run likewise excludes a complete
  country-wide district zero expansion.

Final review retained the legacy source-column/status validation in the canonical
shortcut: a one-row base validates the required fields on every selected request,
without rebuilding the full population. Three malformed-source regression cases
match the old error messages exactly. This validation does not supply candidate
attribute values or alter the stored result. Full tests/package checks were
repeated after that change. The paired/repeated benchmark tables above record
the preceding two-step implementation; final selected-canonical timings with
this validation retained are recorded separately below. The raw XML code did not
change between these runs.

### Final selected-canonical measurements and controls

The final implementation, including retained legacy source-column validation,
was measured through the public English API three times per variant. Every
returned object matched the frozen pre-change or legacy-backend reference
exactly, including standard projections, row order, types and attributes.

| Final public scenario | Full seconds (range; median) | Standard seconds (range; median) |
| --- | ---: | ---: |
| canonical KF candidates | 0.35–0.58; 0.56 | 0.71–0.75; 0.72 |
| canonical KF elected | 0.66–0.74; 0.67 | 0.69–0.78; 0.74 |
| canonical RD candidates | 0.30–0.30; 0.30 | 0.28–0.31; 0.29 |
| canonical RD elected | 0.25–0.28; 0.26 | 0.27–0.28; 0.28 |

Fresh sequential before/after controls used the same frozen baseline, files and
public calls; their complete outputs were also checked with `identical()`.
These controls explain the slower cross-session values in the original-audit
comparison without attributing that variability to an algorithm change.

| Control | Before seconds | Final after seconds |
| --- | ---: | ---: |
| raw RD municipality results | 12.06–14.14 | 11.48–14.09 |
| raw RD candidacies | 5.72–6.41 | 5.81–6.39 |
| canonical all-election 2018 candidates | 0.09–0.26 | 0.10–0.25 |
| canonical three-year candidates | 2.30–2.33 | 2.14–2.50 |
| canonical three-year results | 0.69–0.74 | 0.69–0.74 |

No meaningful gain or regression is claimed for those controls. Final timing
records are `final-canonical.csv`, `controls-before.csv` and
`controls-after.csv` in the ignored diagnostic directory described above.

### Completed actual-source integration

The complete opt-in 2018 raw/canonical integration run passed **1,344 assertions,
zero skips, failures, errors or warnings**. It covers all seven public functions,
RD/RF/KF, supported result geography, list/non-list preference variants, reported
and representative zero-expanded district data, keys, values, types, missingness,
standard/full and English/Swedish. It uses the official candidate snapshot whose
MD5 is `9855ac4280c2a5165389a88c647ae49f`, matching the frozen canonical build.
The final XML implementation was unchanged after this run.

After the final source-column-validation refinement, the staged raw-built versus
canonical matrix was repeated: **713 assertions passed**, with one explicit skip
of the already completed full raw reparse, and zero failures/errors/warnings.
The final **96 public legacy-backend equivalence comparisons**, full **3,875-pass
test suite** and **R CMD check (0 errors, 0 warnings, 0 notes)** were also repeated.
No output discrepancy was found. Protected raw sources and canonical assets
remain unchanged; no canonical rebuild or source replacement was needed.

At completion of priorities 1/2, priorities 3 and 4 were not implemented.
The following section records the subsequent priority 3 work; priority 4 remains deferred.

## Implemented priority 3: grouped modern RF transformations

This follow-up is separate from priorities 1/2 above. Priority 4 and the KF
district-results reader are outside its scope. All source files, candidate
identities, canonical assets, public arguments and schemas remain protected.

Two production files implement the retained optimisation:

- `R/parse_valda_ersattare_2026.R`: build elected/substitute columns per party
  and geographic group, repeating shared metadata only after typed candidate
  vectors have been collected. Source order and repeated substitute relations
  are retained; there is no name-based deduplication.
- `R/personrostomraden_2026.R`: construct one district-candidate table per
  preference area/party instead of one tibble per district. Sum by the same
  candidate key and first-observed order. Reuse parsed mandate lists within
  one request. This reuse is lazy: early reconciliation exits on incomplete
  sources still occur before parsing the mandate-list details.
- Experimental `R/personroster_listor_2026.R`: constructed mandate candidate/list columns per
  party after the existing validation inspected every source list. This separate
  experiment was reverted: its measured gain was too small relative to a complete
  public RF request. The retained implementation uses the original list builder.

No persistent cache, mandate-history optimisation, new relation-selection API,
source-selection change or validation bypass is introduced. Both relation
outputs remain available with the same private-parser contract.

The reference is a frozen copy of the current working-tree implementation before
these three edits, including the approved priority 1/2 changes. It includes
`R/sysdata.rda`, so municipality lookup inputs are identical. Evidence and R-only
runners are retained under `<project>/.local-data/performance-rf-20261019/`.
The first attempted isolated baseline omitted this lookup object and stopped
before producing any benchmark result; the corrected copy includes it. No setup failure changed an official source or package file.

Measurements are sequential public requests against the active corrected RF
source described in `RF_2026_SOURCE_CORRECTION.md`, with no concurrent R test or
validation workload. Stage 1 contains only the grouped relation construction;
the final stage adds grouped person-vote construction and request-local reuse.
Every measured result is compared to the complete frozen public object using
`identical()`, including column/row order, types and attributes. Fresh paired
measurements are the principal comparison; older audit times are recorded above
and are not treated as directly comparable sessions.

The separate list-table experiment measured 5.14 s before versus 3.58 s after,
summed across all 20 RF inputs with exact-output checks. Its 1.56 s saving is
small against a complete public request and does not justify retaining another
changed parser here. `R/personroster_listor_2026.R` was restored byte-for-byte to
the frozen baseline. The discarded version remains only in the ignored local
experiment directory. `after.csv` records that experiment; `final.csv` records
the retained two-file implementation before the final lookup refinement;
`review.csv` records the final source used in the table below. Full tests and package checks are repeated
on the retained version.

The batched relation parser itself takes 2.27 s across all 20 RF inputs. This
bounds the benefit of omitting unused relation materialisation: only a fraction
of that whole-parser time could be removed while retaining the same scalar/source
checks. No extra selective-output flag was retained for such a small residual
cost. Both outputs and their established validation contract are preserved.

Diagnostic-runner issues are distinct from package results. The first baseline
copy omitted the package lookup data and failed before any timed request
completed; this was fixed. Updating the local runner while its original stream
was still open also caused a trailing `ole()` error at process shutdown. All
four timed public callbacks had returned, written their full RDS objects and CSV
records, and printed the completion line before that trailing driver error.
Every saved object is subsequently checked exactly in the stage-1 and retained
implementation runs; no failed public callback or timing is silently discarded.
The corrected driver is stable for all subsequent runs. An initial shared-source
control also used the RF archive root for RD/KF; those controls were rerun against
the already preserved `.local-data/validation-2026-remote` source collection.
No source was downloaded, substituted or altered to repair a diagnostic runner.

### Retained priority-3 public benchmark

Seconds for the complete public English `detail = "full"` request across all
current RF regions, using the same corrected files in each stage:

| Function | Frozen before | Grouped relations only | Retained final | Saved seconds |
| --- | ---: | ---: | ---: | ---: |
| `candidates()` | 404.19 | 109.71 | 87.71 | 316.48 |
| `elected()` | 129.39 | 12.36 | 13.61 | 115.78 |
| `substitutes()` | 109.38 | 3.83 | 3.88 | 105.50 |
| `preference_votes()` | 224.08 | 109.53 | 88.61 | 135.47 |

The final reductions are approximately 78%, 89%, 96% and 60%, respectively.
All four final full objects are `identical()` to the frozen baseline: 12,855,
1,720, 15,183 and 58,354 rows, respectively. This compares every value, row and
column order, type and attribute, not only aggregate counts. No further elected/substitute speedup is claimed for the person-vote changes;
their batched-stage timings are similar and subject to measurement variation.
The final run excludes the discarded list-table experiment.

The final RF results are also compared through actual public standard calls in
both English and Swedish against the corresponding projections/translations of
the frozen full baseline. These repeat the original audit's standard-view
scenarios; the full-view table above is the fresh paired comparison rather than
a comparison of timings across different audit sessions.

Final field-lookup review retains the original static `$` expressions through
small typed-vector getters. This preserves partial lookup, explicit NULL records
and atomic-record errors, rather than accidentally introducing stricter `[[`
lookup while batching. Seven further regression assertions cover those cases.
The final full public RF benchmark was repeated after this refinement; its
`review.csv` and `review.log` are the authoritative final full-view measurements
in the table above. All four full results again match the frozen reference.

The original standard scenarios were also repeated through actual English and
Swedish public calls: candidates 86.47 / 86.31 s, elected 12.63 / 12.75 s,
substitutes 3.81 / 3.79 s, and preference votes 85.67 / 86.46 s. All eight objects
match their baseline projections/translations exactly. Those standard timings
precede the final lookup refinement; the final full-object equivalence and the
unchanged projection/translation code preserve the same data in both views.

### Priority-3 validation and final scope

- Final complete test suite: **3,982 passes, 16 explicit external-data skips,
  zero failures, errors or warnings**. This adds 107 regression assertions to
  the preceding 3,875-pass suite, covering source order, all RD/RF/KF relation
  geography branches, types, empty schemas, repeated substitutes, vacancies,
  verified zeros, incomplete reporting, lazy validation and legacy field lookup.
- **80 exact shared-source comparisons** pass: relations, mandate lists and
  district candidate groups for RD, all 20 RF regions and three KF municipalities
  (24 source ZIPs), plus the four actual public RD functions for both 2022 and
  2026. The discarded list experiment produced identical tables too; the final
  implementation uses the original list builder. The two retained helpers keep
  the same results and validation conditions.
- All **seven EU 2024 public functions** match their protected canonical full
  references exactly, including the shared elected/substitute parser.
- The extra actual-source RD 2026 integration passes **19 assertions**, no skips,
  failures, errors or warnings: preference-vote coverage, reported and verified
  zero list variants, candidate counts and absence of artificial missing votes.
- The staged 2018 raw-reference/canonical panel passes **713 assertions**, with
  one explicit opt-in skip of the already completed full XML reparse, and no
  failures/errors/warnings. No new full XML country sweep is claimed here.
- Historical source integrity: **9,529 manifest source records** pass MD5/SHA256,
  **92 canonical asset** size/SHA256 checks pass, and **20 frozen 2018 Parquet
  files** pass exact data/type/attribute round trips. These cover the protected
  2010, 2014, 2018 and 2022 references. Source-record counts are not unique-file
  counts. The current RF provenance separately verifies **42 ZIPs, the index
  and the candidate CSV** against their recorded sizes and checksums.

Final source changes for this follow-up are exactly `R/parse_valda_ersattare_2026.R`
and `R/personrostomraden_2026.R`. Regression changes are the new
`tests/testthat/test-performance-2026.R` and the lazy-validation case in
`tests/testthat/test-personroster-listor.R`; this report is updated. All other
production R hashes match the priority-3 baseline, including the rejected list
builder, KF district-result readers, canonical backends and mandate history.
The earlier uncommitted mandate-history and priority-1/2 changes remain separate.
No API/schema/dependency, election value, candidate-ID, source-selection or
source-validation-rule change is introduced. No source/canonical assets were
rebuilt or overwritten. Priority 4 is not implemented. No commit, push or release.

Final installed-package validation after the field-lookup refinement:
**R CMD check --no-manual --no-vignettes: Status OK; 0 errors, 0 warnings,
0 notes**. Its installed test run reports 3,982 passes and 16 explicit skips.
The seven actual EU 2024 canonical/raw comparisons were repeated and pass.
Logs: `review-tests.log`, `review.log`, `review-check.log` and
`review-eu-checks.log` in the ignored evidence directory.
Final repository `git diff --check` passes.
## Results and acquisition follow-up (20 October 2026)

This follow-up freezes the entire current R implementation, including the
previous priorities 1--3 and mandate-history work, before changing results code.
Evidence is kept only in `.local-data/performance-results-20261020/`.
No canonical build, source replacement, API change or mandate-history
optimization is part of this follow-up.

### Scope and source routes

The actual supported RKL source/level matrix is recorded in
`supported-rkl-levels.csv`. The historical XML family supports RD district,
municipality, municipal constituency, county, parliamentary constituency and
national results; RF district, municipality, municipal constituency, regional
constituency, region and national results; KF district, municipality, municipal
constituency, county and national results. Final results are available for
2002/2006/2010/2014/2018; full preliminary construction is supported for
2010/2014, not 2002/2006/2018. These historical routes are not relabelled.

For 2022, both counts use D/M only: RD district/parliamentary constituency/national,
RF district/regional constituency/region, KF district/municipal constituency/
municipality. The 2026 route additionally uses U for RD/RF municipality and
municipal constituency and O for RF national and KF county/national results.
RD county and RF county remain unsupported in the modern route.

EU 2004/2009/2014 final and EU 2019/2024 final/preliminary results use their
existing source-specific adapters, with national, county, municipality,
municipal-constituency and district views. The 2003 referendum retains its own
option-based final-result adapter. Re-election event results retain their
existing scope and local-source requirements. Source code routing was inspected
for all these families; the validation panels below identify actual executed
comparisons. This is not a claim that every raw year/count/level combination was
timed. Unsupported counts/levels are not enabled by this audit. There is no
2026 canonical build/reference to benchmark; no such architecture is introduced.

Canonical result selection reads the relevant materialized Parquet asset and
filters its level/count/election. The 2010/2014/2018/2022 panel checks every
supported final level: 17, 17, 17 and 9 election/level combinations, respectively.
All 60 full outputs retain their actual English/Swedish standard projections.
The raw 2018 KF district table also matches its full canonical reference exactly.

### Measured 2026 acquisition

A real `results(2026, "RF", source = "auto", archive = TRUE,
 data_dir = <new isolated directory>, detail = "full", progress = FALSE)`
fetches the official index and all 20 regional final ZIPs. The identical call is
then repeated using those normally persisted local files. Both complete outputs
are identical, with 704 rows. All acquisition, read and transformation spans
are measured at the actual package boundaries, not inferred by subtracting
unrelated runs.

| Phase | First request (s) | Repeated local request (s) |
| --- | ---: | ---: |
| Download helper spans | 46.615 | 0 |
| ZIP selection/extraction and JSON read | 1.019 | 0.965 |
| Validation, transformation and public construction | 4.576 | 4.330 |
| Remaining orchestration/archiving/final checks | 0.610 | 0.755 |
| Complete public call | 52.820 | 6.050 |

There are 21 download-helper calls, one per unique URL, and 23,937,670 downloaded
bytes. The repeated call makes none. Each selected M JSON is read once per
request; it is read again on the next request rather than retained as a global
parsed object. The timed boundary instrumentation adds overhead and this first
acquisition ran alongside the initial XML profile. The later isolated,
uninstrumented preserved-source region controls take 2.68 s before and 2.23 s
in the final implementation. They are not substituted for the paired network
measurements.

Network/helper spans account for 88% of the first call. Response time is highly
variable: RF 25 takes 19.72 s for 441,455 bytes and RF 22 takes 8.93 s for
569,944 bytes, whereas RF 01 takes 1.46 s for 5,971,976 bytes. These timings do
not distinguish server processing from network-path latency or transfer time.
They do establish that JSON parsing is not the main cost of this first call.
No downloader, retries, freshness rules or acquisition concurrency were changed.

The exact URLs, start/end retrieval timestamps and sizes are recorded in
`network-events.csv`; `acquired-checksums.csv` records MD5 and SHA256 for every
preserved response/current/archive copy. All 20 ZIP MD5s match the freshly
retrieved official index. These fresh benchmark sources are isolated from the
maintained archive. Compared with the preserved corrected RF region result,
the public M output differs only in `source_last_update_time` and `update_count`
for RF 01 (13 October versus 5 October). Every other returned column is identical.
This does not claim that every other structure inside those ZIPs is unchanged,
and does not activate a newer source snapshot for existing builds.

Raw-source persistence is explicit. `source = "auto"` reuses an existing local
file, but with a missing local file and default `archive = FALSE, update = FALSE`
it returns a URL; readers use and remove temporary downloads. Supplying a data
directory alone therefore does not populate a persistent raw cache. An initial
`archive = TRUE` call uses the existing persistent-download/archive mechanism;
subsequent auto/local calls reuse the files. `source = "remote"` deliberately
selects the URL, and `update = TRUE` deliberately checks fresh remote content.
These semantics are preserved. Canonical assets have their separate checksum-
verified persistent cache. EU adapters additionally cache their verified frozen
bundles. No implicit session-global raw XML/JSON cache is introduced.

For modern district results the D, M and (2026 RD/RF) U objects are different
required JSON members of the same ZIP, not duplicate parses of one object.
The ZIP directory is inspected separately for these reads. Consolidating that
small bookkeeping cost was not justified by the measured profile.

### Retained result optimizations

1. In `R/valresultat_2018.R`, reuse the fixed empty 83-column result prototype
   within the read operation, rather than rebuilding it for every geographic
   node. Construct party vectors in an ordinary list and construct the final
   tibble once. XML nodes, party resolution, metadata, validation, row order,
   missingness, types and attributes remain unchanged. The optional prototype
   is private, with the previous default for other shared historical callers;
   no global mutable cache is used.
2. In `R/valresultat_adapter.R`, classify all source field names with vectorized
   membership/regular-expression operations before checking their values.
   The original scalar value checks, precedence, named lookup, iteration/error
   order, integer bounds and missing/NULL semantics are retained. No validation
   is skipped. This benefits the shared modern result paths, not candidate IDs.

The XML profile attributes 94.7% of sampled time to result-row construction,
including 32.8% in tibble expression construction and 20.3% in table assignment;
XML file reading accounts for 2.8% and geography for 1.3%. XPath namespace lookup
was already fixed by priority 1 and is not the remaining dominant cost. A real
579-node Stockholm experiment takes 20.56 s before and 5.67 s after prototype
reuse and list construction, with identical complete node tables.

The RF district profile attributes 63.4% to scalar source-value validation,
including 53.5% in repeated `grepl` calls. A bounded real RF 01 parser comparison
falls from 5.11 to 2.25 s with identical 19,463 rows. The complete public-call
measurements below establish that the benefit survives the rest of the API.

### Public before/after measurements

Seconds, full English output and identical preserved source files. The final
wall-time panel runs without Rprof or competing audit R workers. Full returned
objects are checked with `identical()` against the frozen before objects.

| Public scenario | Before | XML changes only | Final | Rows |
| --- | ---: | ---: | ---: | ---: |
| Raw KF 2018, all districts | 176.59 | 31.99 | 33.22 | 80,069 |
| Raw RD 2018, municipalities | 7.77 | 10.55 | 4.61 | 6,203 |
| Raw RF 2026, regions | 2.68 | 5.57 | 2.23 | 704 |
| Raw RF 2026, all districts | 78.64 | 53.47 | 18.16 | 85,426 |
| Canonical KF 2018, all districts | 0.63 | 0.11 | 0.12 | 80,069 |

KF district reduction is 81% (about 143 s saved); its two optimized isolated
runs are 31.99 and 33.22 s. RF district reduction is 77% against the initial
before panel, or 66% against the immediately preceding XML-only control. The
variation in unchanged RF and canonical controls is real: an XML optimization
cannot cause an RF JSON speedup. No benefit is attributed to XML for those
controls, and no canonical optimization is claimed. Original audit timings
around 149 s and 30 s were standard-view measurements in a different session;
percentage gains above use the fresh full-view before/after panel only.

Actual standard English and Swedish 2018 KF district calls also match the frozen
full object's exact projection/translation. Their validation times (50.31 and
56.73 s) were recorded while other validation workers ran, and are not used as
isolated performance comparisons. The Swedish `valresultat()` API is checked too.

### Approaches not retained or not implemented

- Moving all XML metadata assignments into a recyclable list added no convincing
  benefit beyond the smaller retained party-list change, so it was discarded.
- Additional root/ancestor-node plumbing targets only about 1.3% of sampled KF
  time and would complicate shared geography code; not implemented.
- No client-side concurrency, alternate downloader, larger retry budget or
  source-refresh change is introduced to hide network waiting.
- No persistent parsed-tree cache is added: memory use and invalidation of
  changing sources would add complexity. Existing explicit local/canonical
  reuse is retained and documented.
- No new municipality filter/API is added. Subsetting after a countrywide raw
  call still requires that call; canonical result views remain preferable for
  repeated analytical subsets.
- No priority-4 mandate-history optimization, new election stage, schema change,
  candidate-ID change or canonical rebuild is included.

### Validation

Final complete test suite and installed-package tests: **4,091 passes, 16
explicit external-data skips, zero failures/errors/warnings**. New regressions
cover XML row/type/zero/missingness/prototype behavior and scalar validation
classification, boundaries, NULLs, named lookup and error order.
**R CMD check --no-manual --no-vignettes: 0 errors, 0 warnings, 0 notes.**

Protected references: **9,529 historical source records**, **92 canonical asset
size/SHA256 checks** and **20 exact 2018 Parquet round trips** pass. The maintained
RF archive separately passes **42 ZIP, index and candidate-CSV** provenance
checks. Freshly acquired benchmark ZIPs also match their current official index.
Source-record counts are not counts of unique files. No protected source or
asset is overwritten. The completed cross-year comparisons are recorded below.
A separate nested transport probe measures `utils::download.file()` inside the
package helper for RF 25 and RF 01. Transfer times are 0.097 and 0.134 s;
complete helper times are 0.110 and 0.172 s. The additional package handling is
therefore only about 13 and 38 ms in these probes (including tracing overhead).
Both responses match the earlier acquired source checksums. This reinforces the
measured response-time variability; it is not evidence of a 20-second package
file-management overhead. Probe URLs/timestamps and MD5/SHA256 are retained in
`transport-events.csv` and `transport-checksums.csv`.

An additional protected-reference pass verifies all **102 assets** across the
2002, 2006, referendum 2003 and five EU build references. Together with the 92
core historical checks above, **194 protected asset entries** pass. All R-file
hashes match the audit's start snapshot except the four intended production
files: `R/valresultat_2018.R`, `R/valresultat_adapter.R`, `R/eu_2014.R`
and `R/eu_2019.R`. In particular,
mandate history, acquisition code, source selection and candidate-ID code match
the start snapshot.
### Additional EU result path

The full source-family review exposed a worthwhile additional application of the
already tested XPath helpers: eleven `xml_find_first/all` calls in
`.eu2019_geo()`, `.eu2019_result_node()` and `.eu2014_result_node()`. These three
shared functions serve EU 2004/2009/2014/2019 result construction. Replacing only
those calls preserves the XPath expressions, node order, attribute reads and
namespace semantics; candidate matching and source interpretation are untouched.
A real 20-node EU 2014 comparison takes 1.74 s before and 0.24 s after and every
complete node table is identical.

The actual cold-session EU 2004 national public request drops from **623.99 to
156.11 s**, with identical full output against the same protected reference.
Both timings are complete public requests, not the bounded node experiment.
All five final-result levels and the other six public functions also match that
reference exactly. Repeated requests use the existing verified bundle cache
(0.48 s in the old pass, 0.22 s in the new pass); no cache behavior was changed.
The baseline cold EU 2009 run was deliberately stopped, so no completed old
runtime or speedup percentage is claimed for it. Later EU timings are validation
observations, some alongside other validation jobs, not isolated before/after
performance comparisons.

This reveals a remaining structural cost: an initial EU XML `results()` request
builds the complete shared result/candidate/preference bundle, even for a narrow
requested result level. The warm call is cheap, but first-use work remains.
Splitting this source-specific bundle by requested table/level would be a larger
change and is not included. The eleven safe query substitutions deliver a real
public gain without undertaking that redesign.

A separate 200-node experiment with a session-global empty-schema prototype
reduces node construction from 2.11 to 1.67 s. No meaningful complete-request
benefit was demonstrated for that further generalization; it was not retained.
The 2018 prototype stays request-local, and no new global schema/parsed-data
cache is introduced.

Canonical control scenarios from the original audit were also repeated, with
exact before/current object comparisons:

| Canonical standard request | Before (s) | Current (s) | Rows |
| --- | ---: | ---: | ---: |
| KF districts, 2014 + 2018 + 2022 | 0.85 | 0.79 | 247,264 |
| KF 2018 districts, then Stockholm filter | 0.20 | 0.22 | 8,668 |

These small controls ran alongside validation; they establish unchanged data and
continued low cost, not a claimed canonical speedup or source-level pushdown.
The public API still has no municipality filter that avoids a countrywide raw
read.

The additional EU namespace regression adds 15 assertions. The complete final
suite and installed-package check report **4,091 passes, 16 explicit skips,
0 failures, 0 warnings**, with **R CMD check: 0 errors, 0 warnings, 0 notes**.
### Completed source-family checks and final scope

- **21 historical RKL public comparisons** pass frozen-helper/current/raw versus
  protected canonical, with exact values, row/column order, types and attributes:
  RD national, RF region and KF municipality for 2002/2006/2010/2014/2018, plus
  both preliminary/final versions of those three source-area views for 2022.
- **65 EU raw/canonical comparisons** pass: all 35 supported year/count/result-
  level combinations across 2004/2009/2014/2019/2024 and the other six public
  functions for each year. Each year's new raw bundle is built from a fresh
  process/session cache before its repeated and canonical checks.
- All **six referendum 2003 result levels** match the protected reference, and
  all **five re-election event result tables** match the frozen XML helper.
  The documented Orsa source is configured explicitly; no file is renamed.
- Actual modern primary-route controls additionally pass for RF national (O),
  RF municipality (U), RD municipal constituency (U), and KF county (O), against
  the frozen scalar validator. D and M are covered by the paired public panel.
  The missing local KF OS ZIP was acquired separately into the isolated audit
  cache, verified against the already acquired official index and recorded in
  `modern-kf-provenance.csv`; maintained source roots are unchanged.
- The exact API checks supplement, not replace, the **60 canonical final-level
  and 120 language/standard projection checks**, actual English/Swedish raw KF
  calls, the full unit suite, and source/asset/Parquet integrity checks above.
  A fresh full-country 2010/2014 preliminary reconstruction was not rerun here;
  its rules remain covered by the existing tests and unchanged source hashes.

Observed fresh-bundle and repeated EU request times (seconds):

| Year | Fresh bundle | Repeat | National rows |
| --- | ---: | ---: | ---: |
| 2004 | 156.11 | 0.22 | 28 |
| 2009 | 241.32 | 0.85 | 25 |
| 2014 | 240.19 | 0.25 | 23 |
| 2019 | 231.79 | 0.22 | 66 |
| 2024 | 0.31 | 0.10 | 101 |

Only EU 2004 has the completed old/new cold comparison of this follow-up.
Later rows are useful validation-run observations, not measured speedup ratios;
additional validation workers ran during parts of those measurements.

The first EU 2009 check selected the older precommit reviewed prototype. Its
party-result tables are identical to the subsequent clean build, but its
candidate/elected column order and `preference_vote_areas_count` predate the
approved commit. `reference-all.log` records that comparison. Rechecking against
`eu-2009-clean-4dd88b15` passes all eleven EU 2009 checks. No implementation or
candidate values were changed to satisfy a reference. Both reference generations
remain preserved. The additional clean-reference checks bring the total to
**208 protected asset entries** (92 core plus 116 extra), all unchanged.

Harness corrections are not data corrections. The initial new scalar test used
logical `NA` where an invalid numeric logical-field value was intended; it was
corrected to `NA_real_` without strengthening the legacy validation. The old XML
helper adapter also needed to accept/ignore the new private prototype argument
when comparing against the frozen five-argument function. Corrected runs pass.
An initial profile inherited an unsupported Windows locale; the final paired
unprofiled timing runs use the same explicit UTF-8 locale and exact saved output
objects. Profiled/failed-driver timings are not substituted for the final panel.

Changes in this follow-up are limited to:

- `R/valresultat_2018.R`: request-local prototype reuse and party-vector assembly;
- `R/valresultat_adapter.R`: vectorized name classification, identical scalar checks;
- `R/eu_2019.R` and `R/eu_2014.R`: eleven shared result/geography XPath substitutions;
- `tests/testthat/test-performance-2018.R`: 50 additional XML/prototype assertions;
- `tests/testthat/test-performance-results.R`: 59 scalar/EU namespace assertions;
- this report.

The final complete and installed test suites both report **4,091 passes, 16
explicit skips, no failures or warnings**. Final **R CMD check is OK (0 errors,
0 warnings, 0 notes)**, and `git diff --check` passes. The historical source
hashes, maintained RF source provenance, 208 protected asset entries and 20
Parquet round trips pass. The new acquisition manifest is
`network-provenance.csv` (21 original benchmark objects), with the small KF
control and transport probes separately documented. No source/canonical assets
are tracked by this task. Earlier uncommitted mandate-history and priorities
1--3 work remain intact. No priority-4 optimization, cleanup, commit, push, tag
or release is performed.

## Cross-year EU comparison (20 October 2026)

This is a measurement-only follow-up. No further optimization, source selection,
candidate-value treatment, API or schema change is made.

### Coverage and routing

All **five** EU years already have local, unpublished canonical prototypes for
all seven functions: results, seats, candidacies, candidates, elected, substitutes
and preference votes. None of these EU prototypes is auto-eligible; each manifest
has `release_status = unpublished_local_validation_build` and
`auto_eligible = false`. Reading one requires a configured manifest and an
explicit `source = "canonical"`. Merely having built it does not make an
`auto`/`local` request use it. EU 2024 is a canonical reference here, not a
published EU release.

| Year | Existing canonical assets | Final result levels | Complete preliminary support | Raw path when requested |
| --- | ---: | --- | --- | --- |
| 2004 | 14 | national, county, municipality, municipal constituency, district | No | XML + ballot archive + district text exports; whole bundle |
| 2009 | 14 | same five levels | No | XML + ballot XML + small-party workbook; whole bundle |
| 2014 | 14 | same five levels | No | original XML ZIP + candidacy/auxiliary files; whole bundle |
| 2019 | 15 | same five levels | Yes | XML ZIP + candidacy/auxiliary files; bundle per counting stage |
| 2024 | 15 | same five levels | Yes | ZIP/JSON + candidacy CSV; selected JSON kind and level |

No supported final function is raw-only in this set. The absence of a complete
preliminary source for 2004/2009/2014 is a source-coverage issue, not a slow path
that canonicalization can repair. The timings below concern **final** results.

### Method and first-call cost

New evidence is in ignored `.local-data/performance-eu-comparison-20261020/`:
`compare.R`, `compare.log`, `measurements.csv`, five sampling profiles and their
summaries. Years were run serially, without concurrent validation workers.
The first call for each year is the actual public call:

```r
results(year, "E", source = "local", data_dir = source_directory,
        progress = FALSE, detail = "full")
```

The year-specific parsed cache is empty. Source files are already local; the OS
file cache is not flushed. Therefore these are **first parser/bundle calls**,
not first downloads or guaranteed cold physical-disk reads. `Rprof(interval =
0.02)` samples only this first call. All subsequent timings are unprofiled
elapsed seconds. The profiling figures are diagnostic elapsed observations,
not replacements for the earlier unprofiled benchmarks or speedup estimates.

| Year | Earlier unprofiled first raw call | New first raw call, profiled | Repeated local results, same session | Configured canonical results |
| --- | ---: | ---: | ---: | ---: |
| 2004 | 156.11 | 172.54 | 0.45 | 0.37 |
| 2009 | 241.32 | 254.86 | 0.27 | 0.06 |
| 2014 | 240.19 | 200.47 | 0.12 | 0.06 |
| 2019 | 231.79 | 220.14 | 0.13 | 0.08 |
| 2024 | 0.31 | 0.22 | 0.06 | 0.07 |

The earlier unprofiled 2009/2014/2019/2024 observations came from the preceding
validation run, with other validation workers active during parts of that run;
only 2004 had the prior isolated old/new comparison. They establish scale, not
a controlled before/after comparison with this follow-up.

For XML years 2004--2019, a first default candidate/elected/substitute/preference
request also requires the same whole final bundle. Calling those functions
after `results()` must not be described as an independent cold benchmark for
each function. Restarting R loses that parsed bundle even when the original
files remain local. `candidacies()` and `candidates(include_results = FALSE)`
can bypass bundle construction in 2014/2019; the table below uses the default
enriched `candidates()` call.

### Public functions after the first result call

All use final, English `detail = "full"`, default selection and enrichment;
preference votes use the default preference-vote area (national for EU). Calls
run in the listed order. For 2024 these are progressively reused JSON caches,
not the XML whole-bundle mechanism.

| Year | results | candidates | elected | substitutes | preference_votes |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2004 | 0.45 | 0.40 | 0.35 | 0.12 | 0.14 |
| 2009 | 0.27 | 0.33 | 0.31 | 0.22 | 0.23 |
| 2014 | 0.12 | 0.39 | 0.69 | 0.13 | 0.47 |
| 2019 | 0.13 | 0.24 | 0.22 | 0.06 | 0.12 |
| 2024 | 0.06 | 0.41 | 0.41 | 0.06 | 0.10 |

Configured canonical elapsed seconds for the corresponding first call to each
surface in this sequence (some assets may already have been cached by an earlier
surface; this is not a fresh R process for every cell):

| Year | results | candidates | elected | substitutes | preference_votes |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2004 | 0.37 | 0.03 | 0.03 | 0.02 | 0.11 |
| 2009 | 0.06 | 0.01 | 0.02 | 0.02 | 0.05 |
| 2014 | 0.06 | 0.02 | 0.01 | 0.03 | 0.06 |
| 2019 | 0.08 | 0.02 | 0.02 | 0.01 | 0.03 |
| 2024 | 0.07 | 0.02 | 0.03 | <0.01 | 0.05 |

Municipality/district result requests after the same sequence:

| Year | Local municipality | Canonical municipality | Local district | Canonical district | District result rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2004 | 0.20 | 0.14 | 0.30 | 0.26 | 175588 |
| 2009 | 0.24 | 0.08 | 0.27 | 0.08 | 77576 |
| 2014 | 0.19 | 0.11 | 0.22 | 0.12 | 76688 |
| 2019 | 0.08 | 0.08 | 0.11 | 0.10 | 86943 |
| 2024 | 9.29 | 0.08 | 4.80 | 0.09 | 95167 |

The XML district requests above reuse data materialized by the first national
call. The 2024 municipality/district requests instead trigger the first use of
additional JSON kinds (`summering` / `rostfordelning`); their times include that
reading and transformation. They are not warmed result-cache timings.

Additional EU 2024 checks in a **separate fresh R process per surface**, without
profiling (default final national/area selection):

| Surface | First local call | Repeat, same session |
| --- | ---: | ---: |
| results | 0.20 | 0.14 |
| candidates | 0.54 | 0.56 |
| elected | 0.53 | 0.57 |
| substitutes | 0.11 | 0.20 |
| preference_votes | 0.27 | 0.27 |

Fresh EU 2024 municipality/district result checks:

| Level | First local call | Repeat, same session |
| --- | ---: | ---: |
| municipality | 8.89 | 0.14 |
| district | 4.98 | 0.15 |

### Where the first-call work goes

These are **sample shares**, not exact wall-clock phase timers. The Windows
profiler captured fewer nominal sample-seconds than the stopwatch elapsed;
they must not be multiplied by elapsed time to invent a timing split. Categories
are mutually exclusive, classified from the sampled call stacks. File reading
includes decoding/decompression visible in read functions. Other includes
geography, joins, binding, remaining checks and public-output construction.

| Year | Read/decode | Find/verify sources | Result rows | Preference extraction | XML adaptation/construction | Other |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2004 | 1.5% | 0.6% | 56.7% | 0.0% | 27.2% | 14.0% |
| 2009 | 0.9% | 0.3% | 45.6% | 36.2% | 10.2% | 6.7% |
| 2014 | 1.1% | 0.0% | 50.8% | 40.8% | 0.0% | 7.3% |
| 2019 | 1.0% | 0.1% | 46.0% | 45.7% | 0.0% | 7.2% |

EU 2024 national results finish too quickly for a useful phase percentage
from this profile; no conclusion is drawn from its handful of samples.

The common older-year cost is **eager whole-bundle materialization**. Even a
national result request builds party results, geography and (in 2009/2014/2019)
district candidate/list preference tables for the whole country. EU 2004
additionally constructs synthetic XML nodes in memory from the preserved text
exports before passing them through shared result normalizers. This is an
adapter operation; the raw files are unchanged.

Within result-row construction, `.valresultat_schema()` is rebuilt for every
geographic node. Its inclusive sample shares are:

- 2004: 32.8%.
- 2009: 27.9%.
- 2014: 30.5%.
- 2019: 28.0%.

These inclusive schema shares are already inside the result-row category;
they must not be added to it. Repeated tiny tibbles, geography extraction and
list/preference extraction are shared costs. Actual XML input decoding and
checksums are small in these local runs. The main cost is not fetching data
from Valmyndigheten, and changing download handling would not address it.

No network timings are invented here: all sources were already preserved.
The 2004/2009/2014 raw readers deliberately require pinned local originals;
the 2019/2024 remote paths have separate session download caches but were not
invoked in this comparison. Fresh downloads would be an additional cost.

### Assessment and next-step recommendation

- **EU 2004 is not an isolated slow first-read case.** EU 2009, 2014 and 2019
  show the same minutes-to-subsecond first/reused pattern. Their shared XML
  bundle architecture explains the result better than election age alone.
- **The older years are not waiting for their first canonical builds.** All
  already have working configured canonical routes, including the five focused
  functions. Making those validated builds available through the agreed data
  distribution policy would avoid the first-call raw cost; auto-eligibility is
  deliberately not changed in this audit.
- A separate, narrowly scoped optimization assessment is justified if raw
  rebuilding remains an important workflow: first test request-local schema
  prototype reuse in the shared EU result reader. The profiles establish a
  substantial common cost, but do not establish a public-call speedup or its
  size. The preceding 200-node prototype experiment was insufficient to retain
  a change; no global mutable prototype cache is introduced here.
- Avoiding unrequested preference/relation/geographic work could remove more
  cost, but splitting the whole bundle needs a more careful design and cache
  validation. It is a larger change than reusing a local prototype. Do not
  undertake it merely to improve already-fast configured canonical requests.
- No new parser, network retry/cache mechanism, priority-4 optimization or
  additional production optimization is implemented.

### Checks and scope

The new panel passes **45 exact full English raw/canonical comparisons** (all
seven public functions plus municipality and district results, for each of five
years), **35 repeated-canonical identity checks**, and the fresh EU 2024 repeat
checks. Equality includes row order, types and attributes. Code/test file hashes
before and after the serial panel are identical. Existing source verifications
run through the normal readers; source and canonical references are not rebuilt
or replaced. The unresolved EU 2009 candidate/geographic treatment is untouched.

Only this performance report is changed outside ignored diagnostic evidence.
No package tests or `R CMD check` rerun is needed for a documentation-only audit;
the previous full-suite/check results remain the preceding recorded results,
not new claims from this comparison. `git diff --check` is rerun. No commit,
push, tag or release is made.

## Request-local EU schema reuse and source-selection review (20 October 2026)

This follow-up implements only request-local result-schema reuse for EU 2004,
2009, 2014 and 2019. Source/default behavior is **not changed**. Its separate
audit and implementation proposal are in [SOURCE_SELECTION_DESIGN.md](SOURCE_SELECTION_DESIGN.md).

### Measured construction cost and implementation

An instrumented actual EU 2004 national `results()` call requested the schema
**6,769 times**. Timers inside the schema builder measured **72.72 seconds**
out of **208.27 seconds** total (about 35%; a diagnostic observation, not a
phase-additive prediction). Returning a prototype in that experiment produced
exactly identical public output in 117.02 seconds. This justified a production
change, rather than retaining a small isolated-node experiment.

Each `.euYEAR_bundle()` now constructs the empty typed prototype once after
checking its existing bundle cache. It passes it through the existing
`.eu2004_result_node()` / `.eu2014_result_node()` / `.eu2019_result_node()` chain.
Each output slices that prototype using the same row-index operation as before.
Default private arguments preserve direct helper calls. No global schema cache,
new bundle contents, lazy-reader architecture, filtering or data logic is added.
The public column-selection helper still builds its own schema once: the first
public request has two constructions, rather than thousands. A cached result
view generally has only the column-selection construction left.

### Actual public before/after benchmark

Both versions were loaded as full packages in **separate fresh R processes**,
serially. The baseline is the frozen start-of-task working-tree implementation,
including previous optimizations; it is not repository HEAD or a clean Git
commit. Source files are already local, OS disk caches are not flushed, and
package startup is outside the measured call. A small identical builder-call
counter is used in both versions; there is no sampling profiler in this panel.
These are single paired elapsed observations, not statistical confidence bounds.

The measured call is:

```r
results(year, "E", source = "local", data_dir = source_directory,
        detail = "full", progress = FALSE)
```

It requests national final results but still constructs the existing full
raw bundle. No bundling or source-coverage rules have been changed.

| Year / count | Before (s) | After (s) | Time saved | Schema builds before / after |
| --- | ---: | ---: | ---: | ---: |
| 2004 / final | 244.85 | 129.49 | 47.1% | 6769 / 2 |
| 2009 / final | 163.11 | 115.54 | 29.2% | 6559 / 2 |
| 2014 / final | 607.13 | 263.89 | 56.5% | 6721 / 2 |
| 2019 / final | 259.56 | 183.93 | 29.1% | 6671 / 2 |
| 2019 / preliminary | 117.32 | 57.11 | 51.3% | 6671 / 2 |

**EU 2014 timing qualification:** elapsed time fell from 607.13 to 263.89
seconds, but CPU time (user + system) fell only from 259.58 to 245.27 seconds
(5.5%). The large elapsed reduction is affected by host scheduling/load; it
must not be interpreted as a reproducible 56.5% algorithmic speedup. The two
CPU observations support a smaller gain in this year. The earlier interrupted
and unpaired runs are excluded. The much clearer 2004/2009/2019 public-call
reductions and the measured schema construction cost justify the shared change.

The 2019 preliminary row is a separate first bundle for that count stage;
it is measured after the final views in each process. All five final result
levels, all five preliminary levels for 2019, and the other six public functions
are checked. Once a bundle exists the remaining operations are already short;
no separate speedup claim is made for the reused candidate/elected/substitute
or preference-vote views.

Evidence is preserved in ignored `.local-data/performance-schema-20261020/`:
`baseline/`, `experiment.R/.csv/.log`, `clean-stage.R`, the eight completed stage
CSVs, per-stage logs, saved full before outputs and `final-paired.csv`.
The first helper-environment comparison driver was excluded from the final
panel in favor of full-package loading. An initial EU 2014 after-run was
interrupted by a long execution pause and discarded. The final matched 2014
pair was repeated after the pause with CPU timings as well. Its logs are
`paired-post-pause-before-2014.log` and `paired-post-pause-after-2014.log`.
The intermediate retry is retained, but not used in the timing panel.
No paused elapsed time is used. The validation
waiter also expired during that pause and was restarted; this was not a code
or data-validation failure.

### Other result paths

Other-year controls use the unchanged production readers and preserved
canonical/full-output references. Builder timers for small numbers of calls
have coarse resolution and are diagnostic only:

| Case | Elapsed (s) | Schema builds | Time inside schema builder (s) |
| --- | ---: | ---: | ---: |
| rkl-2002-RD-national | 0.22 | 2 | 0.02 |
| rkl-2006-RD-national | 28.52 | 2 | 0.03 |
| rkl-2010-RD-national | 66.33 | 2 | 0.04 |
| rkl-2014-RD-national | 75.56 | 2 | 0.04 |
| rkl-2018-RD-national | 1.00 | 2 | 0.06 |
| rkl-2022-RD-national | 0.63 | 2 | 0.04 |
| rkl-2018-KF-district | 66.39 | 2 | 0.05 |
| rkl-2026-RF-region | 5.46 | 40 | 0.69 |
| eu-2024-municipality | 27.89 | 2 | 0.03 |

RKL 2018 already reuses its request-local XML prototype. Modern RKL JSON
constructs it per selected result file rather than per district node. EU 2024
uses the JSON parsers and builds the harmonized prototype at output assembly;
it does not use the expensive older-EU result-node chain.

The pre-2018 RKL district adapters still call `.xml2018_partirader()` without
a shared prototype, and 2011 re-election SKV and the small 2002 complementary
district reader also have per-unit construction. The single-national controls
do not establish a full-district speedup for those paths. They are left unchanged;
no claim is made that every schema construction in the package has been removed.
The retained implementation is limited to the measured older-EU bottleneck.

### Regression and integrity validation

All **49 selected cases** are exactly identical to their saved before outputs
(including row order, types and attributes). Canonical comparisons and the
English/Swedish, standard/full matrix bring the paired panel to **294 exact
comparisons**. New deterministic tests verify explicit prototype reuse through
each adapter, unchanged schema objects across repeated calls, reported zero
versus missing values, preliminary other-party aggregation, and rejection of
inconsistent party/valid totals.

The source-choice implementation is byte-unchanged. Changes in this stage are:

- `R/eu_2004.R`, `R/eu_2009.R`, `R/eu_2014.R`, `R/eu_2019.R`: prototype threading only;
- `tests/testthat/test-performance-results.R`: targeted regression tests;
- this report and the new source-selection design report.

Earlier uncommitted mandate-history and performance work remains intact. No
source files, candidate identities, canonical assets, election values or public
API defaults are changed. No larger older-EU optimization, commit, push, tag
or release is performed.

Final full test suite: **4115 passed, 16 explicit skips, no failures, warnings or errors**.
Final **R CMD check: 0 errors, 0 warnings, 0 notes (Status: OK)**.
Independent checks verify **9,529 original source hashes**, **208 protected
asset entries** across the retained historical/EU reference generations, and
**20 Parquet round trips**. Nine additional other-year result controls pass.
`git diff --check` passes. No original source or canonical asset is rebuilt or
replaced; the staged package tarball/check directory is disposable validation
output, not a data release.

## 21 October 2026: elected KF remote failure and measured acquisition

The installed and optimized pre-fix elected readers both failed at Salem, the ninth final KF file. This is a cross-municipality candidacy join error, not a missing official Salem party row. The targeted fix and independent all-KF validation are documented in [VALIDATION_ELECTED_2026_REMOTE.md](VALIDATION_ELECTED_2026_REMOTE.md).

The corrected full KF remote call returned 12,528 elected candidates in 187.67 seconds: 292 distinct downloads, 56.62 MB, 27.59 seconds of actual acquisition. Preserved-response replay of the same public call took 123.03 seconds; English/full replay took 129.75 seconds. These are diagnostic timings, with validation processes sometimes running concurrently. They do not reproduce an eight-minute network transfer. The purrr file progress estimate includes parsing, validation and table construction. No persistent remote caching or additional broad optimization was introduced. RD/RF output and the shared 2022 elected path remain unchanged.

### Closing assessment of KF 2026 elected remote performance

The remaining 160.08 seconds are accounted for by 1.84 seconds index/CSV parsing, 17.74 ZIP/JSON reading, 17.04 candidate base construction, 90.96 per-file validation/construction, 6.66 final enrichment and 25.84 residual orchestration/presentation/instrumentation. These categories do not overlap. The residual is not an established optimization opportunity. No further code optimization is retained.

The no-network replay in the preceding measurement is an audit facility. A targeted two-pass production-reader probe confirms that index, candidacy CSV and mandate ZIP acquisition each invoke transport again on the second pass. Normal remote has no persistent response cache; repeat downloads are not prevented across calls. No new cache policy is introduced here. See the closing assessment in [VALIDATION_ELECTED_2026_REMOTE.md](VALIDATION_ELECTED_2026_REMOTE.md).

## 21 October 2026: persistent verified remote raw cache

The prior absence of a production response cache is now addressed. Indexed official result ZIP bytes are persisted in a user-specific cache, checked against a freshly downloaded index per public request. Nothing parsed is persisted. Candidacy CSVs outside the result index remain fresh downloads. See [REMOTE_RAW_CACHE.md](REMOTE_RAW_CACHE.md) for source semantics, tests and exact timings.

The actual KF 2026 elected benchmark in separate R processes is: uncached control 100.22 seconds / 26.92 network seconds / 292 requests; cold cache 84.19 / 22.90 / 292; warm cache 60.66 / 1.60 / 2. All outputs are exactly identical to the approved 12,528-row result. The warm call downloads only index and candidacy CSV, never the 290 unchanged ZIPs. Earlier detailed 187.67-second timings are not a controlled measure of the cache speedup.
