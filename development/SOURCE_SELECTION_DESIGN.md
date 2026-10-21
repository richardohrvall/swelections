# Source selection: audit and proposed default policy

Status: implemented and validated, 20 October 2026. The audit below
records the former behavior; the implementation section records the new policy.

## Recommendation

Keep the existing `source = c("auto", "local", "remote", "canonical")` API in
both languages. Keep `auto` as the argument default, but make its normal policy
**approved canonical coverage first**. `remote` explicitly selects supported
Valmyndigheten sources; `local` explicitly selects the user's saved raw sources.
`canonical` explicitly requires canonical data and never silently switches source.
No additional `raw`, `valmyndigheten` or per-function mode is needed.

A completed local development prototype is not by itself a distributable default.
Canonical coverage must have a validated, approved registry entry and a resolvable
manifest/assets location. Published releases provide this for ordinary users;
an explicitly configured local collection can provide it for its owner after
approval for automatic selection. Do not discover `.local-data` or machine paths.
Existing `auto_eligible = false` prototypes remain opt-in until that separate
approval/promotion step. This proposal does not publish or promote any dataset.

## Audit of the previous behavior

| Path | Current behavior |
| --- | --- |
| Public arguments | All seven English functions and Swedish wrappers accept `auto`, `local`, `remote`, `canonical`, plus `data_dir`; names/detail are independent. |
| Automatic canonical coverage | `.canonical_release_registry()` contains only RKL 2018, `data-v0.1.0`. `.canonical_release()` selects by year. |
| RKL 2018 `auto` | Complete required local raw files win; otherwise published canonical is tried if `nanoparquet` is installed; otherwise remote is selected. Manifest acquisition failure can fall back to remote. |
| RKL 2002/2006/2010/2014 | Dispatch branches bypass the common automatic selector: canonical requires an explicit request/configured manifest; otherwise preserved local sources are required. |
| RKL 2022/2026 | No approved automatic canonical registry entries. `auto` follows raw-file resolution; explicit canonical is supported for configured 2022, not 2026. |
| EU 2004/2009/2014/2019/2024 | Separate dispatch checks only explicit `source = "canonical"`; otherwise it invokes the year's raw reader. All five have unpublished local canonical prototypes with `auto_eligible = false`. |
| Referendum 2003 | Separate explicit canonical branch; otherwise its raw resolver. No automatic canonical registry entry. |
| Re-election events/compositions | Preserved local final sources are required; current re-election dispatch rejects `remote` and `canonical`. An ordinary component of a composition can use its ordinary-election source. |
| Mandate-period history | Uses its documented preserved sources. The existence of a canonical election-result product does not imply canonical mandate-period history. |
| Configured manifests | `swelections.canonical_manifest` supports a single path and several readers support paths named by year. It is not an automatic discovery mechanism for EU prototypes. |
| Generic raw `auto` | `val_file()` uses the configured local file if present and otherwise returns the official URL. A multi-file raw request can consequently mix local and remote components. |
| Explicit raw choice | `local` never substitutes a remote file; `remote` bypasses the local raw-file preference where supported. Retrieval/parsing caches are implementation-specific. |

The source tests in `tests/testthat/test-canonical-backend.R` explicitly enforce
local-raw-first 2018 behavior. This is deliberate existing policy, not an
accidental missed `if` statement. Changing it needs updated tests and migration
documentation. README's general source paragraph also understates the now larger
explicit-canonical coverage; update it when the new policy is implemented.

## Explicit raw sources and user archives

Examples of the **existing** interface (subject to year/level support):

```r
# Direct current structured official sources, irrespective of local canonical data:
results(2026, "regional", source = "remote")
candidates(2026, "regional", source = "remote", detail = "full")

# A user's own saved official files in the supported archive layout:
results(2026, "regional", source = "local", data_dir = "my-election-archive")
# Session-wide raw-root configuration is also supported:
options(swelections.data_dir = "my-election-archive")

# Existing explicit canonical selection:
options(swelections.canonical_manifest = "my-canonical-build/manifest.json")
results(2024, "european", source = "canonical")
```

`data_dir` denotes a supported raw archive, not arbitrary tabular data or a
canonical Parquet directory. Current generic modern paths use
`YEAR/COLLECTION/relative-path`; older RKL and EU readers have their own documented
layouts. A user's archive can live anywhere: it need not be the development
`.local-data` tree. Several historical adapters additionally require manifests,
reviewed original source versions and exact checksums. They are not general
importers for any snapshot with a similar extension.

