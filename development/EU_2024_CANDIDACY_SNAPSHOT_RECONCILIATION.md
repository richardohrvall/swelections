# EU 2024: candidacy snapshot reconciliation

Investigation date: 2026-10-15. No production, API, canonical or original-source
changes; no commit or push. This supplements
[SOURCE_INVENTORY_EU_2024.md](SOURCE_INVENTORY_EU_2024.md).

## Approved implementation decision

Use the later 11 June/December snapshot for the final candidacy/candidate
population. Preserve the recovered 9 June record and its provenance unchanged,
but do not add candidate 1203 to the final population. The disappearance is an
accepted source/version discrepancy; its unknown administrative reason does
not block implementation or require further source recovery. Final candidacy
coverage: **COMPLETE WITH SPECIFIED EXCEPTIONS**, with candidate 1203 the sole
documented historical snapshot exception. No preference/elected/substitute
record is identified for him, and no party-result or mandate value is affected.
This approved decision supersedes the provisional recommendation at the end
of this investigation.

## Result

**The exact record absent from the later candidate snapshots has been found and
recovered:** candidate **1203**, source name **`Österberg, Felix`**, Folklistan
(**1659**), European Parliament election **E**, national election area/constituency
**00**. The archived election-day file explicitly reports a valid consent-only
candidacy. It is not an irrecoverable missing record.

**Classification: verified source/version difference.** The reason for the later
removal is **NOT VERIFIED**. The available evidence does not establish withdrawal,
ineligibility, a registration correction, or another administrative reason.
A removed row must not be translated into an observed `GILTIG = N` status.

The numerical 1,391-versus-1,390 candidacy difference is reproduced by an actual
one-row change between official snapshots. However, the press announcement's
complete set of numbers is **not fully reconciled**: its 1,340 people is not the
1,341 valid candidate IDs in the recovered election-day CSV. Do not claim that the
recovered CSV is the precise register extract used for the 8 June announcement.

## Recovered source and provenance

- Original official URL:
  <https://data.val.se/filer/euval2024/parti/kandidaturer.zip>
- Archive capture: **2024-06-10 13:38:22 UTC**.
- Exact preserved archive replay:
  <https://web.archive.org/web/20240610133822id_/https://data.val.se/filer/euval2024/parti/kandidaturer.zip>
- ZIP member: `kandidaturer.csv`, **171,969 bytes**, member timestamp
  **2024-06-09 16:39:00** (ZIP timestamp timezone unspecified).
- ZIP: **35,228 bytes**, MD5 `46b44ec73698a6b44d4109cfab3083fd`,
  SHA256 `e408dbdf9b96b1b075b1463d707e11854e415524f1ec88cdf9fbd187ac27b2db`.
- CSV: MD5 `c9715d4b02b2d119113c112f3420454d`,
  SHA256 `c47cd8e967c4dbc72d3fd7293aea1199c103c005729eb1c3cd64a456768c5375`.
- Downloaded ZIP's independently calculated SHA1/base32 equals the archive CDX
  digest **`KCECLYJVPL4OE7DCDEHISMUXER3OBUQP`**.

Preserved locally under
`.local-data/eu/2024/review-20261015/one-row-investigation/`:
`kandidaturer-20240610.zip`, extracted `20240610/kandidaturer.csv`, CDX response,
retrieval/provenance sidecars, `recovered-source-checksums.json`, comparisons and
independent R diagnostic logs. None is added to Git. The retrieved archive ZIP is
a new source, not an overwrite of the 17 pre-existing files.

The narrow CDX query for the exact official ZIP URL returned two distinct 2024
content captures (1 March and 10 June). The 10 June one was recovered successfully.
A separate archive availability request returned HTTP 429; this is an access
failure, not evidence that snapshots do not exist. No 8 June raw register extract
was obtained. The current official candidate-presentation page and its metadata
were inspected; no removal history was recovered from them. The official SCB
candidate statistics explain the eligible/consenting population but do not provide
a candidate-level status history for this record.

## Exact row

| Source field | Archived value |
| --- | --- |
| `VALTYP` | `E` |
| `VALOMRÅDESKOD`, `VALKRETSKOD` | `00`, `00` |
| Area/constituency name | `Riket` |
| `PARTIKOD`, `PARTIBETECKNING` | `1659`, `Folklistan` |
| `PARTIFÖRKORTNING` | `FOLK` |
| `KANDIDATNUMMER` | `1203` |
| `NAMN` | `Österberg, Felix` |
| `SAMTYCKE` | `J` |
| `FÖRKLARING` | `I` |
| `ANMÄLDAKANDIDATER` | `N` |
| `GILTIG` | `J` |
| `VALSEDELSSTATUS`, `LISTNUMMER`, `ORDNING` | Empty |
| Age on election day / sex | `29` / `M` |
| Registered municipality | `Stockholm` |

