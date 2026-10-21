> Uppföljning 21 oktober 2026: den godkända standardiseringen är implementerad för lokal validering. Se [värdekontraktet](VALUE_CONTRACT.md). De senare besluten ersätter auditens öppna alternativ: engelska interna nycklar, `yes/no/blank` för svarsalternativens namn och den gemensamma etiketten `Handwritten votes`. Ursprungsauditens observationer och resultat nedan är historisk baslinje.

# Audit av kategoriska värden i canonical och publika API:er

Datum: 2026-10-20. Granskad produktionsbas: `39622e7b3e2a37c4b35c272f03fb6535734d9e8f`
med den befintliga, ocommittade arbetskopian. Detta är en audit och ett förslag,
inte en genomförd ändring av värdekontraktet.

## Slutsats

Engelska kolumnnamn innebär i dag inte engelska kategorivärden. Svenska tekniska
värden finns både i canonical och i engelska publika output. Svenska output har
i regel samma värden. Befintlig språkhantering översätter huvudsakligen kolumnnamn.
Det är det nuvarande, uttryckligen testade kontraktet; den efterfrågade
värdenormaliseringen behöver därför införas som en separat, granskad förändring.

De berörda semantiska fälten är `count_stage`, `geographic_level`,
`district_type`, `comparison_status`, `sex`, `ballot_status`, `consent`,
`candidate_declaration`, `election_basis` och delar av `election_kind`.
Därtill finns svenska aggregatetiketter i `party_designation`, äldre
källbeteckningar i `election_event` och svenska privata canonical-nycklar.
De tre senare fallen kräver annan hantering än vanlig enum-översättning.

Flera boolean-konverteringar fungerar redan. Folkomröstningens `Ja`, `Nej` och
`Blank` är officiella alternativnamn, inte booleaner. De ska inte konverteras till
TRUE/FALSE. Blank är ett giltigt alternativ; ogiltiga röster hålls separat.

## Genomförd täckning

Samtliga 21 exporterade funktionsnamn i aktuell `NAMESPACE` finns representerade i kontrollen: sju huvudfunktioner med svenska motsvarigheter, tre mandatperiodsfunktioner med svenska motsvarigheter och `election_events()`. Canonical-prototyper valdes uttryckligen via respektive manifest; detta godkänner inte automatisk användning och EU:s `auto_eligible` ligger kvar oförändrat.

- Samtliga 214 Parquet-filer i de utvalda 13 manifestgenerationerna lästes och
  deras asset-checksummor verifierades. De omfattar RKL 2002, 2006, 2010, 2014,
  2018 och 2022 för RD/RF/KF; folkomröstningen 2003; EU 2004, 2009, 2014, 2019
  och 2024. Både den publicerade och den korrigerade lokala 2018-generationen
  granskades. Det är 12 olika familj-år-produkter, med två generationer för 2018.
- Alla character- och logical-kolumner inventerades: 5 210 asset-kolumnprofiler.
  Tekniska kategorifälts hela observerade domän sparades. Namn och identifierare
  med stor domän profilerades separat från enum-fält; samtliga partibeteckningar
  och referendumalternativ lästes dessutom i en särskild fullständig genomgång
  av 154 asset-kolumner. Numeriska 0/1-domäner kontrollerades separat.
- 952 faktiska publika canonical-anrop genomfördes. De täcker de sju vyerna
  `results`, `seats`, `candidacies`, `candidates`, `elected`, `substitutes` och
  `preference_votes` där de stöds, båda språkens riktiga wrapperfunktioner och
  `standard`/`full`. Folkomröstningen har endast den relevanta resultatvyn;
  2002 saknar ett stött komplett `candidacies()`-anrop. Detta är inte sju
  påhittade referendumvyer eller ett påstående om en komplett kandidaturpopulation.
- Resultatens standardval och distriktsnivå provades för varje RD/RF/KF-år;
  EU:s län/kommun/kommunvalkrets/distrikt och folkomröstningens län/kommun/distrikt
  provades också. Tillgänglig canonical-preliminär provades för RKL 2010, 2014,
  2022 och EU 2019, 2024; även preliminära mandat 2022. Alla övriga lagrade
  geografier omfattas av den fullständiga fysiska asset-genomgången.
  Detta är inte en körning av varje tänkbar kombination av filterargument.
