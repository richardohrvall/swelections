# RF 2026 official source correction — current-source activation

Valmyndigheten confirmed that the RF double-counting error was corrected on
5 October 2026. The 10 October review compares the corrected official `val2026`
index with the preserved
pre-correction index. It does not change election semantics, candidate identity
rules, canonical assets or published releases.

## Source generation and provenance

The official index is
<https://resultat.val.se/resultatfiler/val2026/index.md5>.
Only two of its 626 source entries changed:

| Source path | Preserved MD5 | Corrected MD5 |
|---|---|---|
| `s/rf/Val_2026_slutlig_01_RF.zip` | `1eb0ebe760c93f70bd98bc45cf79aa45` | `ffd7eb0ecffbaaefe50d8ff1c79ecad9` |
| `s/rf/Val_2026_slutlig_OS_RF.zip` | `64e925d94151c72c85a8f6de786259f1` | `761f69789f778ae5174e6c1f7195e6d4` |

The other 624 entries, including preliminary RF, RD, KF and the other final RF
regions, are unchanged. Stockholm's root update timestamp changed from
`2026-10-02T13:37:48` to `2026-10-05T14:17:44`, consistent with the correction
date communicated by Valmyndigheten.

A complete current RF source set (42 preliminary/final ZIPs, including both OS
files) was retrieved sequentially and verified against the official index.
The immutable acquisition snapshot is external to Git:
`C:/valdata/corrected-snapshots/20261010-rf`.
Its `provenance.json` records URLs, UTC retrieval times, sizes, MD5 and SHA256.
`index-comparison.csv` records the full index comparison.

## Current-source workflow (activated 11 October 2026)

The corrected snapshot is now activated in the current external raw archive,
`C:/valdata/2026/val2026/`. All 42 RF preliminary/final ZIPs, the official index
and the unchanged candidate CSV were verified before installation and compared
byte-for-byte with the immutable acquisition snapshot afterward.

Future RF processing uses `source = "local", data_dir = "C:/valdata"`, or
`source = "auto"` with that archive configured. For example:

```r
results(2026, election = "regional", count = "final", level = "region",
        source = "local", data_dir = "C:/valdata")
```

The archive root remains configurable; no package default or global R option
was changed. `source = "remote"` continues to use the corrected official URLs.
The workflow does not read the old validation snapshot as a current input.

Acquisition provenance is preserved both in the immutable snapshot's
`provenance.json` and beside the active raw sources as
`rf-source-provenance-20261010.json`. It records each file's official URL,
retrieval timestamp, size, MD5 and SHA256. Any differing pre-existing current
file is preserved before replacement under
`archive/pre-rf-correction-20261011/`; existing historical snapshots are retained.
No raw file or generated data asset is committed to Git.

There is no 2026 canonical builder or prototype in this stage. A future 2026
backend/build must select this corrected generation, verify the recorded hashes
and report any later source generation separately rather than silently mixing
versions. Historical canonical releases and eligibility are unchanged.

| Corrected file | Retrieved (UTC) | Bytes | SHA256 |
|---|---|---:|---|
| Stockholm final | 2026-10-10 14:01:47 | 5,972,274 | `397566f9c5f82862d32e0735290e7b15fb08333986fc747ae1ce04b922b9b95b` |
| National final OS | 2026-10-10 14:02:00 | 207,315 | `809734bf28e44a633e7f95c64b4efcc7a16f4362734f1d2bdba67d062eba2d1f` |

The index MD5 is `099c0a4730ec1e980fa9b788cb7b406e`; its SHA256 is
`5446f0578420c6390e236fc8e822ab3f478ee270627c46bf5853464cc9fd414f`.
The current candidate CSV, downloaded from
<https://data.val.se/filer/val2026/parti/kandidaturer.csv>, is byte-identical to
the preserved CSV (MD5 `c30f47a4ea28da2d926e0e186477a98b`).

The old Stockholm ZIP remains unchanged in the prior validation snapshot.
No old OS ZIP was found locally: its old MD5 is known from the preserved index,
but a direct old/new OS JSON comparison is unavailable. Before/after national
changes are instead independently established from the regional sources: the
old Stockholm ZIP plus 19 region ZIPs matching their old index hashes exactly.
This comparison view was temporary and is not a package source.

## Substantive changes

Only four Norrtälje (`0188`) districts have changed total votes:

| District | Name | Before | Corrected | Change |
|---|---|---:|---:|---:|
| `01882201` | Rådmansö - Västra | 1,875 | 949 | -926 |
| `01882202` | Rådmansö - Östra | 1,777 | 900 | -877 |
| `01882301` | Frötuna - Östra | 2,651 | 1,332 | -1,319 |
| `01882302` | Frötuna - Västra | 1,776 | 896 | -880 |

The reduction is 4,002 valid votes; invalid votes are unchanged. Stockholm's
all-vote total changes from 1,584,907 to 1,580,905; Nordost (`0110`) from
188,119 to 184,117; Norrtälje from 49,114 to 45,112. National RF totals are:

| Measure | Before (regional sum) | Corrected (regional sum and OS) |
|---|---:|---:|
| All votes | 6,859,508 | 6,855,506 |
| Valid votes | 6,742,501 | 6,738,499 |
| Invalid votes | 117,007 | 117,007 |

