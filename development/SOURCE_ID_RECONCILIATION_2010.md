# Approved 2010 candidate-ID harmonisation

The fixed election result uses the final XML as its identity baseline, subject
only to the approved scoped rules below. One canonical identity is used for the
same candidate within the 19 September 2010 election occasion across RD/RF/KF.
This is not a claim that candidate numbers identify people across election years.
Raw files remain unchanged and source identifiers are retained as provenance.

## Björn Andersson: approved scope

Canonical ID is **442089**. RD/KF final XML uses that ID; RF final XML uses raw
**451964**. RF ballot evidence uses 442089, with matching party, geography, list
and position. The approved in-memory RF adapter requires election date 20100919,
final Landstingsval reporting, FP party and constituency 0303. List records also
require list 0003-03159 and position 6. A conflicting context or identity collision
raises an error rather than widening the rule.

| Election | Ballot ID | Raw final XML ID | Canonical ID | Geography | List / position | Area preference votes |
|---|---|---|---|---|---|---:|
| RD | 497359 | 442089 | 442089 | Uppsala constituency 03 | 0003-03600 / 22 | 10 |
| RF | 442089 | 451964 | 442089 | Uppsala läns norra 0303 | 0003-03159 / 6 | 8 |
| KF | 442089 | 442089 | 442089 | Tierp 036000 | 0003-03118 / 1 | 25 |

The implemented RD ballot linkage additionally requires raw candidate 497359,
party 0003, constituency 03, list suffix 03600 and position 22. It resolves that
specific ballot record to 442089; it is not a global replacement of 497359.
The RF rule is likewise not a global numeric replacement or an official correction
notice. These are explicit approved package harmonisation rules supported by
structural source evidence, not joins inferred from names alone.

## Source boundary, provenance and validation

`R/candidate_identity_2010.R` copies the parsed XML before applying the RF rule
and returns file/XPath/raw-ID/canonical-ID provenance. `R/xml_2010.R` applies it
before joins/aggregation and performs the scoped RD ballot linkage. Candidate
votes, list positions and election-result relationships are not changed.
Later mandate-period membership does not redefine the fixed election population.

The preserved final ZIP has MD5 `e758499f800cfbc49ce02c54c3d1dd79` and SHA256
`2d598343995a387a8cd1e57520d5d39e1dd2b767ec6b837ef59f50a85485bc7b`.
The original RF audit found exactly 16 changed ID attributes, all `PERSONVAL`:
2 in `slutresultat_00L.xml`, 12 in `slutresultat_0360L.xml` and 2 in
`slutresultat_0382L.xml`. Reversing only those IDs reproduces each input XML.
Area and district/list copies are not summed together. RF 451964 is not retained
as a second canonical candidate.

`tests/testthat/test-candidate-identity-2010.R` contains deterministic and opt-in
source regressions; the latter uses `SWELECTIONS_2010_IDENTITY_ZIP`.
See [IMPLEMENTATION_2010_VALIDATION.md](IMPLEMENTATION_2010_VALIDATION.md) for
full reader and candidate-population validation.

## Unresolved cases

Other source-ID discrepancies and seven weaker identity cases remain unresolved
and unharmonised. The detailed proposed crosswalk and named hypotheses are local
research evidence, not active package mappings or public canonical assets.
No additional rule is authorised by this document. Future linkage requires
separate source evidence and review; raw source IDs must not be overwritten.