Modern saved structured files already have a user-archive route. Some older
backends also depend on preservation-specific subdirectories/manifests, such as
2006's `archived-assessment-20261011/source_objects.csv` and the named 2014 final
snapshot directory. This is a real current constraint, not a generic local-file
import interface. A uniform local-source promise needs a documented public
archive/source-profile specification, with the existing preservation layout
retained as a compatibility profile. Do not require a `.local-data` location or
unrelated research files, but retain the source-version, integrity and coverage
checks needed by the historical adapters. No new public file-path argument is
necessary; `data_dir` remains the archive root.

In particular:

- RKL 2002/2006/2010/2014 require preserved local sources. RKL 2018 final XML is
  no longer downloadable through its raw source resolver, although candidate and
  party text sources have remote URLs.
- EU 2004/2009/2014 explicitly reject `remote`: they need preserved originals
  rather than current redacted/truncated substitutes.
- EU 2019/2024 support remote retrieval, but their accepted source hashes are
  pinned. A newly changed official file can be rejected rather than read as an
  arbitrary current snapshot. This must be assessed independently of changing
  `auto`; do not remove snapshot checks as a default-policy shortcut.
- Modern RKL 2022/2026 have the structured official index/file route. Its source,
  schema, checksum and election checks must remain in effect.

Raw source choice may expose published candidate names or more recent source
metadata absent from canonical. It can also reflect later corrections or updates;
there is no promise that a current official snapshot and a frozen canonical
product differ only in names. Do not automatically enrich canonical records with
remote names, change identities, or silently blend source generations. Preserve
the fixed-election versus mandate-period distinction and the source policy.

## Proposed resolution order

Resolve each requested **election family/event, year, function, count stage and
geographic view**, before loading data. Do not decide using year alone.

| Requested choice | Proposed behavior |
| --- | --- |
| `canonical` | Require approved/configured canonical coverage for the exact request; verify manifest/schema/assets and fail clearly if unavailable or invalid. No raw fallback. |
| `remote` | Use the supported official Valmyndigheten path, even if canonical exists. If that source/format is no longer supported, report that explicitly. |
| `local` | Require the user's saved sources in the supported format/version/layout. No network and no canonical substitution. |
| `auto`, approved canonical coverage exists | Select that canonical product before considering `data_dir` or a configured raw root. |
| `auto`, no canonical coverage for this request | Use a supported official remote route, never user-saved local raw files, even when a raw archive is configured. |
| `auto`, neither approved canonical nor supported remote coverage | Give an actionable source/coverage error. Do not manufacture a counting stage or substitute another election event. |

A missing coverage entry differs from a failed download or checksum. Once an
approved canonical product is selected, an integrity failure must stop; a network
failure should give retry/cache/explicit-source guidance, rather than silently
switching to a different source population. This is a deliberate tightening of
today's 2018 manifest-failure fallback and should have a dedicated regression test.

For compatibility, preserve the raw-operation meaning of explicitly requested
`update`/`archive`: with `auto` these request the existing raw operation and bypass
normal canonical selection; with `canonical` reject them. Keep current immutable
historical-source restrictions. Document this exception instead of ignoring flags.
Make canonical argument validation uniform: ordinary RKL already rejects
`data_dir` with explicit canonical, while EU currently does not apply that same
check. Do not silently ignore irrelevant raw arguments in the future resolver.

Passing only `data_dir` will cease to override approved canonical under `auto`.
Users wanting that archive must use `source = "local"`. This intended behavior
change needs a NEWS/help/README migration example; existing explicit choices,
column schemas and source validation should not otherwise change.

## Smallest implementation plan

1. Extend the existing coverage registry/resolver rather than add a new public
   source argument. Key entries by family/event as well as year: EU 2014 and RKL
   2014 are different products, and an ordinary election is not its re-election.
   Include supported tables/stages/geographies and approved data/schema versions.
   Align the current per-family explicit-canonical year whitelists with this
   coverage definition; a registry entry alone does not update those guards.
2. Route EU, referendum and early RKL explicit/automatic selection through that
   common decision point before their established readers. Preserve unsupported
   combinations and the separate re-election/history boundaries.
3. Reuse existing manifests, download/cache infrastructure, Parquet table readers
   and checksums. Published manifests must resolve for users without developer
   files. Existing single-manifest/year-keyed options remain compatible where
   unambiguous; add family-qualified configuration only where actually needed.
4. Promote validated builds to automatic eligibility only through the reviewed
   release/local-registration workflow. No code should contain local prototype
   paths. Distribution/publication is a separate authorized task.