Party vote reductions (official party codes) in Stockholm are:
`0001: 1,089`, `0002: 973`, `0003: 164`, `0004: 268`, `0005: 139`,
`0055: 187`, `0068: 341`, `0110: 824`, `0471: 1`, `1296: 6`,
`1325: 3`, `1551: 6`, `1693: 1`; sum 4,002.

Nordost has 125 changed candidate × party × preference-vote-area totals,
reducing preference votes by 612. Stockholm's candidate preference-vote sum
changes from 303,085 to 302,473. The previous source had 18 area-level lists
whose detailed candidate sum exceeded `antalRosterMedPersonrost`, by 612 in
total; its district `summeradePersonroster` also contained the excess, although
the district list details did not. The corrected area lists, district lists
and candidate sums agree. Across all 20 current RF regional files there are
zero list-counter, area/district list or candidate-sum conflicts in the
independently checked reported values. The full area/district union also has
no one-sided positive values across 4,231 list keys and 24,832 candidate keys.
No validation rule was relaxed.

Seat allocations are unchanged at region and regional-constituency levels.
Stockholm still has 149 elected and 515 substitute relations, with unchanged
relation keys, election order and substitute order/group. The official election
basis for candidate `16929`, party `0110`, Nordost, changes from preference
votes (`1`) to comparison number (`2`); Nordost's qualified-candidate list
changes from two entries to one. These are source corrections, not package
identity changes. Array-position JSON differences must not be interpreted as
identifier replacements: comparisons use the existing source keys.

## Validation and rebuild scope

Actual public `results()` calls succeed for district, municipality, municipal
constituency, regional constituency, region and national levels. Party/category
votes reconcile exactly from districts to all municipalities, all regions and
the OS national file. For the actually represented separate constituencies,
all 969 municipal-constituency rows and 1,436 regional-constituency rows also
reconcile. Districts in undivided areas are not additional constituency-level
observations.

Public RF preference-vote calls also pass: 58,354 preference-vote-area rows
(24,832 positive), and 12,868 region rows (12,346 positive), with no missing
preference-vote counts in either view. Both sum to 1,402,504 preference votes;
aggregation recalculates shares and retains the same numerator total.

No production-code change is needed to read the corrected source generation.
Any future 2026 canonical build using the old files must refresh final RF
results, seats' vote-derived/context fields, candidates, elected enrichment and
election basis, preference-vote views and normalized area/district preference
bases. Substitute relationships are unchanged, but associated corrected source
provenance must be recorded. Candidacies are unchanged. No 2026 Parquet build
or published asset replacement was performed in this task.

Validation outputs and keyed before/after comparisons are ignored development
artefacts under `.local-data/rf-correction-review/`. Historical 2010, 2014,
2018 and 2022 reference assets and 2,497 preserved source checksums were verified
unchanged. The package test suite passed with its ten explicit opt-in skips;
`R CMD check --no-manual --no-vignettes` reported 0 errors, 0 warnings, 0 notes.
## Candidate-level consequence

Britt Mari Canhasi, candidate `16929`, party `0110` (SD), list `0110-10393`,
Region Stockholm (`01`), Nordost (`0110`), has the following source correction:

| Field | Before | Corrected |
|---|---|---|
| Nordost preference votes | 1,182 | 1,128 |
| Nordost party votes | 23,456 | 22,632 |
| Candidate-wide RF preference votes | 1,215 | 1,161 |
| Qualified preference-vote areas | 1 | 0 |
| `valgrundId` | 1 | 2 |
| `valgrundText` | Ledamoten är vald på personröster | Ledamoten är vald på jämförelsetal |

The corrected Nordost share is approximately 4.9841%, below the 5% threshold;
the previous share was approximately 5.0392%. The 54-vote candidate correction
is confined to the same four Norrtälje districts. The old district list details
already summed to 1,128, while the old candidate summaries contained the excess.
This supports the election-basis change as a consequence of the counting
correction; it does not provide evidence of an independent identity correction.

Candidate ID, list position, elected geography, election order, substitute group
and nested substitute relations are unchanged. Only `valgrundId` and
`valgrundText` differ within the elected record. No candidate-ID rule is changed.

## Activation validation — 11 October 2026

Validation was repeated through the public API using the active archive
`C:/valdata`, not the old source files. All six final RF result levels are
identical to the previously verified corrected snapshot: district (85,426 rows),
municipality (5,554), municipal constituency (969), regional constituency
(1,436), region (704) and national (141). Party/category sums agree exactly
between districts and each official higher level for its represented geography.
National totals remain 6,855,506 all votes, 6,738,499 valid and 117,007 invalid.

Both mandate levels match the corrected reference, and every seat-allocation
field matches the preserved pre-correction values. Preference-vote-area and
region views match the corrected reference exactly, including recalculated
shares. The public elected row confirms candidate `16929`, total preference
votes 1,161 and election basis `2`. Independent raw extraction from all 20 final
regional files matches the corrected reference, with no list-counter conflicts.

All 43 activated source files plus the index were hash-verified; the 42 ZIPs and
candidate CSV additionally passed recorded file-size checks. The preserved
historical 2010/2014/2018/2022 reference assets and all 2,497 original source
checksums are unchanged. The standard test suite passed with ten explicit
opt-in skips. `R CMD check --no-manual --no-vignettes` on the unchanged,
integrity-verified package source reported 0 errors, 0 warnings and 0 notes.
`git diff --check` passed.

This source-correction commit contains only this report. It changes no package
code, candidate-ID handling, public schema, canonical registry or release data,
and creates no canonical prototype, tag or release.
