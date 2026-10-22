# Re-election implementation

> Release status: [published v0.4.0](releases/v0.4.0.md). Dated source,
> prototype and validation statements below are historical evidence, not current
> activation/publication status. Source limitations and provenance remain applicable.


This implementation supports final event results and mandate allocations for
Orsa 2003, Västra Götaland 2011, Örebro Nordöstra 2011, Båstad 2015 and Falun 2019.
The [source inventory](SOURCE_INVENTORY_OMVAL.md) remains the source-review record.

## Selection and composition

`results()` and `seats()` accept `election_kind = "ordinary"` (default),
`"re_election"`, or `"all"`. `year` selects actual polling years. Ordinary
longitudinal selections exclude reruns; a single rerun-only year gives an
informative error rather than substituting an event. `election_events()`
provides the stable IDs, scope, original-event links, continuing mandate period,
roll reference dates, protocol references, availability and pinned source hashes.
Unknown annulment and legal final-decision references/dates remain missing. The registry records source count-end dates separately; these are not legal decision or service dates.

Only `seats()` accepts `after_re_election = TRUE`, requiring ordinary, final
allocations. Here year/range selects the **original election years**. Replacements
are followed even if their polling years lie outside the requested original-year
range. The default composition level is municipality (KF), region (RF), or
national (RD). Only one of those whole-area levels can be requested for a
composition. Regular `seats()` retains its previous level behaviour.

Components are separate party rows, identified by `component_election_event`,
`component_election_year`, `component_geographic_level` and
`component_geographic_code`. `composition_id`/`composition_type` identify the
derived result, and `election_year`/`election_event` identify the original poll.
`mandate_period` remains the original period. Repeated `total_seats` is the
whole-area composition total, not an additive column. Source comparison fields
in full output retain their component-source meaning, not a new cross-date
comparison. No service dates or membership history are inferred.

| Original selection | Replacement | Affected composition |
|---|---|---|
| 2002 KF | Orsa 2003 | 31 seats from the rerun |
| 2010 RF | Västra Götaland 2011 | 149 regional seats from the rerun |
| 2010 KF | Örebro Nordöstra 2011 | 48 original seats + 17 rerun seats = 65 |
| 2014 KF | Båstad 2015 | 41 seats from the rerun |
| 2018 KF | Falun 2019 | 61 seats from the rerun |

All other areas keep their original allocations. Original and replacement
party-level allocations are read from sources, never calculated from combined
votes. Örebro's original Nordöstra allocation is checked against the official
2011 comparison before replacement. Missing inputs or conflicting hashes/party
allocations stop the request. Replacement events are processed chronologically;
the model allows multiple events per original election. A later partial event
requires verified constituent allocations, not an inferred split of a preceding
whole-area result.

Swedish wrappers share the same implementation:
`mandat(ar = 2010, val = "KF", efter_omval = TRUE)` and
`mandat(ar = 2011, val = "KF", valklass = "omval")`.
Selector aliases `ordinarie`/`omval`/`alla` are accepted; output values do not
change with the output-name language. Standard is a projection of full and keeps
all event/component provenance fields. Existing ordinary schemas are unchanged.

## Preserved local sources

`data_dir` can be the archive root containing `omval/2011`, `omval/2015` and
`omval/2019`, or the `omval` directory itself. Existing `valres/` (2011) and
`valmyndigheten/` (2015) subdirectories are recognised. For an original-election
composition, the root may also contain the existing `rkl/` ordinary-year archive.
Original-year source semantics are delegated to their existing readers.

- 2011: final `slutlig2011_{vg,orebro}_jmf2010_antal.skv` and
  `slutlig2011_{vg,orebro}_jmf2010_mandat.skv`; RF geography additionally uses
  `rostberattigade_vg.skv` to establish source-supported constituency membership.
- 2015/2019: original `slutresultat.zip`, restricted to the actual rerun municipality.
  Out-of-event placeholders and invalid national electorates are never used.