There is no printed ballot/list number or ballot position to reconstruct for this
consent-only row. Do not assign it to one of Folklistan's printed lists. Do not
infer identity from its name; this comparison uses the official candidate ID and
party/list/position fields, including source-empty list and position.

## Complete snapshot comparison

| Source | All rows | Valid rows | All IDs | Valid IDs | Valid multi-party IDs |
| --- | ---: | ---: | ---: | ---: | ---: |
| Official announcement, 8 June | Not stated | 1,391 announced candidacies | Not stated | 1,340 announced people | 23 |
| Archived CSV, member dated 9 June | 1,396 | 1,391 | 1,345 | 1,341 | 23 |
| Local June ZIP, member dated 11 June | 1,395 | 1,390 | 1,344 | 1,340 | 23 |
| Local December/current official ZIP, member dated 5 December | 1,395 | 1,390 | 1,344 | 1,340 | 23 |

The 9-to-11 June full-key anti-joins identify:

- **One removed key:** party 1659, candidate 1203, empty list and position.
- **Zero added keys.**
- **Zero validity/consent/declaration changes among common keys.** All five
  invalid candidacies remain present and unchanged in those status fields.
- Two name-field changes among common keys, both Folklistan consent-only rows:
  ID 726 `Svan, Konstantin` to `Svan, K E`; ID 775
  `Lundh, Sven Ingmar Gustaf` to `Lundh, Sven`.
- No other common-field differences.

The later June and December snapshots have identical keys and validity flags, as
established in the main inventory. Thus candidate 1203 is also absent in December
and the current official CSV. The recovered row is an additional documented
historical observation, not a parser repair: the existing June CSV has 1,396
physical lines including the header, 1,395 parsed rows and no parsing problems.
Its 1,390 valid rows are not caused by dropping a final non-newline-terminated row.

### An alternative count that must not be mistaken for the explanation

In the later CSV, selecting **all rows belonging to candidate IDs that have at
least one valid candidacy** also gives 1,391 rows. Its single extra row is
candidate 279's invalid SD candidacy (party 0110, list 06247, position 12), while
his Folklistan candidacy is valid. This is Johan Nissinen's source ID, not 1203.

That selection produces **24**, not 23, multi-party IDs. It therefore does not
reproduce all the announcement's statistics and is not evidence of how the
announcement was calculated. The recovered raw snapshot provides a distinct,
actual one-row version change; no Nissinen status change was found between the
9 and 11 June CSVs. Do not change that candidacy to force 1,391 valid rows.

## Effects on final results

Candidate 1203 has:

- **Zero identified records** in the preserved final district preference-vote
  data (the 393,607 positive records), and none in their national counterpart;
- **Zero elected records** and **zero substitute relations** in the final JSON;
- no source list or ballot position.

This does not justify allocating aggregate votes to the recovered candidacy.
It does mean that preserving the row does not require changing any reported party
vote, preference-vote observation, mandate or elected/substitute relation. All
previous aggregate-result conclusions remain unchanged. No production data have
been changed to add or discard this candidacy.

## Optional administrative clarification (not an implementation blocker)

The evidence establishes a source/version difference and recovers the full row.
It does **not** establish whether its removal was a correction of election-day
eligibility, a later withdrawal, or another event. Nor does it establish why the
announcement reported 1,340 people together with 1,391 candidacies.

The specific authoritative evidence still needed is either:

1. Valmyndigheten's candidate-register change/consent record for **E 2024,
   candidate 1203, Folklistan 1659**, explaining removal between the represented
   9 and 11 June exports and its effective date; or
2. the exact raw register extract and counting definition used for the
   **8 June 2024 announcement**, including candidate IDs.

Suggested factual question to Valmyndigheten:

> The official CSV generated 9 June 2024 at 16:39 contains candidate 1203,
> `Österberg, Felix`, Folklistan 1659, `SAMTYCKE=J`, `GILTIG=J`, without a
> printed list. The 11 June export omits the row entirely. What caused its
> removal, and was the candidacy valid for the 9 June election? Which counting
> definition/source extract produced the announcement's 1,391 candidacies and
> 1,340 people?

**Approved implementation rule:** use the later 11 June/December population.
The recovered candidate 1203 row and its checksums remain historical provenance
only; the row is not added to final candidacies/candidates. Coverage is COMPLETE
WITH SPECIFIED EXCEPTIONS, with this precisely identified snapshot exception.
The removal reason remains unestablished, but neither clarification nor further
source recovery is required before implementation. Final party votes, reported
preference votes, mandates, elected persons and substitutes are unaffected.