- `mandate_history`/`mandathistorik`, `members_at`/`ledamoter_vid` och
  `vacant_seats_at`/`tomma_stolar_vid` granskades för 2014, 2018 och 2022 med
  samtliga tre valtyper. Full-output hämtades via båda riktiga språkfunktionerna;
  båda detaljnivåerna kontrollerades via samma produktionspresentation.
- `election_events()`, alla fem omvalens resultat och mandat, samt sammansatta
  mandat efter omval ingår. Omvalen är Orsa 2003, Västra Götaland och Örebro
  2011, Båstad 2015 och Falun 2019. Historik och omval använder sina stödda
  lokala källor; de framställs inte som färdiga canonical-assets.
- 2026:s rådataväg granskades separat med bevarade källor. För dyra råanrop
  lästes full-output en gång; engelska/svenska och standard/full producerades
  sedan med de riktiga gemensamma presentationsfunktionerna. Exakta lyckade
  urval och källstopp anges i kontrollbilagan nedan.

Bevismaterial och R-skript finns lokalt under
`.local-data/categorical-values-audit-20261020/`. Bland annat finns
`assets.csv`, `canonical-profiles.csv`, `public-requests.csv`,
`public-canonical-profiles.csv`, `raw2026-detail-requests.csv`,
`extras-profiles.csv` och `designation-domains.rds`.
Ingen råkälla eller genererad data läggs till i Git genom denna rapport.

## Semantiska kategorier: nuvarande och föreslagna värden

I tabellen avser ”nu” observerade, icke-saknade värden. Att ett historiskt schema
har ett fält med enbart typat NA räknas inte som ett observerat svenskt värde.
Föreslagna engelska token är stabila kategorier, inte ändrade valuppgifter.

| Fält (svenskt kolumnnamn) | Nu i canonical/English API | Föreslaget canonical/English API | Föreslaget Swedish API |
| --- | --- | --- | --- |
| `count_stage` (`rakningstillfalle`) | `slutlig`, `preliminar` | `final`, `preliminary` | `slutlig`, `preliminar` |
| `geographic_level` (`geografiniva`) | Nio svenska nivåtoken; se nedan | Befintliga engelska API-nivåtoken | Befintliga svenska nivåtoken |
| `district_type` (`valdistriktstyp`) | `valdistrikt`, `uppsamlingsdistrikt`, `ordinary`, `wednesday` | `ordinary`, `collection`, `wednesday` | `valdistrikt`, `uppsamlingsdistrikt`, `onsdagsdistrikt` |
| `sex` (`kon`) | `Man`, `Kvinna`, `M`, `K` | `male`, `female` | `man`, `kvinna` |
| `ballot_status` (`valsedelsstatus`) | `Definitiv`, `Utkast`, `S`, `B` | `final`, `draft`; behåll neutrala källkoder `S`/`B` tills deras separata domän dokumenterats | `definitiv`, `utkast`; källkoder oförändrade |
| `consent` (`samtycke`) | `ja`, `nej`, `irrelevant` | Logical-värde och separat tillämplighet, alternativt trevärdesenum; se nedan | Samma logical-värde, alternativt `ja`/`nej`/`ej_tillampligt` |
| `candidate_declaration` (`forklaring`) | `ja`, `nej`, `irrelevant` | Samma princip som `consent` | Samma princip som `consent` |
| `comparison_status` (`status_jamforelse`) | Åtta svenska statusvärden; se nedan | Åtta separata engelska token | Svenska motsvarigheter, med bibehållna skillnader |
| `election_basis` (`valgrund_text`) | Sex svenska förklaringar; se nedan | Sex separata engelska token | Svenska förklaringar/kategorier |
| `election_kind` (`valklass`) | Källdata kan ge `ordinarie val` eller tom sträng; andra API-vägar ger redan `ordinary`, `re_election` | `ordinary`, `re_election` där eventmetadata fastställer klass | `ordinarie`, `omval` |

### Nivåer

Återanvänd den redan etablerade argumentordlistan i stället för att uppfinna nya
nivånamn för output:

