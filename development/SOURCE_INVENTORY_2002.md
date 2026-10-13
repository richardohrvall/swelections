# 2002 source inventory and feasibility assessment

Reviewed 2026-10-12, against commit `bf975682214d967cadb9a79b9915da61901efc30`.
This is a source review, not a production implementation or canonical build.
Valmyndigheten is primary; SCB and SND are independent publication/reference
controls, not substitutes for missing individual Valmyndigheten records.

**Orsa follow-up:** the focused investigation below recovered both the original
2002 and rerun 2003 official XML through archived Valmyndigheten URLs. The
original Orsa final result is now reproducible, including districts, allocated
mandates and elected/substitute records. This supersedes the earlier Orsa gap,
but does not establish complete national XML or candidate coverage. See section 13.
The final targeted follow-up also recovered original Orsa election-night
HTML/text/XML (section 14). Full preliminary collection coverage remains unproven.

## Executive assessment

Final RD/RF/KF party results and allocated mandates are accessible in the
historical **HTML and fixed-width text** presentation under `val/val_02/`.
It is not the 2006 XML structure. Following all final county indexes establishes
29 RD constituency links, 100 RF constituency links and 290 KF municipality
links. This proves index coverage, not that every underlying district or
candidate page is complete.

Area/list and sampled district preference-vote pages, elected slots and
substitutes are accessible, but names have been replaced by
`Personuppgift borttagen`. No public stable candidate/person identifier was
found. The displayed preference-vote `Nr` is a ranking with ties, not a
candidate ID or a reliably identified ballot position. A complete ballot
candidacy population has not been recovered.

The current KF presentation incorporates **Orsa's 16 March 2003 rerun**, even
inside the `valnatt` tree. It cannot be treated indiscriminately as the fixed
15 September 2002 election. No complete preliminary collection snapshot was
recovered. Final collection values must never fill that gap.

A results/seats implementation is feasible after source preservation and
resolution of the Orsa election-occasion boundary. Anonymous result-observation
views are probably feasible with explicit identity limitations. A complete
seven-function canonical release is **not ready** on the evidence collected.

## 1. Local collection

Eleven original files were inspected, including every member of the three SND
ZIPs. `kandidater/` and `rostning/` have no files. No local 2002 result XML,
ballot ZIP, original elected/member file or preliminary collection snapshot
was found. Project-wide year/path searches found the SCB files listed below,
not a second preserved 2002 primary archive.

| File under `.local-data/rkl/2002/` | Bytes | Contents and role |
| --- | ---: | --- |
| scb/valres_parti_valdistr2002_ri.dta | 37,361,804 | 184,917 rows, 12 columns; RD district x party votes; 290 municipality codes, 82 party codes |
| scb/valres_parti_valdistr2002_lt.dta | 17,193,178 | 104,792 rows, 10 columns; RF district x party votes; 289 municipality codes, 60 party codes |
| scb/valres_parti_valdistr2002_ko.dta | 13,740,870 | 81,260 rows, 11 columns; KF district x party votes; 290 municipality codes, 217 party codes |
| scb/val02_nom.dta | 15,570 | 290 rows, three columns: llkk, sd_vals0 (label sd_vals02), kommunna. An SD ballot/municipality indicator, **not nominated-candidate microdata** |
| scb/val02_dist.dta | 125,604 | Legacy binary; header declares four variables and 6,266 records. Visible variable names include llkkdddd, llkk, sd_ko02, sd_ri02. Ordinary readers reject the format; values were not decoded |
| scb/val02_mandat.dta | 556 | Legacy binary; header declares two variables and 49 records; visible names llkk and sd_mand0, label sd_mand02. Not a complete national mandate table; values not decoded |
| snd/snd0237-10-3.zip | 4,136,329 | RD SND dataset 0237-010, version 2.1; eight members, including paired SV/EN SAV, XLSX and PDF plus variable crosswalk and member checksums |
| snd/snd0238-9-3.zip | 4,607,787 | RF SND dataset 0238-009, version 2.0; eight analogous members |
| snd/snd0239-9-3.zip | 4,164,488 | KF SND dataset 0239-009, version 2.0; eight analogous members |
| valresultat/kommun_bestallda_valsedlar_SD_2002.txt | 3,724 | Preserved SD ballot-order municipality text; supplementary ballot context, not a candidate roster or vote source |
| valresultat/tillagg_ovriga.pdf | 45,650 | Valmyndigheten's RD other-party correction/supplement; see section 4 |

The modern DTA files have municipality/district codes, party codes/names and
vote counts, including invalid category 9999. Their district x party keys are
unique. Unique raw district-code counts are RD 6,266 / RF 6,226 / KF 6,266;
these are **not interchangeable** with the website's counting-unit totals.

The two unreadable binaries begin with format byte 0x67. Both `haven` and
`foreign` reject them. Header/ASCII inspection is descriptive only, not a
validated conversion. No bytes were changed. Their SD-specific fields and
small mandate-file population make them supplementary research extracts,
not canonical national inputs.

Filesystem dates range from 2008 to 2026 and do not establish source capture
or publication dates. The SND ZIP member dates of 2026-10-11 describe packaging,
not the 2002 election or an original snapshot. All 21 data/documentation member
SHA256 values in the three ZIP checksum lists were verified. The original
11 files retain their initial sizes, MD5 and SHA256.

## 2. Official web sources and coverage