5. Decide the canonical reader dependency explicitly. `nanoparquet` is currently
   in Suggests and missing it can send 2018 `auto` to raw. For a reliable canonical
   default, prefer making it a normal dependency after compatibility review;
   otherwise give an installation error, not a silent data-source change.
   The existing SHA verifier also checks for `tools::sha256sum`; include
   that requirement in the supported-R compatibility review.
6. Test the decision table, all seven functions and both languages; mixed years
   and families; canonical-before-local; strict explicit choices; unsupported
   preliminary levels; offline cached canonical; corrupted/missing assets;
   and `update`/`archive`. Keep source-value and raw/canonical validations separate
   from routing tests. Verify no election-event or candidate identity changes.

At the design-only stage, no registry entries, dependency declarations, source readers,
metadata values or source-selection tests had been changed. Implementation follows below.

## Implemented policy (20 October 2026)

The shared registration in `R/canonical_distribution.R` now identifies the
family, event kind, year, schema, canonical reader, approval status and optional
published location. The registry includes supported unpublished readers as
explicit-only entries. Manifest asset/table layouts determine the requested
function, count-stage and geographic coverage. Missing view coverage retains the
existing raw behavior; failures of a selected manifest/asset do not silently
switch source. Re-election and mandate-history source support is unchanged.

All seven RKL functions resolve before historical dispatch. EU functions and the
2003 referendum use the same policy. The EU canonical reader itself is selected
from the registry, so changing a supported EU product's approval status requires
no source-routing changes. By explicit user decision, **all five EU prototypes
retain `auto_eligible = false`**. Other unpublished entries likewise remain
explicit-only. Only the existing published RKL 2018 product is automatically
eligible; nothing has been released, promoted, rebuilt or discovered locally.

`auto` prioritizes approved canonical over a raw `data_dir`. Explicit `local`,
`remote` and `canonical` retain their roles. Explicit canonical validates raw-only
arguments consistently across RKL, EU and referendum. `update`/`archive` with
`auto` keeps the existing raw-operation intent and snapshot restrictions. A raw
request's internal candidate-enrichment calls stay raw rather than independently
switching to canonical. This request context is restored on success or error.

Configured manifest paths accept a single path, legacy year keys, `series:year`
keys, or the unambiguous `series:ordinary:year` keys. The most specific key wins.
Every selected manifest is validated against its family/year/event/schema.
The existing published 2018 manifest-cache location is retained for offline
compatibility. New product cache locations separate family/event/version.

The optional `nanoparquet` dependency remains in Suggests. This deliberately
uses the design's actionable-error alternative: if canonical is selected but its
reader is absent, installation guidance replaces the former silent raw fallback.
No dependency or minimum-R changes are made. The existing requirement for
`tools::sha256sum()` is documented, not bypassed or silently weakened.

No historical local-archive layout or remote hash policy is redesigned. A future
uniform archive/profile format remains separate work. A current EU 2019/2024
remote file still must satisfy its existing snapshot integrity checks; this
change does not make pinned readers accept arbitrary future source revisions.
The broad README review is deferred; only its source-policy paragraph and the
2018 raw-source wording are corrected. Installed help adds `?data_sources` and the migration example using `source = "local"`.

Validation evidence is kept locally under
`.local-data/source-selection-20261020/`; final counts are appended below.

### Final validation

- Full test suite: **4488 passed, 16 explicit skips; zero failures, errors or warnings**.
- `R CMD check --no-manual --no-vignettes`: **0 errors, 0 warnings, 0 notes**.
- **840 exact comparisons** over 105 actual public request cases across RKL
  2002/2006/2010/2014/2018/2022, EU 2004/2009/2014/2019/2024 and referendum
  2003. The frozen start-of-task implementation is the reference. Both languages
  and detail modes pass, including row order, values, types and attributes.
  Temporary registry approval tests auto selection; production EU status stays false.
- **12 additional exact comparisons** verify family-qualified 2014 manifests
  and requested 2022/2018 multi-year order in both languages/detail modes.
- **294 raw/canonical/frozen-output comparisons** pass for the four older EU
  readers, including all seven functions, supported result levels and 2019 preliminary.
  Nine additional historical/modern result controls pass, including EU 2024 and RF 2026.
- A real 2018 published-source integration passes **8 assertions** with
  preserved assets. A deterministic hypothetical EU publication test exercises
  manifest retrieval, asset checksums and offline cache reuse through `results()`.
- **9,529 original-source hashes**, **208 protected canonical asset entries**
  and **20 Parquet round trips** pass. No source/canonical files are rebuilt.
- `git diff --check` and separate new-file whitespace checks pass.
  `DESCRIPTION` and `NAMESPACE` are unchanged relative to this task's baseline.