| Nuvarande token | Canonical/English | Swedish |
| --- | --- | --- |
| `riket` | `national` | `riket` |
| `lan` | `county` | `lan` |
| `region` | `region` | `region` |
| `regionvalkrets` | `regional_constituency` | `regionvalkrets` |
| `riksdagsvalkrets` | `parliamentary_constituency` | `riksdagsvalkrets` |
| `kommun` | `municipality` | `kommun` |
| `kommunvalkrets` | `municipal_constituency` | `kommunvalkrets` |
| `valdistrikt` | `district` | `valdistrikt` |
| `personvalsomrade` | `preference_vote_area` | `personvalsomrade` |

`ballot_status` kräver också en källspecifik ordlista: `Definitiv`/`Utkast` får inte automatiskt likställas med `S`/`B`, kandidaturens giltighet eller en räknings slutlighet. De är skilda källbegrepp.

`district_type` behöver källfamiljens betydelse: en onsdagsenhet är inte
utan vidare identisk med varje annan typ av uppsamlingsenhet. Ingen geografisk
omklassificering eller sammanslagning föreslås genom språkbytet.

### Jämförelsestatus

| Observerat värde | Föreslaget engelskt token |
| --- | --- |
| `Kan jämföras` | `comparable` |
| `Ej jämförbart` | `not_comparable` |
| `Jämförs mot summerat` | `compared_with_aggregate` |
| `Summerad` | `aggregated` |
| `Ny` | `new` |
| `Modifierad` | `modified` |
| `ej jämförbar: Ny` | `not_comparable_new` |
| `ej jämförbar: Modifierad` | `not_comparable_modified` |

De åtta kategorierna får inte reduceras till en enda jämförbar-boolean;
informationen om summering, nyhet och ändring ska bevaras.

### Valgrund

| Observerat värde | Föreslaget engelskt token |
| --- | --- |
| Ledamoten är vald på jämförelsetal | `comparison_number` |
| Ledamoten är vald på personröster | `preference_votes` |
| Ledamoten är vald som listtrogen efterträdare till dubbelvalsavvecklad | `list_successor_after_dual_election` |
| Ledamoten är vald på personröster som efterträdare till dubbelvalsavvecklad | `preference_vote_successor_after_dual_election` |
| Ersättaren är utsedd listtroget | `list_substitute` |
| Ersättaren är vald på personröster | `preference_vote_substitute` |

`election_basis_id` bevaras som källidentifierare. De observerade koderna
`P`, `J`, `E`, `PE`, `1`, `2`, `5`, `6`, `10`, `11` får inte globalt
likställas mellan år eller källformat bara för att förklaringarna liknar varandra.

### Consent/declaration: inte en enkel ja/nej-flagga

Dessa fält innehåller också uttrycklig icke-tillämplighet. Rekommendationen om
riktiga logical-värden behöver därför kompletteras för att undvika informationsförlust:

| Nuvarande källa/normalisering | Föreslaget logical-värde | Separat `*_applicable` |
| --- | --- | --- |
| `J` / `ja` | TRUE | TRUE |
| `N` / `nej` | FALSE | TRUE |
| `I` / `irrelevant` | NA | FALSE |
| Saknat | NA | NA |

Detta är ett förslag till schemaändring som kräver beslut. Om antalet kolumner
ska förbli oförändrat är ett uttryckligt enum `yes`, `no`, `not_applicable`
ett förlustfritt alternativ. Konvertera inte `irrelevant` till FALSE och använd
inte numeriska 1/0. Fyll inte historiskt saknad uppgift med ”ej tillämpligt”.

### Var värdena faktiskt förekommer