The current [Valmyndigheten raw-data guide](https://www.val.se/valresultat-och-statistik/statistik-och-data/radata-fran-val-2002-2022)
explicitly links 2002 to its text-format presentation. The initially tested
`val2002/` paths return 404; they are not evidence that 2002 results are absent.
The correct namespace is `val_02/`.

| Source | URL or actual linked pattern | Content/coverage |
| --- | --- | --- |
| Final RD national HTML/text | https://historik.val.se/val/val_02/slutresultat/00R/00.html and 00-text.html | Party counts, other parties, OG, turnout, mandates M(U), changes from previous election, counted-unit status; text traverses county/municipality aggregates |
| Final RF national HTML/text | https://historik.val.se/val/val_02/slutresultat/00L/00.html and 00-text.html | Analogous national/region/municipality aggregates; 20 regions, excluding Gotland RF |
| Final KF national HTML/text | https://historik.val.se/val/val_02/slutresultat/00K/00.html and 00-text.html | Includes Orsa rerun; root report time 2003-03-20 10:49:22 |
| Election-night HTML/text | Same 00R/00L/00K paths under valnatt instead of slutresultat | Distinct count stage; KF root is updated 2003-03-16 22:44:00, not a pristine 2002 night snapshot |
| County indexes | slutresultat/LLR/LL.html, LLL/LL.html, LLK/LL.html | All linked indexes retrieved: RD 21/21, RF 20/20, KF 21/21 |
| RD constituency | https://historik.val.se/val/val_02/slutresultat/07R/0707KR.html | 29 links nationally; municipal children, party/list totals, preference vote links, elected/substitute sections |
| RF constituency | https://historik.val.se/val/val_02/slutresultat/01L/0110KL.html | Nordost example; 100 distinct constituency links nationally |
| KF municipality | https://historik.val.se/val/val_02/slutresultat/20K/2034/2034.html | Orsa rerun example; 290 municipality links derived through all 29 intermediate KF geographic indexes |
| KF municipal constituency | https://historik.val.se/val/val_02/slutresultat/01K/0163/016301.html | Sollentuna First; allocated seats, party/list votes, elected/substitute sections |
| Ordinary district | https://historik.val.se/val/val_02/slutresultat/01K/0163/01630151.html | Party/list counts and linked anonymous person-vote data; an inspected example, not a national district sweep |
| Collection district | https://historik.val.se/val/val_02/slutresultat/01K/0163/K-0163-01.html | I vallokal ej räknade röster; final collection values, not preliminary values |
| Candidate totals | 0707KR-totalt.html, 0110KL-totalt.html, 016301-totalt.html beneath the corresponding area directory | Per-party anonymous candidate-result rows, rank, preference votes/share, qualification where shown |
| Candidate list views | Corresponding -lista.html pages | Party code + five-digit list number, anonymous rows, rank, list-relative share |
| District candidate view | K-0163-01-totalt.html / 01630151-totalt.html in the sampled KF directory | Candidate-result observations also exist at district scope; no identity linkage to area rows was established |

The final national counted-unit totals are RD 6,266 / RF 6,233 / KF 6,372.
All indexes above were inspected rather than inferred from filenames. Only
selected deeper district/list/candidate pages were retrieved. Full national
candidate, district, elected and substitute completeness remains unverified.

The inspected sources combine invalid votes as **OG**. No reliable separate
blank/other-invalid breakdown or exact eligible-voter count for every primary
HTML unit was established. Displayed turnout and shares are source percentages;
do not reconstruct exact counts from rounded/truncated display values.

The tested XML index `val_02/slutresultat/xml/index.html`, ballot index
`val_02/valsedlar/index.html` and statistics index `val_02/statistik/index.html`
return 404. No JSON/XML/ZIP export was found through current links. This is not
proof that an older raw export never existed.

## 3. Archives: findings and limits

Three targeted Wayback availability requests for the original `www.val.se`
2002 final constituency, landing and night-national URLs returned HTTP 429.
After other work/backoff, one bounded CDX query for `www.val.se/val/val_02/*`
returned HTTP 503. No aggressive retry, parallel crawl or guessed capture date
was used. An exhaustive Wayback inventory therefore could not be completed.

Arquivo.pt's version-history API returned ten capture metadata entries for
`http(s)://www.val.se/val/val_02/slutresultat/00R/00.html`, dated 2019-05-23
through 2024-06-19. Two actual replay URLs were retrieved, including:

- https://arquivo.pt/wayback/20190523061257/http://www.val.se/val/val_02/slutresultat/00R/00.html
- https://arquivo.pt/wayback/20240619073010/https://www.val.se/val/val_02/slutresultat/00R/00.html

These responses are **archive UI wrappers**, not verified election content.
Following the underlying replay/no-frame/raw-content routes returned 404.
A separate history lookup for the Kronoberg list-person page returned zero
entries. Metadata capture existence is not evidence of a recovered ballot,
named candidate page, original Orsa result or preliminary collection dataset.
Archive metadata and retrieved wrappers are preserved and classified separately.

No new readable named candidate source, mandate-period event file or complete
preliminary collection source was recovered. This is a bounded access/search
limitation, not a claim that no captures or original files exist anywhere.

## 4. Smaller parties and the official RD supplement

Current pages expose major parties, selected other parties and a residual
other-party category. List identifiers encode the numeric party code, e.g.
`0001-00197`; source party definitions should be retained rather than inferred
from an abbreviation alone.

The preserved `tillagg_ovriga.pdf` explicitly explains a technical failure to
separately show four parties in the original final presentation. It supplies
29-constituency rows and reported national totals:

| Party | Reported total |
| --- | ---: |
| Fria Listan | 502 |
| Nationaldemokraterna | 9,248 |
| Ny Demokrati | 2,207 |
| Populistpartiet | 11 |

It explicitly distinguishes blank (not reported, possible votes remain within
other parties) from zero (no votes reported for the party). The supplement is
an allocation **within** other-party votes, not additional ballots. Some
party/constituency cells remain missing; do not allocate them or extrapolate
these rows to municipalities/districts. No original download URL or dated
version metadata for this local PDF has been established. Its producer text
and exact checksum are evidence; the local filename/date are not full provenance.

## 5. Candidate identity and population

| Concept | Public 2002 evidence | Assessment |
| --- | --- | --- |
| Name | Personuppgift borttagen in inspected candidate/elected/substitute rows | Public name is missing; archived named evidence not recovered |
| Party | Designation/abbreviation, numeric code in list identifier | Useful source scope; use official definitions |
| Election and geography | Directory, breadcrumb, title and linked area code | Recoverable observations; not cross-election person identity |
| List number | E.g. 0001-00197; technical 90000 also occurs | List identity, not person identity or proof of a printed-name ballot |
| Nr on preference page | Equal counts share ranks, e.g. two rank-5 rows with 87 votes in Kronoberg C | Ranking, **not list position/candidate identifier**; tied anonymous rows must not be deduplicated |
| Preference votes | Explicit candidate row counts and displayed shares | Preserve observed rows; missing candidate row cannot safely mean zero |
| Qualification | Over spärr label in total-area view | Source status at that area; do not propagate across levels |
| Elected/substitute status/order | Separate Vald/Valda and Ersättare tables with order and age | Source-slot relations are visible; links to person-vote rows are not verified |
| Stable candidate/person ID | None found in sampled public HTML fields/attributes or local sources | Do not manufacture a person ID or name-based cross-list/RD/RF/KF join |
| Full ballot population / true list position / validity / consent | No recovered ballot-candidacy register | Cannot infer from positive vote rows or list labels |

`90000` has list/party votes but blank personal-vote fields in inspected
examples. That is not sufficient evidence to generalise complete-zero rules
nationally. Preserve blank separately from explicit zero. The presence of a
result list does not establish ordered/printed-name-ballot status.

A future generated **source-row key**, if approved, could identify one HTML
row/slot together with source URL, election, area, party and list role. It
would not identify a person. No keys were created in this review. Cross-area
candidate totals, matching elected rows to person-vote rows and linking across
RD/RF/KF must remain unsupported without additional evidence.

### Important positive evidence from SCB documentation

[SCBDOK ME0104 for 2002](https://www.scb.se/contentassets/0306ea5d06f34dfab00ef2ca653a5284/me0104_do_2002.pdf),
whose internal document footer is dated 2007-01-09, documents underlying
nominee/elected records with `personnr`, `listnr`, true ballot position
`nrinom`, names, party/geography and `antpersrost`. It attributes these to
Valmyndigheten. Thus lack of a public ID is **not proof that the underlying
2002 administration had no person identifiers**.

The documented nominee-file row counts are RF 48,279 and KF 83,451 before /
83,466 after Orsa's rerun, explicitly allowing several rows per person.
These are metadata counts, not candidate records available here. Elected-file
metadata also permits several constituency records per person; do not equate
raw file-row totals with allocated mandates or unique elected people.
SCB's controlled research material may warrant an enquiry, but is not an open
candidate-ID lookup and is not authorised as canonical individual input here.

## 6. Counting stages and preliminary gap

| Current presentation | RD | RF | KF |
| --- | ---: | ---: | ---: |
| Night reported units | 5,976 | 5,937 | 5,976 |
| Final reported units | 6,266 | 6,233 | 6,372 |

`valnatt` and `slutresultat` differ. Final collection pages are accessible;
the sampled same-code `valnatt/.../K-0163-01.html` returns 404. No third complete
preliminary/Wednesday tree or export was recovered from current links or the
bounded archive investigation. The difference between night/final unit counts
is not a proof of a retrievable preliminary collection population.

Consequently there is no validated construction of
`night ordinary districts + preliminary collection = full preliminary`.
Missing pages cannot be identified as numeric zero; an exact list of missing
preliminary units/categories cannot be established without the source's own
expected geography/index. Final values must not be substituted.

KF night's 2003 root timestamp and Orsa rerun contamination make its current
snapshot unsuitable as an unqualified ordinary-2002 election-night baseline.
Do not introduce a public election_night stage or silently call it preliminary.
Keep original night, full preliminary and final concepts separate in provenance.

## 7. Mandates and election-result relationships

Current national party allocation totals are RD **349**, RF **1,656**, KF
**13,274**. KF includes the current Orsa rerun result. The SCB PxWeb KF mandate
extract independently agrees with 13,274, and splits SD 49 / other 562 where
the national Valmyndigheten summary groups them as other 611.

Primary constituency pages include original elected/substitute table sections,
separate orders and age. Their anonymity does not establish that every allocated
seat is filled. No nationally verified unfilled-slot count or exhaustive
placeholder classification has been obtained. Do not import 2006's 14 unfilled
seats or infer `unfilled_seats = 0` from missing evidence.

A future implementation must compare allocated seats with the **original**
filled/explicitly-unfilled slots, preserving substitute group scope. A party-wide
substitute list is not automatically a proven member-to-substitute cross-product.
No current/departed membership or mandate-period change export was recovered;
it must never replace fixed election relationships if later found.

## 8. Independent validation and reconciliation

| Control | RD | RF | KF, current post-Orsa source |
| --- | ---: | ---: | ---: |
| Valid votes, VM/local SCB | 5,303,212 | 5,227,376 | 5,313,271 |
| Invalid votes, combined OG | 82,218 | 116,585 | 96,830 |
| Total ballots | 5,385,430 | 5,343,961 | 5,410,101 |
| Allocated mandates | 349 | 1,656 | 13,274 |
| SCB PxWeb preference-vote total | 1,380,864 | 1,325,189 | 1,660,350 |

All seven major-party national counts agree between Valmyndigheten and the
local SCB long extracts for each election. The three national valid/invalid/
total controls also agree. The KF live PxWeb counts and mandates provide a
second reproducible publication-level cross-check. Preference totals are
SCB table controls; they have **not** been reconciled with all candidate pages,
and party inclusion/nominee coverage must be checked before treating them as
candidate-population completeness evidence.

SND is a documented research distribution, not primary Valmyndigheten raw data.
Its RD/RF vote sums agree with the national controls. For KF, sums are 5,312,977
valid and 5,409,855 total; every municipality's total agrees with local SCB
except Orsa. SND Orsa has 4,070 total / 4,009 valid votes; current SCB has
4,316 total / 4,303 valid. The difference is +246 total / +294 valid / -48
invalid, explained by ordinary 2002 versus 2003 rerun. Do not force agreement.

SND RD eligible-voter sum is 6,722,163 with three missing `tot` cells, versus
Valmyndigheten's published national control 6,722,176. The 13-person residual
must not be distributed to missing cells without their primary records.
RF SND has 6,233 rows, KF 6,372. Postal pseudo-codes are reused across source
areas and constituencies. KF needs municipality/constituency context; RF also
needs county/context (some postal rows use llkk=9999 or 999999). Whole-row
RF duplicates are zero; full contextual keys are unique. Raw district code
alone is not a deduplication key. The local SCB long table's unique raw code
count is not an independently verified count of all website reporting units.

### Reconciliation classification

| Issue | Classification / next action |
| --- | --- |
| National major-party/valid/invalid/total counts | Resolved: equal within the current presentation's election-occasion scope |
| KF SND versus current SCB/VM | Explained snapshot/election-occasion difference, confined to Orsa |
| SND postal-code repetition | Explained source-geography structure; retain full context, do not remove rows |
| RD SND eligible residual 13 and three missing cells | Unresolved reference missingness; retrieve original eligible records |
| Candidate person IDs absent publicly | Confirmed public-source limitation; underlying IDs documented, access/linkage unresolved |
| Blank versus other-invalid votes | No verified separate primary breakdown; preserve missingness |
| Full preliminary collection data | Unrecovered; no complete expected-unit reconciliation possible |
| Original Orsa elected/substitute/ordinary result | Resolved by archived official XML in section 13; election occasions must remain separate |

## 9. SCB sources and reproducible access

**SCB Statistics Database does not provide voting-district-level election
results in these public result tables.** The preserved district extracts,
SND distributions and historical publications are separate sources. SCBDOK's
internal district tables do not imply public PxWeb district access.

The following v1 metadata endpoints were inspected under
`https://api.scb.se/OV0104/v1/doris/sv/ssd/START/ME/ME0104/`:

- `ME0104C/ME0104T3`: RD votes; municipality/constituency aggregation;
- `ME0104B/ME0104T2`: RF votes; municipality/region aggregation;
- `ME0104A/ME0104T1`: KF votes; municipality/national aggregation;
- `ME0104A/Kfmandat`: KF mandates;
- `ME0104C/ME0104T24`, `ME0104B/ME0104T26`, `ME0104A/ME0104T25`:
  preference totals by constituency/region/municipality, party and sex;
- category indexes also expose `Riksdagsmandat`, `Ltmandat`, eligible-voter
  tables and separate demographic turnout-survey tables.

Tiny POST extracts used `filter=item`, year 2002, the explicit national code,
count contents and, for preference totals, party TOTALT and sex 1+2. Exact
requests, response bytes, timestamps and hashes are preserved locally. Their
contents codes include RD ME0104AV, RF ME0104AT and KF ME0104AX for preference
counts. Turnout sample-survey estimates are not a replacement for total-count
ballot/eligible controls.

The documentation describes *Allmänna valen 2002*, parts 1 RD / 2 RF / 3 KF,
with district tables, mandates, preference aggregates and separate Orsa tables.
[SCB's KF results footnote](https://www.statistikdatabasen.scb.se/pxweb/sv/ssd/START__ME__ME0104__ME0104A/ME0104T1/)
explicitly says current 2002 data include the 2003 Orsa rerun and directs users
to part 3 for the ordinary result. The publication/reference should be preserved
before using it to validate original 2002 KF. Nominee statistics are aggregate
validation and not a source for inventing individuals.

## 10. Comparison with 2006 and function coverage

| Feature | 2002 | Established 2006 approach |
| --- | --- | --- |
| Primary read layer | HTML tables / fixed-width text; no XML export recovered | XML plus supplementary HTML |
| Result harmonisation | Counts/party/area concepts reusable after a new reader | Existing XML normalisation |
| Candidate person ID | Not public; internal SCB person IDs documented | No verified public person ID |
| Ballot candidacies | Complete source not recovered; displayed Nr is rank | Preserved ballot ZIP gives positions/source observations |
| Candidate names | Public rows redacted; named archive not recovered | Approved archived named evidence available |
| Area/list/district person votes | Anonymous source-row views present in inspected examples | Scoped source-row keys, no name linkage |
| Preliminary | No complete collection source; KF night also contains rerun | No complete collection source |
| Elected/substitute relations | HTML sections; full linkage/unfilled controls pending | Original XML slot/group relations validated |
| Other parties | Separate presentation plus partial official PDF supplement | XML other-party partition plus supplements |
| Election occasion | Orsa 2003 embedded; must separate | No comparable rerun in the 2006 occasion |

| Public function | RD | RF | KF | Feasibility / missing evidence |
| --- | --- | --- | --- | --- |
| results() | Feasible final | Feasible final | Feasible final with Orsa separation | New HTML/text read adapter; full district crawl/keys/other-party partition validation required; unsupported categories remain NA |
| seats() | Feasible allocation | Feasible allocation | Feasible allocation with Orsa separation | Preserve M(U); filled/unfilled distinctions need original slot census |
| candidacies() | Defer full population | Defer full population | Defer full population | Need ballot register with true positions; positive-vote rows do not enumerate all ballot candidates |
| candidates() | Conditional source-observation view | Conditional | Conditional | No verified person-level joining; keep documented result/elected/substitute rows as separate evidence, pending population design |
| elected() | Conditional source-slot view | Conditional | Conditional, original Orsa recovered in section 13 | Full constituency crawl, count/order/empty-slot controls and original election scope needed |
| substitutes() | Conditional relation view | Conditional | Conditional, original Orsa recovered in section 13 | Must verify group/member relationship; no guessed linkage by redacted name or rank |
| preference_votes() | Conditional source-row view | Conditional | Conditional with Orsa separation | Area/list and district examples exist; no cross-area person totals or synthetic zeros; full smaller-party coverage unverified |

These recommendations do not add support or change any package API. Reuse
English/Swedish projection, count/share semantics and manifest infrastructure
only after a genuinely 2002-specific HTML/text reader has been validated. Do
not wrap 2002 HTML as if it were 2006 XML. No generated person identifiers or
canonical assets were created.

## 11. Preservation and questions for Valmyndigheten

Preserve all existing local files as research/reference snapshots. Acquire
complete official final district/constituency/list pages from their discovered
indexes into an immutable manifest-backed collection if implementation is
approved. Keep current and original-Orsa generations separate. Retain the
PDF other-party supplement and its blank/zero definition. Preserve original
and rerun Orsa protocols/exports as different election occasions.

Questions to combine with the 2006 enquiries:

1. Can Valmyndigheten provide original 2002 ballot/candidate exports with true
   list position, stable candidate/person key, validity and original names?
   Which documented SCB person/list fields originated from those exports, and
   can a publishable scoped identifier/crosswalk be supplied?
2. Is a complete preliminary collection/Wednesday snapshot or original export
   retained? What was its URL, expected reporting-unit population and timestamp?
3. Can the ordinary 15 September 2002 Orsa party, candidate, elected and
   substitute records be supplied separately from the 16 March 2003 rerun?
4. Which original appointed slots were unfilled, and how did the original 2002
   presentation encode them? Did anonymisation preserve the distinction?
5. What are the exact member/substitute-group and election-basis semantics in
   the 2002 HTML, and are original files separate from mandate-period events?
6. Do missing candidate rows mean zero only under a documented complete ballot
   population? Can smaller/other-party candidate totals and lists be enumerated?
7. Are separate blank/invalid categories and exact eligible-voter counts retained
   at district level? Are there further raw, membership/departure/replacement
   files that were once public but are no longer linked?

## 12. Implementation readiness

**Recommended sequence: results/seats first, using the recovered original Orsa snapshot (section 13);
source-observation candidate/preference views only after additional coverage
and relationship checks. Defer verified person-level linkage and full ballot
candidacies.**

A full canonical build should wait for: a complete primary-result preservation sweep; candidate/list
population rules; filled/unfilled and substitute-scope validation; and explicit
acceptance of unavailable fields. Preliminary support remains deferred unless
a genuinely preliminary collection source is recovered. Current findings are
not sufficient to claim complete national candidate microdata.

No production code, tests, canonical schemas, existing historical assets or
original source files were modified. No commit, push or release was made.

## Appendix: source integrity and preservation

The review collection has 138 preserved objects and 152 recorded HTTP/API attempts. All recorded object sizes, MD5 and SHA256 are verified. Archive wrappers/metadata are not recovered candidate data.
The acquisition used bounded sequential 35-second requests, cached successful responses and new files. Existing raw sources were not overwritten. Small primary indexes/samples and the 2.1 MB SCB documentation PDF were preserved; no national district/candidate crawl was performed.
Complete original/effective URLs, UTC retrieval times, statuses, sizes and hashes, plus exact SCB POST requests, are in the **local, untracked** `source-review-20261012/source-manifest.json` under the 2002 archive.
Manifest SHA256: `d7794f89e1a2126c0a1f94b8030efe0d6133cfbe4d284164be1b6279bfea8b9f`.
`initial-provenance.json` separately records the initial guide/namespace probes; `discovered-geography.json` records actual linked geographic units. Archive capture dates, current retrieval times and source report dates remain distinct.

| Original source | MD5 | SHA256 |
| --- | --- | --- |
| scb/val02_dist.dta | f14479815b68a2e1f339591765d410ce | e76b7a0bc75d71d0b5001b0725aa35ae8b672ed1a49572a0159a7a88e2576941 |
| scb/val02_mandat.dta | 5acf611b9641c90089e5a3e4a0994b84 | 5e285e72669720b8df7f2fd6d6e7880a3a66ce6e8b1c9d2bfb73dd403b37a836 |
| scb/val02_nom.dta | eea1232c2fbb19eefc7d613ce3cd32a6 | 7df9671c1e1f081e6ae85e1e80410cc4ebacbcd88f1acb5821e1fb8a39e62cd9 |
| scb/valres_parti_valdistr2002_ko.dta | ae299b60b2d9cae25aab86e138368e47 | 46703299c0e6a8e4eeaecd413d690abd217fdd36920cc030643f05a02aeccfd6 |
| scb/valres_parti_valdistr2002_lt.dta | f1ccf11f0e50c8aeef687a4268f20d6d | bd45d1fdcf4ae1b878d5eb6fb27925e97a165d21c38d440936f066a8fa1ef0ce |
| scb/valres_parti_valdistr2002_ri.dta | 4d914f7a4b6ed159dc0736df8b94be27 | e834e5de6a9befe93be2183ca05f991c5758c8832b1de56b1031a5fc2365f730 |
| snd/snd0237-10-3.zip | ac27fa12700498899791abb58290596f | 47a4b1288efa238d5bc90149ff8d9e387d504484a0da37ada78f2b1e84b607d6 |
| snd/snd0238-9-3.zip | deaac1e0491592f96a51192b4d80c47b | 305168b076351e1605e555ac74399f34a3c071f3431c94336254b5bdc2fa88bc |
| snd/snd0239-9-3.zip | a6afa695d49eb3bf05c733a10bc5ba19 | f880893e557979519f97e679242ca96f6ec640fecb4581adb32c637c9fb3a58c |
| valresultat/kommun_bestallda_valsedlar_SD_2002.txt | 10797f06747971faf2ac2b23a6d1c2a0 | f641ff18a673ee36e90b136f0a96e7dc1ca0fa3151ffb5f71d781bd4e5f07b90 |
| valresultat/tillagg_ovriga.pdf | b0094d49a33e919a9cf2d865f72fe78e | 83fa892e978ca3adac82189e8b685d262ac5e443937b9bad666ce70e56141dff |

Selected snapshots from the full local manifest, retrieved 2026-10-12:

| Exact source URL | Bytes | SHA256 |
| --- | ---: | --- |
| https://historik.val.se/val/val_02/slutresultat/00R/00.html | 41431 | 9eeda5ef7731c32a9112fa97bfc0228c3a34baf392469f6656920d4327bf4303 |
| https://historik.val.se/val/val_02/slutresultat/00L/00.html | 35312 | fbe8cb83f0e6a455f171868ccfe0abe1dd6592a1ee77a40b0aced8afe9501f1f |
| https://historik.val.se/val/val_02/slutresultat/00K/00.html | 57340 | 3c880cbe2d9d4a88701be0e5c09ec03975e7e0bd83883714219f59c47389fafb |
| https://historik.val.se/val/val_02/valnatt/00R/00.html | 27556 | f773605bba605f1d6623befd52cf59dd3ee427a181137e61e49fdbc11ada6911 |
| https://historik.val.se/val/val_02/valnatt/00L/00.html | 26907 | 4bd9df51a71eb63d75824addba4a42c43e67e15ba7dc0e302436beed680ce211 |
| https://historik.val.se/val/val_02/valnatt/00K/00.html | 26989 | 2bf17966504dd68397cdb5cfa8def23bd9c14bfddf5d1053692d4b6f73e2b464 |
| https://historik.val.se/val/val_02/slutresultat/07R/0707KR-totalt.html | 27054 | d66735603b2ff1404258d8f31f6d57d05672c89ec32d19a47d6844adb09af531 |
| https://historik.val.se/val/val_02/slutresultat/07R/0707KR-lista.html | 26957 | 7e318e03075bd964ceaeae9622e5059a86695c7773580e731874e506f6548602 |
| https://historik.val.se/val/val_02/slutresultat/01L/0110KL-totalt.html | 29318 | 730bde318f6223e0a6e461d23e7d8ddb3c646f292aa2403021b14b49da0005b9 |
| https://historik.val.se/val/val_02/slutresultat/01K/0163/016301-lista.html | 40258 | e299ae805fae8537f11269ec893cb04b1dda101045d3fbe8d9bec79763d060fb |
| https://historik.val.se/val/val_02/slutresultat/01K/0163/K-0163-01.html | 16881 | eb9bb8e9d03c41d8bc34dbb930521c37a5e05d666116c3a79dde96f4aafc524f |
| https://www.scb.se/contentassets/0306ea5d06f34dfab00ef2ca653a5284/me0104_do_2002.pdf | 2098100 | 10696439d232f22b628f0eb327801d3c2cac106acb3b02a4300e820d596ab7a1 |

## 13. Focused Orsa investigation: two separate election occasions

Reviewed 2026-10-12. No production reader, public schema, raw source or canonical
asset was changed. Newly acquired evidence is preserved separately under
`.local-data/rkl/2002/orsa-review-20261012/`; the earlier source-review collection
and its manifest remain unchanged.

### 13.1 Election occasion and legal/source chronology

- **Ordinary election:** KF Orsa, municipality `2034`, election date
  **2002-09-15**. Valprövningsnämnden's decision **43-2002**, dated
  **2002-11-20**, says the county board certified the outcome on **2002-10-04**.
  Five advance ballots were omitted. The decision annulled the municipal
  election and ordered a rerun; it did not add those ballots to an amended
  version of the ordinary result.
- **Rerun:** KF Orsa, election date **2003-03-16**. Valmyndigheten's historical
  guide expressly identifies this separate election and says its result is
  shown in the 2002 presentation.
- The recovered **ordinary XML** expressly says
  `TILLFÄLLE="Allmänna val 15 September 2002"` and
  `RAPPORTERING="SLUTLIG SAMMANRÄKNING RESULTAT"`. Root `TID_RAPPORT` is
  `20021210181459`; municipality/constituency report time is `20020920164936`.
  These source timestamps are not the election date or certification date.
  The archive capture is **2003-01-26 15:10:28** (Wayback timestamp).
- The recovered **rerun XML** expressly says `TILLFÄLLE="Omval 16 Mars 2003"`,
  with the same final-report label. Root report time is `20030320111615`;
  municipality/constituency report time is `20030320104922`. Its capture is
  **2003-04-26 22:32:58**.

Authoritative context:
[Valprövningsnämnden 43-2002](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/valprovningsnamndens-beslut/fem-fortidsroster-hade-inte-natt-valnamnden-i-tid_gqd34c3294/)
and [Valmyndigheten's historical guide](https://www.val.se/valresultat-och-statistik/riksdags--region--och-kommunval/tidigare-valresultat).

### 13.2 Recovered primary sources and present-day replacement

| Occasion/source | Original Valmyndigheten URL/path | Preserved version and evidence |
| --- | --- | --- |
| Ordinary final XML | `http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml` | [Archived XML, 2003-01-26](https://web.archive.org/web/20030126151028id_/http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml); full municipality, constituency, five ordinary districts and one Wednesday district, party/list/person-vote and elected/substitute structures |
| Ordinary final municipality HTML | `http://www.val.se:80/val/val_02/slutresultat/20K/2034/2034.html` | [Capture 2003-01-20](https://web.archive.org/web/20030120121641id_/http://www.val.se:80/val/val_02/slutresultat/20K/2034/2034.html) and [capture 2003-02-03](https://web.archive.org/web/20030203153111id_/http://www.val.se:80/val/val_02/slutresultat/20K/2034/2034.html); identical election tables. The only line difference is the source-generated HTML creation comment, 2002-12-18 versus 2003-01-21 |
| Rerun final XML | Same original XML URL as above | [Archived XML, 2003-04-26](https://web.archive.org/web/20030426223258id_/http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml); independently recoverable and explicitly labelled as the rerun |
| Current final municipality/text | `https://historik.val.se/val/val_02/slutresultat/20K/2034/2034.html` and `2034-text.html` | Rerun figures, title/report time 2003-03-20 10:49:22 |
| Current final constituency | Same directory, `203400.html`, `203400-totalt.html`, `203400-lista.html` | Rerun party/list/person-vote and elected/substitute presentation; current names redacted |
| Current night municipality/text | `https://historik.val.se/val/val_02/valnatt/20K/2034/2034.html` and `2034-text.html` | Rerun election-night figures, title/report time 2003-03-16 22:44:00; turnout 77.6%, distinct from the final rerun's 79.7% |
| Subsequent election's comparison | `https://historik.val.se/val/val2006/slutlig/K/kommun/20/34/roster.html` | The column labelled **2002** also contains the **2003** rerun: 4,303 valid, 4,316 cast, 5,413 eligible, 79.73% turnout and the rerun mandates |

The original and rerun XML use **the same filename and original URL**, but have
different election-occasion labels and values. The current presentation has
replaced/incorporated the original Orsa outcome, rather than preserving two
independent election occasions at that location. This affects KF district,
municipality, county/intermediate and national aggregates. It does not turn
Orsa's ordinary RD/RF elections into reruns.

The old municipality HTML links to both the original XML and
`/val/val_02/protokoll/slutresultat/2034K.html`. The present historical host
returns 404 for both those old paths. Archived XML is therefore the operative
primary source for the ordinary Orsa outcome. This is a **new positive XML
finding**, revising the earlier current-link-only assessment; it is not evidence
that the entire 2002 national source collection has been recovered in XML.

A focused archive query for the original **night** municipality page timed out.
No original Orsa 2002 night/preliminary capture was recovered in that first
attempt; section 14 now resolves the election-night source gap. The recovered
ordinary **final** XML must not fill a preliminary-data gap. Earlier failed
archive probes (429/timeout), unsuccessful SCB publication probes and successful
CDX indexes are recorded as such, without treating an index as a source payload.

### 13.3 Party votes and allocated mandates

These are direct values from the two official XML snapshots, not a recomputed
mandate allocation. Both municipal `GILTIGA` and constituency values agree.

| Party | Ordinary 2002 votes | Rerun 2003 votes | Vote change | Ordinary seats | Rerun seats | Seat change |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| M | 377 | 280 | -97 | 3 | 2 | -1 |
| C | 898 | 1,034 | +136 | 7 | 8 | +1 |
| FP | 237 | 170 | -67 | 2 | 1 | -1 |
| KD | 223 | 289 | +66 | 2 | 2 | 0 |
| S | 1,588 | 1,619 | +31 | 13 | 12 | -1 |
| V | 277 | 260 | -17 | 2 | 2 | 0 |
| MP | 189 | 199 | +10 | 1 | 1 | 0 |
| SPI | 88 | 274 | +186 | 0 | 2 | +2 |
| SD | 121 | 135 | +14 | 1 | 1 | 0 |
| ND | Not separately reported | 43 | Not comparable separately | Not separately reported | 0 | Not comparable separately |
| ÖVR, remaining source category | 11 | 0 | Not comparable as a stable party population | 0 | 0 | 0 |
| **All parties** | **4,009** | **4,303** | **+294** | **31** | **31** | **0** |

ND is separately identified only in the rerun source; do not infer an ordinary
ND value of zero. The comparable combined smaller-party category
`SPI + SD + ND (where separately present) + remaining ÖVR` is **220 versus 452**.
The ordinary XML preserves SPI and SD separately, unlike SND's combined `vr`.
The HTML/XML `*_FGVAL`, `+-` and previous-election values refer to **1998**, not
an automatic comparison between September 2002 and March 2003.

| Field | Ordinary 2002 | Rerun 2003 | Assessment |
| --- | ---: | ---: | --- |
| Eligible voters | 5,389 | 5,413 | Explicit XML `VALDELTAGANDE/@RÖSTBERÄTTIGADE` |
| Votes cast | 4,070 | 4,316 | Explicit `SUMMA_RÖSTER`, +246 |
| Valid votes | 4,009 | 4,303 | Municipality `RÖSTER` equals sum of direct party `GILTIGA/@RÖSTER` |
| Invalid votes, combined | 61 | 13 | Direct `OGILTIGA/@RÖSTER`, -48 |
| Blank votes separately | Unavailable | Unavailable | Neither XML splits the combined OG category; preserve typed NA rather than infer zero |
| Other invalid separately | Unavailable | Unavailable | The 2006 comparison places the old 13 under an invalid category but leaves old blanks empty; it does not establish a separate verified blank count |
| Turnout, source display | 75.5% | 79.7% | Exact counts imply about 75.5242% and 79.73397%; increase about 4.21 percentage points |
| Ordinary polling districts | 5 | 5 | Same source codes, separate occasions |
| Wednesday district | 1 | 1 | `K-2034-00`; ordinary 50 valid/53 cast, rerun 110 valid/111 cast |
| Area preference votes | 1,764 | 1,904 | `KRETS_KOMMUN/@PERSONKRYSS`, +140 |
| Actual elected source records | 31 | 31 | `VALD`, matching allocated seats in each snapshot |
| Substitute source records | 25 | 28 | `ERSÄTTARE`; relation records, not a claimed count of distinct persons |

### 13.4 Elected/source-observation comparison

The archived XML retains names and within-party/group order; the live rerun
HTML redacts names. Neither recovered `VALD` structure supplies a verified
stable person ID. List `PERSONVAL/@KANDIDAT` is a list-scoped candidate/position reference
(for example 1, 2, 7 in a list), not a demonstrated person key;
`PERSONVAL/@ORDNING` is preference rank with ties.
Do not treat either as a global candidate/person identifier.

The full 31 ordinary and 31 rerun elected records, including party and source
order, are retained in the local `comparison-controls.json`. There are 27
identical party/name strings; this is a record-string comparison, **not** an
inferred person-identity crosswalk. The source-record differences are:

| Source name/party | Ordinary elected record | Rerun elected record |
| --- | --- | --- |
| Sofia Diefke, M | Order 3 | Absent |
| Marianne Hållmarker, FP | Order 2 | Absent |
| Barbara Sundberg, KD | Order 2 | Absent |
| Lottie Sundberg, S | Order 13 | Absent |
| Johan Smids, C | Absent | Order 8 |
| Ulf Björklund, KD | Absent | Order 1 |
| Hasse Thelin, SPI | Absent | Order 1 |
| Eva Sillén, SPI | Absent | Order 2 |

There are also source-order changes, including S: Anders Rosell 2 -> 4,
Börje Eriksson 3 -> 2 and Marie Olsson 4 -> 3; KD: Bengt-Åke Svahn 1 -> 2.
The two original relationship sets must be kept independently. Neither the
rerun roster nor later mandate-period events may replace the ordinary roster.
No public candidate-name policy or person-linkage rule is decided in this review.

### 13.5 Validation and remaining limits

Read-only R checks passed:

1. Both XML files parse with their declared ISO-8859-1 encoding and explicitly
   identify their respective election occasions and final counting stage.
2. All direct municipality and constituency party counts/mandates agree.
   Both contain six complete district units: five `VALDISTRIKT` and one
   `ONSDAGSDISTRIKT`, each represented once.
3. Ordinary district valid counts are **879, 988, 564, 1,055, 473 and 50**;
   rerun counts **1,071, 1,133, 705, 1,106, 578 and 110**. Each set sums to its
   own municipality total. District OG sums are 61 and 13 respectively.
4. All six ordinary district party/valid/cast controls agree with the local
   SND KF SAV, using official municipality/district keys and the source-role
   mapping of SND's postal row to the XML Wednesday district. All seven major
   parties and the combined smaller-party category reconcile, not just totals.
5. Direct area candidate preference records sum to **1,764 / 1,904**;
   direct district candidate records independently sum to **1,764 / 1,904**.
   Nested list and district representations are not added to area totals.
6. Both 31-seat party allocations reconcile with the 31 elected records.
   The separately recovered rerun agrees with today's municipality/text data
   and the 2006 page's previous-election values.
7. All **11 original local files** retain their recorded size, MD5 and SHA256;
   all **23 new preserved response objects** pass recorded size/hash checks.

The VPN narrative has an imprecise C percentage (22.9%) compared with the
original explicit 898/4,009 counts. Use the actual result XML counts rather than
reverse-engineering votes from rounded narrative percentages. The original
last S mandate and SPI's failure to obtain a mandate agree with the decision.
SCB's current Statistics Database and local KF DTA represent the rerun, so they
must not be used as evidence against the original ordinary result. SCB directs
users to *Allmänna valen 2002, del 3* for ordinary results; the full publication
was not recovered through the bounded URL probes in this review. The archived
primary XML resolves Orsa without requiring SCB as a substitute source.

The ordinary Orsa **final** result is now supported. Full 2002 preliminary
coverage, nationwide candidate identity/ballot population and an unredacted
national primary export remain separate unresolved inventory questions.

### 13.6 Recommendation for implementation and future election occasions

**Implement ordinary 2002 including the correct original Orsa final result.**
Use the pinned pre-rerun official XML for every KF Orsa final component:
party/district votes, totals/turnout, mandates, area/list/person-vote observations,
elected and substitute relations. Do not combine the original votes with the
rerun's elected list or use the current `valnatt` branch for September 2002.
Unsupported categories and identities remain missing.

Recompute affected KF parent aggregates from consistently selected ordinary
municipalities rather than trusting current 2002-labelled parent pages. As a
diagnostic, replacing only the rerun Orsa totals with the original gives
**5,409,855 cast / 5,312,977 valid / 96,878 invalid** nationally, reconciling with
the existing ordinary SND cast/valid controls. Allocated seats remain unchanged
because both Orsa occasions allocate 31. No such dataset was built here.
Do not modify RD/RF Orsa values on account of the municipal rerun.

Model each occasion separately in a future design, conceptually:

| Concept | Ordinary Orsa | Rerun Orsa |
| --- | --- | --- |
| `valtillfälle` | Ordinary occasion, 2002-09-15 | Distinct rerun occasion, 2003-03-16 |
| Election code/geography | KF / 2034 | KF / 2034 |
| Election date | 2002-09-15 | 2003-03-16 |
| Election kind / `valklass` | Ordinary election | Rerun (`omval`) |
| Relationship | Preceding ordinary election | Explicit reference to that preceding occasion and the annulment decision |
| Counting stage | Final or separately verified preliminary | Final or separately verified preliminary for the rerun |

The election date, occasion ID and predecessor relationship must distinguish
these records; year `2002` alone, geography alone, report timestamp or source
filename cannot. An annulled ordinary result can remain available for research
with its annulment/supersession status documented; the rerun remains a different
election, not a revision of its vote observations. Results, seats, elected and
substitute records all require the same occasion scope. Do not combine two
Orsa ballots in national turnout denominators or accidentally add the rerun to
ordinary-year totals. Public API/schema generalisation requires a separate
approved design; it was not implemented here.

### 13.7 Pinned source provenance

Both XML bodies are newly preserved, unchanged, in the separate local review
collection; archive capture times and retrieval timestamps are distinct.

| Snapshot | Retrieved UTC | Bytes | MD5 | SHA256 |
| --- | --- | ---: | --- | --- |
| Ordinary XML, capture 2003-01-26 15:10:28 | 2026-10-12T09:45:41Z | 127763 | 3249b5428225a4e6d0c77dbcd1d17340 | 88cc548c0a4044bac264647824145b909ae71546e42a5c15e3d110d8adcc6b68 |
| Rerun XML, capture 2003-04-26 22:32:58 | 2026-10-12T09:47:01Z | 133680 | 816b7a5f0ce4028dd31af9d18b259113 | 2ed9f72f36cbbb2b682d42d7a299a388b2c394d9ee4e3b393c46c9cd1fe4775c |

Local files:

- `objects/orsa-ordinary-2002-xml-1446806bee43.xml`
- `objects/orsa-rerun-2003-xml-123c236533b8.xml`
- `source-manifest.json`: exact original/archive/current URLs, effective URL,
  retrieval UTC, status, bytes and MD5/SHA256 for every successful response.
  SHA256: `bdfca68bbfafb6e1983e6413bcd8eb86336c4f8c4c0bde98cddd7b1d4d4e705e`.
- `comparison-controls.json`: independently extracted party/elected/district
  and preference-vote controls, kept locally rather than published as data.

No source, canonical or production file was overwritten; no commit/push or
canonical build was performed. Only this inventory report is intended for Git.

## 14. Final targeted search: original Orsa 2002 election-night result recovered

Reviewed 2026-10-12. This follow-up supersedes the **election-night** source gap
in section 13. It does **not** establish a full preliminary stage including
Wednesday/collection-district votes. No production or canonical changes were
made, and no final collection figure was substituted for a preliminary value.

### 14.1 Search scope and outcome

Use of exact URLs, rather than search-engine coverage, recovered the sources:

- Derive `valnatt/20K/2034/2034.html` from the original final HTML's `Valnatt`
  link and `senaste/valnatt_2034K.xml` from the recovered export naming pattern.
  The archived night HTML independently confirms that exact XML URL.
- Query Wayback CDX for successful captures **2002-09-01 through 2003-03-15**,
  before the rerun. Both exact URLs have indexed captures, and **both bodies
  were successfully retrieved** through timestamped `id_` replay.
- Follow the archived night page's actual parent links to
  `valnatt/20K/20.html` and `valnatt/20K/2024KR.html`. Their recovered January
  2003 captures link explicitly to **Orsa (5 av 5)** and the original night
  municipality page. No separate collection/preliminary branch appears in
  these recovered parent/municipality links.
- Recover the explicitly linked fixed-width text source
  `valnatt/20K/2034/2034-text.html` from its February 2003 capture.
- Query the Orsa night directory prefix for all indexed successful URL keys
  in the same pre-rerun window. It returns municipality HTML/text and four
  of the five linked individual district HTML pages. **Orsa Södra's URL
  `20340203.html` is explicitly linked but has no successful indexed capture
  in this query window**; that does not mean its URL never existed. All five
  districts, including Södra, are present in the recovered XML and text.
  The other four standalone district pages are indexed but were not separately
  downloaded because XML/text already preserve their complete vote rows.
- A separate Orsa-directory query for **2002-09-15 through 2002-10-04** covers
  election day, the following week and the period before certification. It
  returns an empty successful-capture index. This is an archive-date coverage
  limitation, not evidence that the contemporary result was unavailable.
- A narrowly filtered `senaste/` export-prefix query for Orsa returns only
  `valnatt_2034K.xml` and `slutresultat_2034K.xml` in the pre-rerun window.
  No separately named full preliminary/collection export was identified.
- Arquivo.pt's exact original night-URL version-history query returns zero
  indexed captures. Search-engine queries return today's rerun presentation,
  not an original 2002 source. Neither negative result overrides the positive
  Wayback payload recovery.

This run used bounded, sequential requests, a short delay between requests,
exact/prefix queries scoped to Orsa and its actual parent/export links, and
cached successful responses. All 14 requests succeeded; earlier timeout/429/503
results are retained in the previous manifest, not reclassified as absence.
No broad national archive crawl was performed. The targeted investigation is
closed with a **positive election-night recovery** and a separately stated
remaining full-preliminary limitation.

### 14.2 Election-occasion and counting-stage verification

The recovered XML declares:

```text
TILLFÄLLE = Allmänna val 15 September 2002
FILNAMN = valnatt_2034K.xml
RAPPORTERING = VALNATT RAPPORTERING
VALTYP = Kommunfullmäktigval
TID_RAPPORT = 20020916131952
```

Municipality `2034` and constituency `203400` are Orsa, reporting **5/5**
ordinary districts. Their source report time is **2002-09-15 23:09:30**,
matching the recovered HTML/text title. District report times are also on
15 September 2002. Capture dates in January/February 2003 are preservation
metadata, not election dates. The XML's explicit ordinary-election label,
September report times and different counts establish that it is neither the
March 2003 rerun nor a relabelled final ordinary result.

There are five `VALDISTRIKT`, with unique official codes:
`20340201`, `20340203`, `20340204`, `20340206`, `20340202`.
There is **no `ONSDAGSDISTRIKT`**. This distinction is substantive, not a
missing sixth ordinary district. No candidate/person-vote, elected or substitute
records occur in the night XML. Its provisional mandate fields are not official
final elected relationships.

### 14.3 Comparison with the separately recovered ordinary final result

| Party/category | Ordinary 2002 night | Ordinary 2002 final | Final minus night |
| --- | ---: | ---: | ---: |
| M | 372 | 377 | +5 |
| C | 895 | 898 | +3 |
| FP | 232 | 237 | +5 |
| KD | 217 | 223 | +6 |
| S | 1,571 | 1,588 | +17 |
| V | 264 | 277 | +13 |
| MP | 184 | 189 | +5 |
| SPI | 87 | 88 | +1 |
| SD | 120 | 121 | +1 |
| Remaining ÖVR | 10 | 11 | +1 |
| **Valid votes** | **3,952** | **4,009** | **+57** |
| **Combined invalid votes** | **63** | **61** | **-2** |
| **Votes cast** | **4,015** | **4,070** | **+55** |
| Eligible voters | 5,389 | 5,389 | 0 |
| Source turnout | 74.5% | 75.5% | Rounded source levels |

Both stages have identical geographic identifiers but different observations.
Separate blank/other-invalid counts remain unavailable. The night total is
about **74.5036%** of eligible voters; the final total is about **75.5242%**.

The final ordinary Wednesday district has 50 valid and 53 cast votes. Final
ordinary polling districts also differ from the night snapshot: **+7 valid,
-5 invalid, +2 cast**. Therefore adding that **final** collection district to
the night snapshot gives neither a source-verified preliminary result nor the
final total (4,068 versus 4,070 cast). This diagnostic is not a reconstruction;
**no final collection votes were used as preliminary observations**.

Read-only independent R controls passed:

- every party's district sum equals its constituency and municipality value;
- all five codes are unique and every district appears once;
- HTML, fixed-width text and XML have identical municipality party/OG values;
- independently parsed text district rows match all five XML district rows,
  including Orsa Södra despite its standalone HTML capture gap;
- valid plus invalid equals explicit `SUMMA_RÖSTER = 4015`;
- original final comparison uses the pinned section-13 XML, not current rerun data.

### 14.4 Preserved sources and checksums

New local collection: `.local-data/rkl/2002/orsa-preliminary-review-20261012/`.
Original sources and the prior Orsa collection were not overwritten.

| Source | Archive capture | Bytes | MD5 | SHA256 |
| --- | --- | ---: | --- | --- |
| [Night XML](https://web.archive.org/web/20030124230111id_/http://www.val.se:80/val/val_02/senaste/valnatt_2034K.xml) | 2003-01-24 23:01:11 | 10087 | f6cb26b0bade301debc211fa227e8f12 | f0ac19c757e30bad3b33a3cd4bfa4856a23dccf0619aa8cc1fc7729ab381ba90 |
| [Municipality HTML](https://web.archive.org/web/20030120082726id_/http://www.val.se:80/val/val_02/valnatt/20K/2034/2034.html) | 2003-01-20 08:27:26 | 15881 | f0d765e3d99084a27fb983eaccb9b35e | 2716e942891e43d95cf04896d5e4be1a9916bd1e2ea4544184b754c053819bc4 |
| [Fixed-width text](https://web.archive.org/web/20030203153147id_/http://www.val.se:80/val/val_02/valnatt/20K/2034/2034-text.html) | 2003-02-03 15:31:47 | 1811 | 8ed47cb075f95e2c7e13cb3b9d619d40 | a2ecd644c45390c40e49059dd07a021b96b4a0211b423b711ef3539f746f39b1 |
| [County parent](https://web.archive.org/web/20030107195216id_/http://www.val.se:80/val/val_02/valnatt/20K/20.html) | 2003-01-07 19:52:16 | 20927 | bab5ca7ad445de4a588bbc8769aeb78e | e4e1d7e6dda4113641272773a27cc7a2c7765ea0f8d16a1d5525cfc8e8309a27 |
| [Intermediate parent](https://web.archive.org/web/20030111162854id_/http://www.val.se:80/val/val_02/valnatt/20K/2024KR.html) | 2003-01-11 16:28:54 | 21041 | ffb4008be4c3995f75c4ad207eeeae74 | 1c83f67ce42ff795ce5bd01461ec54a0066e38e0d26bb868edf8a0d7ba2ce25a |

Original URLs are the corresponding `http://www.val.se:80/val/val_02/...`
paths embedded in these archive links. Exact original/archive request URLs,
effective URLs, retrieval UTC, response sizes, MD5 and SHA256 are in the new
`source-manifest.json`. Its SHA256 is
`5e050e9f869d867105da03630162c706e78382ee82fdb957926ed745dac2e4b2`.
XML was retrieved **2026-10-12T10:09:48Z**, municipality HTML at
**10:09:39Z**, text at **10:14:02Z**, county parent at **10:12:06Z** and
intermediate parent at **10:14:13Z**. CDX compressed archive lengths are not
used as downloaded source sizes. Index JSON is distinguished from source bodies.

The XML file is `objects/ordinary-2002-night-d58e49e7aa3e.xml`.
Local `comparison-controls.json` preserves extracted stage labels, geography,
party/district controls and the final comparison. All **14 preserved response
objects** pass size/MD5/SHA256 checks; all **11 original local sources** and the
previous Orsa manifest retain their pinned hashes. Only this inventory report
has changed outside ignored local preservation/diagnostic material.

### 14.5 Conclusion for implementation planning

**The ordinary Orsa 2002 election-night result is recovered and validated.**
It can be preserved and used as its actual historical counting snapshot.
The claim that the original night result remains unrecovered is superseded.

**A separate complete preliminary result including preliminary collection votes
remains unrecovered in this targeted search.** The retrieved source is explicitly
valnatt and contains only five ordinary districts. No separately verified
preliminary collection page/export was found in its links, parents or the
narrow indexed Orsa exports. That is a scoped recovery limitation, not proof
that such a source was never published or never archived elsewhere.

Keep the ordinary night, ordinary final and 2003 rerun sources distinct. Do not
silently relabel the recovered night result as the package's full preliminary
stage, add final collection values, or implement a new public stage in this
source-review task. Stage/API decisions remain for a separate review.

## 15. Implementation-stage final XML discovery (12 October 2026)

Subsequent bounded archive preservation recovered the original national final
exports `slutresultat_00R.xml`, `slutresultat_00L.xml`, `slutresultat_00K.xml`.
Their January 2003 captures explicitly describe the ordinary 15 September 2002
election and contain the original Orsa totals. Together with municipal exports,
the selected registry contains **869 XML sources**: three national, 287 RD,
289 RF and 290 KF. Retrieval/capture times, original/replay URLs, sizes and
MD5/SHA256 are recorded locally and in the prototype provenance.

Exact bounded checks still leave three RD municipal exports unrecovered:
Halmstad 1380, Laholm 1381 and Kungsbacka 1384. Complete RD district and
municipal-constituency views therefore remain unavailable; national, county,
constituency and municipality coverage is complete through the national XML.
This is a recovery limitation, not proof that those exports were never produced.

The 2002 RD/RF final collection districts are direct municipality children,
while KF collections are constituency children. They are final sources only.
The implementation includes both placements once and does not add them to the
recovered night material or expose an unverified full preliminary stage.

The original final appointment census gives 349 RD, 1,656 RF and 13,271 KF
elected observations. KF has 13,274 allocated seats and three explicit unfilled
slots (Håbo one, Olofström two). No complete ballot-candidacy register or stable
person identifier has been established. Result, list and appointment observations
remain source-scoped; no name-based linkage or invented ballot population is used.

Independent controls pass 9,529 XML geographic comparisons and 6,982 SCB
municipality/party comparisons. These do not remove the already documented
four-party presentation limitation in section 4. Individual preference posts
also do not cover unidentified ÖVR preference aggregates; list/source-control
differences are retained rather than corrected. Exact implementation coverage,
counts and unresolved findings are in [IMPLEMENTATION_2002.md](IMPLEMENTATION_2002.md)
and [VALIDATION_2002.md](VALIDATION_2002.md).

## 16. Focused final ordinary-result reconciliation

See [FINAL_RESULT_RECONCILIATION_2002.md](FINAL_RESULT_RECONCILIATION_2002.md)
for the complete follow-up, exact geographic differences and current package
impact. It supersedes section 8's apparent 13-person SND eligible-voter gap:
SND equals the definitive SCB control (6,722,163), while selected final XML
uses 6,722,152. SCB documents its later electoral roll and rounding rules.
The ordinary ballots/mandates reconcile; the four-party RD supplement supplies
107 explicit corrected constituency cells and nine genuine blanks. Its known
values are established, but no supplement overlay was applied to production
or canonical data in this review.

## 17. Official supplement source established and incorporated

The official source is
https://historik.val.se/val/val_02/slutresultat/tillagg_ovriga.pdf . A fresh
13 October 2026 download exactly matches the preserved PDF checksum recorded
above. The approved disclosed corrections are now incorporated in result
output. See [SUPPLEMENT_2002.md](SUPPLEMENT_2002.md) for full provenance,
unknown-cell handling, aggregate coverage and the two supported lower-level
zero corrections. No candidate, preference-vote or mandate reader is changed.