The implementation touches common registration/selection, RKL per-year dispatch,
EU/referendum dispatch, manifest/asset resolution and the corresponding tests.
The new `R/data_sources.R` is documentation only, not a new public function.
Installed help, canonical workflow documentation, the contributor source rule,
and the narrowly scoped README source paragraph are updated. Existing unrelated
uncommitted mandate-history/performance work is preserved. No commit or push.

### EU delivery follow-up (20 October 2026)

The maintained `data-raw/validate-eu-YYYY.R` validators now omit `data_dir` from
explicit canonical calls. Their explicit local-source calls retain that argument;
the public rule rejecting raw-only arguments for canonical sources is unchanged.

Default release-manifest cache paths now include the election year:
`series/event_kind/year/data_version/manifest.json`. This isolates, for example,
EU 2019 and EU 2024 releases sharing a version. Explicit registry `cache_key`
values continue to take precedence; the published RKL 2018 key `data-v0.1.0`
is unchanged. Regression coverage checks both year-specific retrieval and offline
reuse. Existing prototype manifests do not need a data/schema migration.

No EU registry row has been approved for automatic selection. All five retain
`auto_eligible = false`; an explicit prototype manifest and `source = "canonical"`
remain the supported local validation route. Publication locations, release
versions and subsequent eligibility approval remain separate decisions. See
[CANONICAL_READINESS_EU.md](CANONICAL_READINESS_EU.md) for the delivery evidence.

## Revised policy: auto never selects user raw archives (21 October 2026)

This supersedes the earlier local-then-remote fallback and the earlier statement
that re-election source selection is unchanged. `auto` selects approved canonical
coverage, otherwise a supported remote source. `data_dir`, `swelections.data_dir`
and the legacy raw-root option never make an automatic request read user-saved raw
files. `local` is always explicit. Remote download caches and canonical caches
remain usable; they are not user-selected raw archives.

- RKL 2002/2006/2010/2014 require explicit `local` without approved canonical
  coverage. RKL 2018 result-dependent raw views also require explicit `local`;
  its supported remote candidacy/party sources remain usable automatically.
- RKL 2022/2026 and EU 2019/2024 use their supported remote resolvers when no
  approved canonical view is selected, even if matching local files exist.
- EU 2004/2009/2014 require explicit `local` without approved canonical coverage.
  No redacted current source replaces a pinned historical source.
- Referendum 2003 uses its remote path rather than discovering a saved archive.
- Re-election raw results require explicit `local`. Mandate-history functions
  already use explicit `local`/`canonical` choices and have no `auto` option.
- Explicit raw `update`/`archive` requests bypass canonical as before, but refresh
  from remote rather than reusing an existing user file. Historical read-only
  restrictions are unchanged. Explicit local archival still archives only the
  existing local file, without network access.

No registry flags, release membership, manifests or canonical assets change.
For a future EU 2009 approval with an eight-asset manifest, the existing view
coverage check permits `auto` for six functions. Preference votes have neither
approved canonical coverage nor a supported remote route and therefore error,
with guidance to use `source = "local"`. They never discover a local preference
archive automatically. Explicit private prototype canonical requests remain
available for testing. A registry-level approved-function allowlist to protect
against a full-prototype manifest override remains a separate proposed activation
safeguard; this source-fallback change does not implement or approve it.

This is an intentional compatibility change: calls previously relying on `auto`
plus `data_dir` or a raw-root option to read saved files must specify
`source = "local"`. No election values, identities or output schemas change.

### Verification of the revised policy

- Full test suite: 4,721 passed, 16 explicit external-source/integration skips,
  zero failures, warnings or errors. The isolated new regression file passes 89
  assertions, including all six EU 2009 preference levels and a simulated future
  eight-asset approval; the actual registry is unchanged.
- `R CMD check --no-manual`: zero errors, warnings and notes; built from an
  isolated working-tree package copy, not a committed or clean canonical build.
- Actual preserved EU 2009 local/canonical comparisons are `identical()` for
  final national results (25 rows), seats (11), candidacies (500), candidates
  (500), elected (18) and substitute relations (68), including order, types and
  attributes. No preference-vote values or allocations were changed.
- All 206 current canonical asset/manifest files and 1,300 protected historical
  asset/manifest references retain their recorded checksums. The complete
  canonical registry, including every `auto_eligible` value, is unchanged.
- `git diff --check` passes. No canonical rebuild, release, commit or push.

Local evidence: `.local-data/source-auto-remote-20261021/` (test results,
package build/check logs, and explicit-source comparison/integrity results).