| Fält | Produkter med observerade värden | Detaljnivå i kontrollerade publika output |
| --- | --- | --- |
| `count_stage`, `geographic_level` | Alla undersökta valfamiljer/år, även omval och 2026-råvägen | `standard` och `full` |
| `district_type` | Alla canonical-år har en observerad typ på relevant geografi | Vanligen `full`; folkomröstning även `standard` |
| `comparison_status` | RKL 2002–2018, EU 2009–2024, omval och 2026-råoutput; RKL 2022/EU 2004 har här typat saknat fält | `standard` och `full` där det ingår |
| `sex` | RKL 2006–2022, samtliga EU-år, 2026; RKL 2002 har här saknade värden | `standard` och `full` beroende på vy |
| `ballot_status` | RKL 2006–2022, samtliga EU-år, 2026 | `full` |
| `consent`, `candidate_declaration` | RKL 2018/2022, EU 2019/2024, 2026; tidigare scheman har saknade värden | `full` |
| `election_basis` | Observerad svensk förklaring i RKL 2022, EU 2024 och 2026 | `standard` och `full`; andra år kan ha källkod men sakna förklaring |
| Källans `election_kind` | RKL 2022, EU 2024 och 2026 | `full`; omval/historik/eventmetadata använder redan engelska klasser |

Standard är en projektion av full. Ett fält som inte finns i standard ska inte
beskrivas som felöversatt där; exempelvis ligger samtycke/deklaration i full.

## Booleaner som redan är korrekta

De befintliga parserfunktionerna konverterar uttryckliga flaggor till logical.
Auditten körde särskilda små tester av de riktiga parserfunktionerna utöver
fullständig testsvit och data-domängranskningen:

- `parse_kandidaturer_2026()`: `J`/`N` blir TRUE/FALSE för
  `candidates_registered`; samma konverterare används för `valid`.
  Samtycke/deklaration använder medvetet en annan trevärdeskonverterare.
- `parse_rostfordelning_mandat_2026()`: källans `Ja`/`Nej` blir TRUE/FALSE för
  `above_threshold`. Saknat explicit besked förblir NA.
- 2006 års kandidatadapter gör redan `Ja`/`Nej` till logical för
  `candidates_registered`; EU 2004/2009 har motsvarande uttrycklig flaggläsning.
- `is_test`, `counted`, `other_parties`, `elected`,
  `qualified_by_preference_votes`, `open_list`, `on_name_ballot`, `name_varies`,
  `multiple_lists`, `multiple_parties`, `multiple_election_types`,
  `multiple_electoral_areas`, `multiple_constituencies`, `is_blank_option` och
  relevanta tillgänglighets-/fullständighetsflaggor är redan logical i de
  undersökta output där de finns.

Den separata genomgången av samtliga numeriska asset-kolumner hittade endast åtta fält med en icke-tom 0/1-domän: `constituencies_count`, `election_types_count`, `electoral_areas_count`, `lists_count`, `name_variants_count`, `parties_count`, `preference_vote_areas_count` och `unfilled_seats`. Dessa är antal, inte felkodade booleaner.

TRUE/FALSE ska vara samma R-värden i båda språkgränssnitten. De ska inte
översättas till textsträngarna ”Sant/Falskt”. Antal, mandat, ordningsnummer,
källkoder och andelar som råkar anta 0 eller 1 är inte därför booleaner.

## Redan engelska kategorier: bevara semantik, lokalisera bara presentation

Mandatperiodsfunktionernas `status` ger `occupied`/`vacant` i granskade data.
`source_kind` ger `current`, `departures`, `allocation`, `original_election`,
`history`. Observerade datumgrunder är:

- `start_date_basis`: `reported`, `original_elected_match`,
  `original_unfilled_allocation`,
  `departure_without_successor_verified_vacancy_control`;
- `end_date_basis`: `reported`, `re_election_replacement`.

Dessa behöver inte förengelskas. Svenska funktioner behåller i dag samma token;
en framtida svensk värdepresentation kan ge exempelvis `besatt`/`vakant`,
`kallrapporterat`, `matchat_ursprungligt_vald`, `ursprungligen_otillsatt`,
`verifierad_vakans_efter_avgang` och `ersatt_genom_omval`, med en uttrycklig
ett-till-ett-ordlista. För `source_kind` kan motsvarigheterna vara
`nuvarande`, `avgangar`, `mandatfordelning`, `ursprungligt_val`, `historik`.