- 2003: preserved original rerun `slutresultat_2034K.xml`, not ordinary Orsa 2002.

An explicit location can be supplied without renaming or copying original files:

```r
options(swelections.re_election_sources = list(
  `SE-KF-2003-03-16-2034` = list(
    final = "path/to/preserved-rerun.xml",
    seats = "path/to/preserved-rerun.xml"
  )
))
```

Reviewed SHA256 values are pinned in the event registry. Every event output
contains `source_file`, `source_sha256`, `source_url`, `protocol_reference`,
`event_scope_*`, the original-event link, mandate period and roll reference date.
Composition rows identify the original source event and geographic component;
replacement rows additionally retain the exact rerun file/hash. Unknown original
file-level provenance is not fabricated; the component event identifies the
existing ordinary source product.

`source = "auto"` uses the configured preserved local rerun inputs. Explicit
`remote` and `canonical` rerun requests fail: no verified remote downloader or
published canonical rerun release is supplied. `update`/`archive` are rejected
for immutable rerun sources. No canonical assets or source files are rebuilt.
Parquet round-trip validation covers the new output schemas locally.

## Supported final levels and explicit gaps

- Orsa/Båstad/Falun: municipality and ordinary/collection district results;
  municipality mandates. Their technical whole-municipality `00` constituency
  is not exposed as a real municipal constituency.
- Örebro Nordöstra: district, municipality (explicitly partial scope), municipal
  constituency results; event mandates total 17 at either supported parent view.
- Västra Götaland: district, municipality, regional constituency and region
  results; regional constituency and regional mandates. No national placeholder
  electorate is used. 2011 SKV `OG` means other invalid, excluding blank ballots.

No preliminary reader is enabled. Falun's preliminary pages were recovered, but
empty-category semantics and the adapter require their own validation; final
collection values are never substituted. Unknown eligible-voter values on
collection units remain missing. Electoral-roll dates belong to each poll, not
the original event; no cross-date electorate/turnout composite is constructed.

The reference-date metadata uses the event-specific 30-day register basis in
[1997:157, Chapter 7 section 4](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/vallag-1997157_sfs-1997-157/)
and [2005:837, Chapter 5 section 1](https://data.riksdagen.se/dokument/sfs-2005-837.html).
SCB also describes the new rolls for the 2003/2011 reruns in
[Valdeltagande vid omvalen 2011](https://www.scb.se/contentassets/9f23fe2e182a4a2d8961949f81473bc6/me0105_2011a01_br_me09br1201.pdf).
The reference date is not a claim that later authorised roll corrections are absent.

Orsa's eight signed protocol attachments remain unrecovered. Its allocations
use the separately labelled original rerun XML and the already reconciled
historical presentation; the missing legal attachments remain an explicit
provenance gap. The other four cases use the preserved complete decision
protocols/comparison files described in the inventory.

The six Båstad result-only candidate IDs remain source observations. Candidate
readers/IDs/names are unchanged by this implementation. No candidate population
is filtered through a ballot-file inner join. Re-election support for candidate
functions is a separate reader task; the event registry is not a claim that
those functions already accept rerun years. Historical ballot/registered-name
questions remain open. No physical-person or mandate-membership linkage is made.

For the 2011 comparison-table readers, party abbreviations are the reported
identifiers. The documented lookup
`inst/extdata/re-election-party-identifiers-2011.csv` supplies eight official
party IDs and labels from the preserved Valmyndigheten ballot-page anchors
(source URL and SHA256 included). Other unsupported identifiers remain missing;
no candidate or physical-person linkage is inferred. Unknown unfilled-seat counts
also remain missing. `source_url` identifies the verified source catalogue (or
Orsa's exact archived object); it is not an invented download URL for a local ZIP
whose original retrieval receipt has not been established.

Validation commands, results, exact schema additions and changed files are in
[VALIDATION_OMVAL.md](VALIDATION_OMVAL.md).