## Implementerad central funktionsspärr (21 oktober 2026)

Registreringen innehåller nu `auto_functions` som uttrycklig funktionslista per
familj/valtillfälle/år. Alla sju funktioner listas för de fullständigt godkända
produkterna, sex utan `candidacies` för RKL 2002, sex utan `preference_votes` för
EU 2009 och endast `results` för folkomröstning 2003. Ingen `auto_eligible`-flagga,
versions-/cacheuppgift eller distributionsplats har ändrats.

Automatiskt val prövar i ordning:

1. Är valtillfället aktiverat?
2. Finns funktionen uttryckligen i registreringens `auto_functions`?
3. Finns den begärda faktiska vyn/nivån/räkningen i manifestet?

Saknad, tom eller feltypad funktionslista ger inget automatiskt godkännande.
Spärren använder samma funktionsidentitet för engelska och svenska API:t och
prövas före manifeståtkomst. Manifestet kan begränsa tillgänglig täckning men
aldrig utöka den centrala behörigheten. Den tidigare föreslagna EU 2009-spärren
är därmed implementerad; tidigare formuleringar om att den återstår är historik.

Explicit `canonical` passerar inte auto-gaten, men kräver fortfarande de faktiska
assetsen och läsarens vanliga validering. Därför går det fortsatt att uttryckligen
testa det privata fullständiga EU 2009-manifestet, medan publiceringsmanifestets
saknade P-assets ger fel. Explicit `local`/`remote` samt raw update/archive påverkas
inte. `auto` väljer aldrig användarens lokala råfiler.

Regressionerna i `test-canonical-auto-functions.R` verifierar det fullständiga
14-asset-fallet, samtliga sex P-nivåer och list-/nollvarianter via engelska och
svenska publika anrop, explicita källval, utebliven manifeståtkomst för nekade
funktioner, saknad behörighet, kvarvarande nivå-/stadiekontroll och oförändrade
flaggor för de tolv produkterna. Fiktiva payloads hålls isolerade från valdata.

Ytterligare kontroll med den faktiska oförändrade 14-asset-prototypen visar att
E6 ger exakt identisk output för simulerat auto och explicit canonical, medan
auto-P ger local-hänvisning trots befintligt råarkiv. Explicit prototyp-P återger
fortfarande de dokumenterade källraderna; inga källvärden har rättats här.

Den verifierade tabellen med dagens flaggor och separat minnessimulering av
aktivering finns i [aktiveringsinventeringen](CANONICAL_ACTIVATION_INVENTORY.md).
Lokala kontrollresultat: `.local-data/canonical-auto-function-gate-20261021/`.


## Faktisk aktivering och distributionskandidat, 21 oktober 2026

De tolv godkända produkterna är nu aktiverade i produktionsregistreringen.
Elva auto_eligible-flaggor ändrades till true; RKL 2018 behåller true och väljer
nu den korrigerade data-v0.4.0-generationen. De centrala funktionslistorna är
oförändrade: RKL 2002 saknar candidacies, EU 2009 saknar preference_votes och
folkomröstningen 2003 omfattar endast results. Inga andra valtillfällen aktiveras.

Detta ersätter tidigare avsnitts uppgifter om oförändrade/inaktiva flaggor.
Den aktuella omfattningen, exakta fil-/URL-listan, portabla proveniensmetadata,
valideringen och återstående publiceringssteg finns i
[CANONICAL_RELEASE_CANDIDATE.md](CANONICAL_RELEASE_CANDIDATE.md).
188 Parquet-filer och tolv unikt namngivna manifest förbereds; ingen publicering,
commit eller push har gjorts. Byggmanifestens build_tree_dirty är fortsatt true.



## Mandatperioder: godkänd avgränsning, 21 oktober 2026

RKL 2014 och 2018:s centrala funktionslistor utökas med mandate_history,
members_at och vacant_seats_at; alla tre använder samma canonical-historikasset
per period. Befintliga auto_eligible-flaggor och övriga produktuppgifter är
oförändrade. RKL 2022 får inga canonical-historikbehörigheter: auto väljer aktuell
remote-historik, med fast canonical-baslinje för ursprunglig mandatfördelning/valda.
Auto väljer aldrig användarens lokala filer. Inget kalenderstyrt byte efter
2026-10-31 är implementerat.

Aktuell releaseomfattning är 190 Parquet-assets och tolv manifest, inte 191.
Se [genomförd modell och validering](MANDATE_HISTORY_SOURCE_SELECTION.md).
Ingen commit, push eller publicering.