Eventregistrets `ordinary`/`re_election`, `scope_level` och omvalens
`event_scope_level` är redan engelska. Post-omvalets `after_re_election` är en
sammansättningskategori, inte en flagga som ska bli TRUE/FALSE.
För `scope_level`, `event_scope_level` och `component_geographic_level` rekommenderas samma svenska presentationsordlista som för `geographic_level`, medan canonical/English behåller de redan engelska nivåerna. `composition_type = after_re_election` kan visas som `efter_omval` på svenska. Källstammar, period-ID:n och event-ID:n är identifierare, inte svenska enumfel. Eventregistrets `electoral_roll_basis` är redan en engelsk metadataförklaring; den behöver ingen teknisk omkodning men kan få separat svensk presentation.

## Namn, alternativ och uttrycklig källproveniens

### Ska inte maskinöversättas

Partinamn, partiförkortningar, kandidatnamn, kommun-/län-/region-/distriktsnamn,
valsedelsuppgifter, valsedelskretsbeteckningar och den officiella
folkomröstningsfrågan bevaras som publicerade namn/texter.

`voting_option_name` har exakt `Ja`, `Nej`, `Blank` i folkomröstningen 2003.
Det är korrekta svenska alternativbeteckningar även i engelska data, med
separat alternativkod och `is_blank_option`. `voting_option_code` innehåller de officiella källidentifierarna `JA`, `NEJ`, `BLANK`, direkt från XML:s alternativregister. Rekommendationen är att behålla dessa identifierare som källkoder; engelska etiketter är en separat presentation. De ska varken bli booleaner eller bytas genom generell strängöversättning. Om engelska visningsetiketter
önskas ska `Yes`, `No`, `Blank` vara en uttrycklig presentationsetikett med
originalnamnet bevarat. Varken alternativens röster eller Blank får behandlas
som booleaner eller ogiltiga röster.

`source_node_type` har originaltaggarna `NATION`, `LÄN`, `KRETS_RIKSDAG`,
`KOMMUN`, `KRETS_KOMMUN`, `VALDISTRIKT`, `ONSDAGSDISTRIKT`.
Dessa ska behållas ordagrant eftersom fältet uttryckligen anger källans XML-tag.
Den normaliserade nivån ligger separat i `geographic_level`.

`election_code`, `party_code`, `candidate_number`, `list_number`,
`election_basis_id`, `substitute_group` och geografiska koder är käll-/nyckelvärden.
Exempelvis `RD`, `RF`, `KF`, `E`, `F`, `K` i en källkod och numeriska grupp-ID:n
ska inte träffas av någon generell översättningsregel.

Den särskilda platshållarkontrollen av alla character-kolumner hittade inga bevarade `Namnet gallrat`, `Personuppgift borttagen` eller `Kunde ej utses` som textvärden i de kontrollerade canonical-filerna. Däremot förekommer `NEJ` i EU 2009 och `Nej`, `NEJ`, `JA`, `Giltig` i EU 2014:s `source_party_designation`. Dessa är ordagranna källbeteckningar i de särskilda beteckningstabellerna, inte booleaner eller instruktioner att klassificera observationen som giltig. De ska bevaras. Detta visar konkret varför omkodning måste vara fält- och kontextbunden.

### Aggregatetiketter är inte verkliga partinamn

Den fullständiga beteckningsgenomgången identifierade `Övriga partier` och
`Handskrivna röster` som svenska syntetiska resultatetiketter. De ska skiljas
från verkliga svenska partibeteckningar.

Förslag: stabil kategori `other_parties` respektive
`handwritten_votes_unreported_party`, engelska visningsetiketter
`Other parties` respektive `Handwritten votes (party designation unreported)`
och svenska motsvarigheter, med ursprunglig källbeteckning bevarad.
`other_parties` finns redan som logical-flagga; använd den verifierade kontexten
för kategorisering i stället för textmatchning över godtyckliga partinamn.
Ingen ny partifördelning får härledas. Detta ändrar inte EU 2004:s 943 röster,
EU 2014:s tio Vårdsbergröster eller någon annan redovisad källa.

### Eventbeteckningar och privata canonical-nycklar

`election_event` innehåller äldre former som `Val_2018`, `2018`,
`EU-val_2014` och folkomröstningens fullständiga titel, medan eventfunktionerna
använder `SE-...`-identifierare. Detta är en separat ID-/metadatakonsekvensfråga,
inte en uppmaning att översätta eller ersätta identifierare globalt.
Vid framtida normalisering bör befintligt eventregister vara referens och
källans eventbeteckning bevaras separat. Tom klass får inte gissas.

