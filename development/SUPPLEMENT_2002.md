# Official 2002 RD four-party supplement

The authoritative source is Valmyndigheten's
[Resultat Riksdagsval Övriga partier – en komplettering](https://historik.val.se/val/val_02/slutresultat/tillagg_ovriga.pdf).
A fresh official download on 13 October 2026 is byte-identical to the preserved
local PDF: 45,650 bytes, MD5 `b0094d49a33e919a9cf2d865f72fe78e`,
SHA256 `83fa892e978ca3adac82189e8b685d262ac5e443937b9bad666ce70e56141dff`.
PDF creation/modification metadata is 13 December 2002, 12:26:58 +01:00;
this is not asserted to be its publication time. Exact retrieval UTC and
checksums are in `inst/extdata/rd-2002-party-supplement-provenance.json`.
No raw PDF is distributed with the package.

## Public result semantics

The small packaged CSV is an audited transcription of 116 constituency cells
and four explicit national sum cells. It contains 107 disclosed constituency
counts, including genuine zeros, and nine missing cells. Its SHA256 is pinned
by the provenance JSON and checked by the reader.

- National output uses the four explicitly reported sum values: Fria Listan
  502, Nationaldemokraterna 9,248, Ny Demokrati 2,207 and Populistpartiet 11.
  These are official reported sums; they are not proof that every undisclosed
  cell has zero votes. All undisclosed votes remain in residual other parties.
- Constituency output exposes all four parties in every constituency, with
  integer `NA` counts and `NA` shares for the nine undisclosed cells.
- County values are sums only when every relevant constituency discloses that
  party. Otherwise the county count/share is `NA`; seven county-party cells
  remain unknown. No partial county total is passed off as complete.
- Positive municipality/district counts are not allocated from aggregate totals.
  An explicit constituency zero can, however, correct an existing observation
  in its contained geography. Populistpartiet in Gävle (1) and Hudiksvall (7)
  therefore become 0, restoring those votes to the residual. No new lower-level
  zero rows are generated and no undisclosed cell is filled.
- Named parties without a source-established numeric code retain the existing
  missing code and official alias/designation. No party/candidate ID is invented.

The result-only reader replaces the four older other-party subtotals and
recomputes residual other votes from the unchanged parent aggregate after
subtracting all individually known party counts. Unknown-party rows do not
remove any numeric votes from the residual. Known zero is distinct from NA.
The national residual becomes 3,403; valid/combined-invalid/cast totals and
mandates are unchanged. Different geographic levels can have different
amounts of individually disclosed detail, so their residual categories need
not represent an identical set of undisclosed parties.

The transformation changes only fresh, in-memory result-reader XML documents.
It is not applied to candidate, preference-vote, elected, substitute or mandate
readers. No raw snapshot is rewritten. The build manifest records the official
supplement provenance separately from the selected XML source registry.

## Independent validation

`Rscript data-raw/validate-supplement-2002.R RAW_ROOT` extracts the pinned PDF
with the development-only `pdftotext` utility and parses its columns independently
from production logic. It matches every cell, preserves blanks, verifies the
sum rows, and checks public counts and all geographic partitions against raw
XML totals. It uses R; the R package has no PDF parser or Python runtime dependency.
Other retained XML/SCB validators continue checking unmodified source values.
Old SCB minor-party detail is not used to overwrite the explicit correction.

## Package-build tar archives

The previous check note identified six old `valresultat_*.tar.gz` build archives
at repository root. They are harmless development artefacts but are not package
content. The targeted `.Rbuildignore` expression
`^valresultat_[0-9].*\.tar\.gz$` excludes them from the source package.
The archives are neither deleted nor altered. Check staging deliberately retains
those files before `R CMD build` to verify that the rule removes the note.