Fysiska canonical-filer innehåller privata diskriminatorer:

| Fält | Observerade värden | Bedömning |
| --- | --- | --- |
| `.component` | `geo`, `parti`, `lista`, `roster`, `listroster`, `omraden`, `officiella`, `metadata`, `population_kandidat`, `population_lista`, `population_alla` | Interna lagrings-/läsarnycklar. Om de ska förengelskas krävs koordinerad export/läsarversion; de är inte publika statusetiketter. |
| `.table` | Svenska geografinivåer, `RD`, `RF`, `KF`, `votes`, `lists`, `parties`, `context`, `qualified` | Samma princip: struktur och nycklar, inte vanlig språkpresentation. |
| `.person_view` | `FALSE`, `TRUE`, `FALSE__FALSE`, `TRUE__FALSE`, `FALSE__TRUE`, `TRUE__TRUE` | Sammansatt serialiserad vy-nyckel, inte en feltypad offentlig boolean. |
| `.source_area` | Geografiska koder | Identifierare; behåll. |

Om även interna nycklar ska förengelskas är ett konkret förslag för `.component`: `geo` → `geography`, `parti` → `party`, `lista` → `list`, `roster` → `votes`, `listroster` → `list_votes`, `omraden` → `areas`, `officiella` → `official`, `metadata` → `metadata`, `population_kandidat` → `candidate_population`, `population_lista` → `list_population`, `population_alla` → `all_population`. För `.table` kan nivåordlistan ovan återanvändas; de redan neutrala/engelska token behålls. Detta är en koordinerad lagringsversionsändring, inte en ändring som enbart ska göras vid visning.

Privata nycklar kan alternativt behållas i en dokumenterad intern lagringsspecifikation.
Kravet på engelska semantiska canonical-värden behöver inte översättas till
ett riskabelt globalt byte av alla svenska strängar i lagringsprotokollet.

## Befintlig översättning och rekommenderad nästa ändring

`R/output_names.R`, `.public_output_names()`, `.canonical_names_en()` och
`.canonical_names_sv()` översätter kolumnnamn, inte värden.
`R/api_english.R` har redan ordlistor för argumentvärden; de gör inte
motsvarande omkodning av output. `.mh_present()` byter historikkolumnernas namn
men behåller kategorier. Testet ”canonical schema translates shared and
base-only names without values” bekräftar nuvarande kontrakt.

Föreslagen senare implementation, efter godkännande:

1. En gemensam fältbunden värdeordlista för normaliserade semantiska fält.
   Inga globala ersättningar av `Ja`, `Nej`, `K`, partinamn eller XML-taggar.
2. Engelska enumvärden i en versionsmärkt canonical-export. Läsaren måste
   hantera gamla och nya scheman utan att filtrering/joinar mot dagens svenska
   internvärden går sönder. Publicerade historiska assets skrivs inte över.
3. Svensk presentation med samma betydelse och explicit ordlista. Logical
   behålls som logical i båda språken; källfält bevaras ordagrant.
4. Beslut om de två tillämplighetskolumnerna för samtycke/deklaration innan
   eventuell schemaändring. Beslut om eventmetadata hålls separat.
5. Domäntester per fält/år/familj, typade NA, false kontra saknat kontra
   ej tillämpligt, oförändrade namn/källkoder, Blank som giltigt alternativ,
   standard/full-projektion, språkekvivalens och äldre canonical-läsning.

Ingen av dessa produktionsändringar har gjorts i denna audit.

## Testresultat och avgränsningar

Hela befintliga testsviten: **4 539 godkända, 16 explicita skips,
0 fel, 0 varningar**. Skips omfattar konfigurationsberoende externa
integrationstester; de ersätts inte med påståenden om genomförd livekontroll.
De 952 canonical-anropen passerade och gav identiska värden mellan språken
när kolumnnamnen jämställdes. Det bevisar dagens beteende, inte att ett framtida
engelskt enumkontrakt redan är uppfyllt.

Nätverksmaterial uppdaterades inte i denna audit. Ingen canonical-rebuild eller
ny publicering gjordes. `auto_eligible` ändrades inte. Ingen commit eller push.
`R CMD check` kördes inte på nytt för denna dokumentations-/läsningsaudit;
användaren begärde ingen ny paketbyggnad och produktionskod ändrades inte.

## Kontrollbilaga: 2026 och oförändrat material

Rågranskningen använde en separat kopia av bevarade 2026-källor: 294 filer från det bevarade valideringsarkivet och 52 från den aktuella lokala källroten, där de senare fick företräde i auditkopian. Ursprungliga arkiv ändrades inte. Det är en dokumenterad lokal granskningskonfiguration, inte en ny publicerad källversion.

| Funktion / urval | Kontrollerade full-output-rader | Resultat |
| --- | ---: | --- |
| `candidacies`, RD/RF/KF | 178 693 | OK |
| `seats`, RD/RF/KF | 3 471 | OK |
| `elected`, RD | 349 | OK |
| `elected`, RF | 1 720 | OK |
| `elected`, KF | — | EJ VERIFIERAD: befintlig områdes-/partivalidering stoppar |
| `substitutes`, RD | 1 351 | OK |
| `substitutes`, RF | 15 183 | OK |
| `substitutes`, KF | 61 717 | OK |
| `candidates`, RD | 6 326 | OK |
| `candidates`, RF | 12 855 | OK |
| `candidates`, KF | 52 395 | OK |
| `preference_votes`, RD | 31 820 | OK |
| `preference_votes`, RF | 58 354 | OK |
| `preference_votes`, KF | 63 363 | OK |
| `results`, RD-district | 95 759 | OK |
| `results`, RD-preliminary | — | EJ VERIFIERAD: preliminär ZIP saknas i auditens lokala arkiv |
| `results`, RF-district | 85 426 | OK |
| `results`, RF-preliminary | 3 228 | OK |
| `results`, KF-district | 84 764 | OK |
| `results`, KF-preliminary | — | EJ VERIFIERAD: preliminär ZIP saknas i auditens lokala arkiv |

För varje lyckad full-läsning profilerades båda språken och båda detaljnivåerna via produktionspresentationen. Detta räknas inte som fyra separata råinläsningar.

Stoppet för `elected(KF, 2026)` inträffar vid `s/kf/Val_2026_slutlig_0128_KF.zip` (Salem). Den aktuella joinen tar med kandidatnummer `53411`, parti `0005`, med kandidatur i område `0120`; områdets partirad söks därefter i mandatfilen för `0128`. Filens nycklar gäller `0128`. Detta förklarar det omedelbara valideringsstoppet, men auditten avgör inte här om den bakomliggande orsaken är kandidatur-scope, identitetsfråga eller snapshotkombination. Ingen kandidatidentitet har harmoniserats och kontrollen har inte kringgåtts. KF-elected 2026 ska därför inte beskrivas som genomkörd; motsvarande historiska canonical-vyer är kontrollerade. Se `kf-source-stop.log` för exakta nycklar.

Preliminära råresultat för RD och KF 2026 kunde inte granskas i denna lokala konfiguration: `p/rd/Val_2026_preliminar_00_RD.zip` respektive `p/kf/Val_2026_preliminar_0114_KF.zip` saknas där. Stoppet i första KF-filen är inte en fullständig inventering av alla saknade KF-filer och säger inte att Valmyndigheten saknar dem. RF-preliminär kunde däremot köras. Preliminära kategorivärden granskades dessutom genom de stödda canonical-år som räknas upp ovan. 2018-canonical saknar stödd preliminär asset i den granskade generationen; dess stage-guard får inte ersätta begäran med slutligt resultat.

Integritetskontroll: **350 befintliga versionshanterade/icke-ignorerade filer** hade oförändrad SHA256 jämfört med auditens start. **1300 skyddade canonical-assets och manifest** hade också oförändrad SHA256. Den enda nya icke-ignorerade auditfilen är denna rapport; R-skript, profiler och kontrolloutput ligger lokalt under den ignorerade auditkatalogen. Den tidigare ocommittade arbetskopian har lämnats orörd.
