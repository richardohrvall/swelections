> Teknisk uppföljning 21 oktober: funktionsspärren är implementerad och verifierad;
> inga aktiveringsflaggor eller canonical-assets ändras. Ursprunglig inventering
> och den senare implementationen skiljs åt nedan.

# Slutlig aktiveringsinventering för första canonical-releasen

Datum: 21 oktober 2026. **Beslutsunderlag, inte aktivering.** Ingen kod, data,
registrering, manifestfil eller flagga ändras. Endast denna rapport skapas.

## Rekommendation och underlag

Rekommendera automatisk användning av **tolv avgränsade produkter, 188 Parquet-assets**,
efter commit, ren rebuild, slutvalidering och beslut om distribution. Innehållsmässigt
redo betyder här den uttryckligen godkända källpopulationen och de stödda vyerna,
inte att samtliga tänkbara historiska uppgifter eller personlänkningar finns.

- RKL 2002/2006/2010/2014/2018/2022: 121 assets gemensamt för RD/RF/KF.
- Folkomröstning 2003: en asset, endast resultat.
- EU 2004/2009/2014/2019/2024: 66 assets, varav endast åtta från EU 2009.
- Sex EU 2009-personröstbaser hålls utanför; den lokala 194-asset-samlingen
  förändras inte av denna föreslagna avgränsning.

Kontrollerat mot aktuella manifest, releaseinventeringen och readiness-rapporterna.
EU 2009:s åtta-asset-manifest filtrerades **endast i minnet** för kontrollen.
De befintliga manifestens funktions-/resultatnivåer och räkningsstadier kontrollerades.
Samtliga tolv aktuella generationer har schema 3, value/storage contract 1/1 och
sanningsenligt `build_tree_dirty = true`. Alla 206 aktuella canonical-filer/manifest
matchar de registrerade checksummorna; hela täckningsregistreringen är oförändrad.

Underlag, i aktualitetsordning:

1. Användarens principgodkännande av EU 2009-alternativ C och det efterföljande
   beslutet att `auto` aldrig väljer användarens lokala råfiler.
2. [Source-selection, reviderad policy och verifiering](SOURCE_SELECTION_DESIGN.md).
3. [EU 2009:s åtta publicerbara och sex tillbakahållna assets](EU_2009_RELEASE_DECISION.md).
4. [Releaseinventeringen](CANONICAL_RELEASE_READINESS.md),
   [produkterna](CANONICAL_RELEASE_PRODUCTS.csv),
   [EU-readiness](CANONICAL_READINESS_EU.md) och
   [RKL/folkomröstnings-readiness](CANONICAL_READINESS_RKL_FOLKOMR.md).

Äldre rekommendationer om att hålla hela EU 2009 utanför eller behålla dess
årsgate stängd även för godkända funktioner ersätts av det senare C-beslutet.
CSV-inventeringens 194 fysiska prototypfiler är däremot fortfarande korrekt;
CSV-filerna har inte skrivits om till ett faktiskt publiceringsmanifest.

## Funktioner och tabellsemantik

- **G7** = `results`, `seats`, `candidacies`, `candidates`, `elected`,
  `substitutes`, `preference_votes`.
- **H6** = G7 utan `candidacies` (RKL 2002).
- **E6** = G7 utan `preference_votes` (EU 2009).
- **R** = endast `results` (folkomröstning).
- **F** = final. **P** = preliminary. Endast resultat/mandat har de angivna
  räkningsstegsvyerna; kandidat-/relationsvyer avser det fasta slutresultatet.

Alla funktionsnamn omfattar motsvarande svenska API samt standard/full och
svenska/engelska presentationer. `candidates` omfattar båda dokumenterade lägena
med/utan resultatberikning. Godkännandet gäller deklarerade geografier och
stödda varianter; en flagga gör inte en ostödd variant tillgänglig.

Kolumnen **auto remote** anger automatisk källa efter den föreslagna aktiveringen,
inte om explicit `source = "remote"` också stöds. För de godkända canonical-vyerna
väljer `auto` canonical och därför ingen remote. Ett canonical-integritetsfel får
inte tyst utlösa remote-fallback. `—` i local-kolumnen betyder att ingen godkänd
vy kräver användararkiv; användaren kan fortfarande uttryckligen välja stödd `local`.

**Ja i flaggkolumnen är en rekommendation för releasen efter leveranskontrollerna,
inte ett konstaterande att flaggan kan slås på redan nu.**

## Valfamilj × år: föreslagen aktivering

| Valfamilj | År | Canonical-täckning | Godkända funktioner | auto_eligible vid release | auto canonical | auto remote | Kräver explicit local | Specificerad begränsning |
|---|---:|---|---|---|---|---|---|---|
| RD | 2002 | F; del av 14 gemensamma assets | H6 | Ja | H6 | — | — | Inget komplett kandidaturregister; nio supplementceller ej offentliggjorda, småpartiers lägre uppdelning saknas delvis; 41 523 personröster endast aggregat; separat kontroll +547. |
| RF | 2002 | F; samma produkt | H6 | Ja | H6 | — | — | Inget komplett kandidaturregister; personröstlistvyer avvisas vid källkonflikterna, inte lösta genom local; 13 542 aggregatröster; separat kontroll +28. |
| KF | 2002 | F; samma produkt | H6 | Ja | H6 | — | — | Inget komplett kandidaturregister; personröstlistvyer avvisas; 8 675 aggregatröster; tre obesatta mandat särredovisas. |
| RD | 2006 | F; del av 15 gemensamma assets | G7 | Ja | G7 | — | — | +4 089 personröster i fem kretsar mot separat statistik; godkänd detaljerad källpopulation, ingen justering eller personinferens. |
| RF | 2006 | F; samma produkt | G7 | Ja | G7 | — | — | SCB:s wide-valideringstabell innehåller 102 dubbletter; käll-/kandidatobservationer är inte verifierade personer. |
| KF | 2006 | F; samma produkt | G7 | Ja | G7 | — | — | 38 personrösters skillnad mot separat statistiksida; tre parti/kommun-kombinationer saknar numerisk kod; 14 obesatta mandat. |
| RD | 2010 | R P/F, S F; del av 24 gemensamma assets | G7 | Ja | G7 | — | — | 171 kandidatberikningar NA; endast uttryckligen godkända identitetsregler. |
| RF | 2010 | R P/F, S F; samma produkt | G7 | Ja | G7 | — | — | Nio helt orapporterade preliminära uppsamlingsenheter behålls med NA; 53 kandidatberikningar NA. |
| KF | 2010 | R P/F, S F; samma produkt | G7 | Ja | G7 | — | — | Nio helt orapporterade preliminära uppsamlingsenheter; tio kandidatberikningar NA; fyra resultat-/medlems-ID-konflikter. |
| RD | 2014 | R P/F, S F; del av 24 gemensamma assets | G7 | Ja | G7 | — | — | 126 kandidatberikningar NA; +1 mot SCB:s annorlunda kandidatpopulation. |
| RF | 2014 | R P/F, S F; samma produkt | G7 | Ja | G7 | — | — | 113 kandidatberikningar NA; −18 mot SCB:s population. |
| KF | 2014 | R P/F, S F; samma produkt | G7 | Ja | G7 | — | — | 40 kandidatberikningar NA; −177 mot SCB; personröstskillnad +394 lokaliserad till Båstad/snapshots; 17 initiala vakanser. |
| RD | 2018 | F; del av 20 rättade gemensamma assets | G7 | Ja, behåll | G7 | — | — | Ingen stödd preliminär vy; 321 uppsamlingsenheter saknar uttryckliga invalid/total-fält. |
| RF | 2018 | F; samma produkt | G7 | Ja, behåll | G7 | — | — | Ingen stödd preliminär vy; 320 uppsamlingsenheter saknar uttryckliga invalid/total-fält. |
| KF | 2018 | F; Ragunda-rättad generation | G7 | Ja, behåll | G7 | — | — | Häggkvist 534885 från 2018-09-09; rättelsedatum 2018-12-12. Fem Stugubyn-rösters listfördelning ej belagd. 321 uppsamlingsenheter saknar invalid/total-fält. |
| RD | 2022 | R/S P/F; del av 24 gemensamma assets | G7 | Ja | G7 | — | — | 14 kandidat–kretskombinationer/15 personröster skiljer mellan områdes- och distriktskälla; källvärden bevaras. |
| RF | 2022 | R/S P/F; samma produkt | G7 | Ja | G7 | — | — | Dokumenterad Norrbotten-rekonstruktion och redan godkänd, avgränsad Bo Larsson-regel; ingen mandatperiodshistorik i fasta resultatet. |
| KF | 2022 | R/S P/F; samma produkt | G7 | Ja | G7 | — | — | Korrigerade kandidatberikningar; okända nämnare förblir NA. |
| EU | 2004 | F; 14 assets | G7 | Ja | G7 | — | — | 943 giltiga handskrivna röster enbart aggregat; nycklar avser listpositioner. Korrekt SD-kontroll används trots SCB-tabellens felaktiga nollor. |
| EU | 2009 | F; åtta av 14 befintliga assets | E6 | Ja, endast E6 | E6 | — | preference_votes, alla sex nivåer | 114 småpartikandidaturer saknar resultatberikning; P hålls utanför på grund av 34/91/102-frågorna, se nedan. |
| EU | 2014 | F; 14 assets | G7 | Ja | G7 | — | — | Tio giltiga handskrivna Vårdsberg-röster har orapporterad partibeteckning; en explicit nollkategori saknar numerisk kod. |
| EU | 2019 | R/S P/F; 15 assets | G7 | Ja | G7 | — | — | Preliminärt tio särredovisade partier + övrigaggregat; 7 455 röster för ogiltiga kandidat–partirelationer finns i P men inte i giltig kandidatpopulation. |
| EU | 2024 | R/S P/F; 15 assets | G7 | Ja | G7 | — | — | Kandidat 1203 endast i tidig snapshot; final population följer senare källa. 2 324 röster för fem ogiltiga relationer finns i P. |
| Folkomröstning | 2003 | R F; en asset, sex geografiska nivåer | R | Ja | R | — | — | yes/no/blank är giltiga alternativ; invalid separat. Väljarsammansättning endast nation/län; inga nämnare på 396 onsdagsenheter. Övriga sex funktioner är inte tillämpliga. |

RKL-årens assetantal är gemensamma för RD/RF/KF och ska inte räknas tre gånger.
Tabellen har 24 familj×år-rader men bara tolv registrerade canonical-produkter.

### Geografier, stadier och gemensamma avgränsningar

- RKL 2002–2018: RD har sex resultatnivåer (distrikt, kommun, kommunvalkrets,
  län, riksdagsvalkrets, riket), RF sex (distrikt, kommun, kommunvalkrets,
  regionvalkrets, region, riket), KF fem (distrikt, kommun, kommunvalkrets, län,
  riket). Personröster följer områdes-/distriktsvyerna och respektive listrestriktion.
- RKL 2022: RD distrikt/riksdagsvalkrets/riket, RF distrikt/regionvalkrets/region,
  KF distrikt/kommunvalkrets/kommun. Mandat stöder respektive två
  icke-distriktsnivåer. Källans uttryckliga `total_votes` saknas på
  29/53/41 kretsnivåer i båda stadierna; saknade fält är inte saknade partiröster.
- EU: resultat nation/län/kommun/verklig kommunvalkrets/distrikt; mandat
  nationellt. P har sex deklarerade nivåer för de godkända åren, inte EU 2009.
  Kommunvalkretsar i delade kommuner är inte en extra nationellt uttömmande
  population. 2009 års senare 18→20 och 2019 års senare 20→21 är inte ursprungliga
  mandatresultat.
- Folkomröstning: riket/län/riksdagsvalkrets/kommun/verklig kommunvalkrets/distrikt.
- RKL 2002/2006/2018 och EU 2004/2009/2014 har ingen godkänd komplett preliminär
  canonical-vy. Inte heller raw ska presentera final eller valnatt som denna vy.
  Ingen automatisk källa ska väljas för en ostödd begäran.
- RKL 2010:s 722 partiellt rapporterade preliminära sidor och 4 213 tomma
  kategoriantal bevaras. De 18 helt orapporterade enheterna är en
  rapporteringssnapshot, inte en felaktig slutresultatrekonstruktion.
- Kandidat-ID/källnycklar är inte longitudinella person-ID:n. RKL 2002 saknar ett
  komplett valsedelskandidaturregister; detta gör inte dess rapporterade
  kandidat-/personröstobservationer otillgängliga. EU 2009 har båda Per Johansson-
  kandidaturerna men saknar verifierad resultatallokering.

## Fall utan canonical i releasen och begäranden som inte ska aktiveras

| Familj/valtillfälle | Canonical-godkännande | auto canonical | auto remote | Explicit local / annat besked | Varför inte canonical-auto? |
|---|---|---|---|---|---|
| RD 2026 | Nej, ingen produkt | Ingen | G7 via stödda råkällor | local är frivilligt och explicit | Inga byggda/validerade canonical-assets; ID-/namnrollsfrågan är öppen. |
| RF 2026 | Nej, ingen produkt | Ingen | G7 via stödda råkällor | local är frivilligt och explicit | Råkällans rättelse efter dubbelräkning är verifierad, men ingen canonical-produkt finns. |
| KF 2026 | Nej, ingen produkt | Ingen | G7 via stödda råkällor | local är frivilligt och explicit | Ingen canonical-produkt; samma öppna ID-/namnrollsfråga. |
| Orsa KF 2003-03-16 | Nej | Ingen | Ingen | R/S kräver local | Omvalsprodukt saknas; ska inte ärva ordinarie 2002-godkännandet. |
| Västra Götaland RF 2011-05-15 | Nej | Ingen | Ingen | R/S kräver local | Verifierad råkälla är inte en canonical-release. |
| Örebro Nordöstra KF 2011-05-15 | Nej | Ingen | Ingen | R/S kräver local | Endast 17 eventmandat; ingen kommunomfattande ny 2011-räkning. |
| Båstad KF 2015-05-10 | Nej | Ingen | Ingen | R/S kräver local | Ingen canonical-produkt. |
| Falun KF 2019-04-07 | Nej | Ingen | Ingen | R/S kräver local | Ingen canonical-produkt. |
| Härledd mandatkomposition efter omval | Nej, separat produkt saknas | Ingen | Ingen komplett sammansatt väg | Kompositionsanropet kräver explicit local och nödvändiga bevarade komponenter | Får inte marknadsföras som en ny ordinary-canonical-vy. |
| Mandatperiodshistorik 2014–2018/2018–2022/2022–2026 | Ingen levererad canonical-historikprodukt | Inte aktuellt | Ingen komplett sådan väg | Gemensamt historikunderlag kräver lokala källor; API:t har inte auto | Ska inte få godkännande via de sju fasta valresultatfunktionerna. |
| EU 2009 P-prototyper, alla nivåer | Nej, sex assets hålls utanför | Ingen | Ingen stödd remote | Endast uttrycklig local för råarkivet; privat canonical-prototyp kan testas explicit | Ej verifierad kandidatallokering/officiell additivitet samt saknad finfördelning och listkoppling. |

2026-raden godkänner inte någon ny kandidatidentitetstolkning. Auto väljer den
befintliga remote-vägen; dess källkontroller, metadata och felbeteende kvarstår.
Detta är en inventering, inte en ny live-hämtning eller certifiering av alla
Valmyndighetens nuvarande filer. Om remote saknas eller felar väljs aldrig local.

## Exakt rekommenderad registrering vid den framtida aktiveringen

Följande är rekommenderade värden, **inte införda kodändringar**:

| Registreringsnyckel (series/event/year) | auto_eligible | Godkända auto-funktioner | Assets |
|---|---|---|---:|
| rkl / ordinary / 2002 | true | results, seats, candidates, elected, substitutes, preference_votes | 14 |
| rkl / ordinary / 2006 | true | G7 | 15 |
| rkl / ordinary / 2010 | true | G7 | 24 |
| rkl / ordinary / 2014 | true | G7 | 24 |
| rkl / ordinary / 2018 | true (redan true; ny generation/manifestplats) | G7 | 20 |
| rkl / ordinary / 2022 | true | G7 | 24 |
| folkomr / ordinary / 2003 | true | results | 1 |
| eu / ordinary / 2004 | true | G7 | 14 |
| eu / ordinary / 2009 | true, avgränsat | results, seats, candidacies, candidates, elected, substitutes | 8 |
| eu / ordinary / 2014 | true | G7 | 14 |
| eu / ordinary / 2019 | true | G7 | 15 |
| eu / ordinary / 2024 | true | G7 | 15 |
| **Summa** | **12 avgränsade produkter** | **Ingen automatisk local** | **188** |

RKL-godkännandet omfattar RD/RF/KF inom respektive gemensam produkt. Alla andra
valtillfällen står utanför godkännandelistan. 2026 och omval får inga nya
true-poster. Flaggan avgör inte ensam vilka steg/geografier som finns:
manifestets deklarerade täckning och läsarens valideringar gäller fortfarande.

## EU 2009: precist spärrkrav före aktivering

Aktivera sex funktioner, **inte hela 14-asset-prototypen**. För publicering krävs
ett nytt, begränsat manifest med de åtta godkända assetsen och deras verkliga
layouter. Det fullständiga prototypmanifestet får inte användas med sex filer
borttagna från servern.

Teknisk uppföljning 21 oktober: den centrala spärren är nu implementerad som
`auto_functions` i registreringen. Ordningen är **aktiveringsflagga → godkänd
funktion → faktisk manifesttäckning**. EU 2009 tillåter E6 och nekar P före
manifestläsning, även när den oförändrade fullständiga 14-asset-prototypen är
konfigurerad. Tom/saknad funktionslista ger inget auto-godkännande.
Explicit canonical granskar däremot den valda manifesttäckningen oberoende av
auto-behörighet. Spärren har verifierats både isolerat och med den verkliga
prototypen. Aktiveringsflaggorna är fortfarande oförändrade.

För P gäller efter den föreslagna avgränsningen:

- `auto`: tydligt fel, aldrig lokal fallback och aldrig automatisk prototyp-P.
- `canonical` med publiceringsmanifestet: tydligt besked att vyn inte ingår.
- `local`: användaren väljer själv sitt råarkiv och dess dokumenterade
  källkonflikter; data blir inte reconcilerade av source-valet.
- Explicit privat canonical-prototyp: fortsatt ett test-/forskningsval,
  inte godkänd publik P-täckning.

De 34 gemensamma Per Johansson-rösterna får inte ges en påhittad fördelning;
91 saknar verifierad finfördelning; 102 resultatkolumner saknar säker lista/position.
De 23 entydigt härledbara rösterna är inte införda; den nuvarande geografiska
resten i övriga 100 kolumner är 114. Inget av detta ändras vid aktivering av E6.
Kandidatur-/valda-/ersättarvyerna innehåller inte den felaktiga 22+22-allokeringen.

## Vad som återstår före releasebeslut

1. Funktionsavgränsningen är godkänd och den centrala spärren implementerad.
   Behåll spärrtesterna i slutvalideringen; inga aktiveringsflaggor har ändrats.
2. Avgränsa EU 2009:s leveransmanifest till åtta assets. Behåll dess sex P-baser
   utanför publiceringen och oförändrade lokalt.
3. Fastställ distributionsplatser, manifestnamn, versions-/cacheuppgifter och
   koppla godkännandet till den nya generationen. Gammal publicerad 2018-version
   bevaras historiskt men ska inte vara den aktuella konfigurationens källa.
4. Commit och ren rebuild från den beslutade produktionsversionen. Alla nuvarande
   tolv arbetskopiegenerationer är dirty; inget får märkas clean i förväg.
5. Slutvalidera innehåll, avsiktliga manifest/proveniensskillnader, byteidentitet
   för oförändrade Parquet-data, schema/kontrakt/rundresa, källintegritet samt alla
   godkända funktioner/varianter och source-val; kör testsuite och R CMD check.
6. Publicera och aktivera först efter att leveransen går att hämta och kontrollera.
   Ingen true-flagga ska peka på saknade filer eller en icke godkänd generation.

Inga andra hela produkter behöver hållas tillbaka av innehållsskäl inom den
redan godkända avgränsningen. Källbegränsningar i 2002/2006/2010/2014/2018/2022
ska inte döljas, men är inte samma sak som EU 2009:s underkända P-allokering.
Det är de redan granskade källpopulationerna, inte ett påstående om full fysisk
personidentitet eller varje historisk extravariabel, som föreslås som default.

**Den ursprungliga inventeringen ändrade ingen kod, data eller flagga. Den senare godkända spärrimplementationen redovisas nedan; ingen aktivering eller publicering har gjorts.**

## Faktisk selektion efter spärrimplementationen

Kontrollerad 21 oktober 2026 mot den implementerade selektorn och samtliga tolv
befintliga manifest. Samtliga sju funktionsval har prövats för varje produkt,
med dagens flaggor och med separat aktivering **enbart i testprocessens minne**:
168 dokumenterade beslut. EU 2009 prövades avsiktligt med sitt fullständiga
oförändrade 14-asset-manifest, inte endast det föreslagna åtta-asset-urvalet.

**G7/H6/E6/R definieras ovan.** `Fel → local` betyder att auto ger ett fel med
hänvisning till explicit `source = "local"`; det betyder aldrig att auto använder
local. Tabellen gäller stödda slutliga standardanrop. Övriga redan godkända
stadier, geografier och varianter kräver dessutom faktisk manifesttäckning.

| Produkt | auto_eligible nu | Faktisk auto-selektion nu | Verifierad selektion vid aktivering endast i minnet |
|---|---|---|---|
| RKL 2002 (RD/RF/KF) | false | H6: fel → local; candidacies ostödd | H6 canonical; candidacies fortsatt ostödd |
| RKL 2006 (RD/RF/KF) | false | G7: fel → local | G7 canonical |
| RKL 2010 (RD/RF/KF) | false | G7: fel → local | G7 canonical |
| RKL 2014 (RD/RF/KF) | false | G7: fel → local | G7 canonical |
| RKL 2018 (RD/RF/KF) | true, oförändrad | G7 canonical med konfigurerat aktuellt manifest | G7 canonical |
| RKL 2022 (RD/RF/KF) | false | G7 remote | G7 canonical |
| Folkomröstning 2003 | false | R remote; övriga ej tillämpliga | R canonical; övriga ej tillämpliga |
| EU 2004 | false | G7: fel → local | G7 canonical |
| EU 2009 | false | G7: fel → local | E6 canonical; preference_votes: fel → local |
| EU 2014 | false | G7: fel → local | G7 canonical |
| EU 2019 | false | G7 remote | G7 canonical |
| EU 2024 | false | G7 remote | G7 canonical |

RKL 2018 har ännu ingen ny publik manifestplats i registreringen. Dess nu-rad
förutsätter det korrekt konfigurerade aktuella manifest som kontrollen använde;
utan sådan konfiguration ger dagens implementation ett manifestkonfigurationsfel.
Det är en kvarvarande distributionsuppgift, inte en redan publicerad release.
Övriga icke-aktiva prototypmanifest ignoreras fortfarande av auto, även om de är
lokalt konfigurerade. Ingen remote-post innebär en ny live-hämtning eller en
ny granskning av Valmyndighetens nuvarande innehåll: den anger den stödda vägen
som väljs när canonical inte är auto-godkänd. Ingen post väljer lokala råfiler.

### Verifiering och avgränsad ändringslista

- Den centrala `auto_functions`-kolumnen och spärren före manifeståtkomst finns i
  `R/canonical_distribution.R`. Saknad/tom/feltypad lista ger inget godkännande.
- Nya regressioner finns i `tests/testthat/test-canonical-auto-functions.R`.
  Installerad hjälp uppdateras i `R/data_sources.R` och `man/data_sources.Rd`.
  Utvecklingsdokumentationen uppdateras här och i `SOURCE_SELECTION_DESIGN.md`.
- Hela testsviten: **4 945 godkända**, 16 uttryckliga integration-/externkällskips,
  inga fel eller varningar. Det är 224 ytterligare godkända kontroller jämfört
  med den föregående source-selection-kontrollen.
- `R CMD check --no-manual`: **0 errors, 0 warnings, 0 notes**, från en isolerad
  paketkopia av den aktuella arbetskopian. Detta är inte en ren canonical-rebuild.
- Verklig full14-prototyp: samtliga E6-output är `identical()` för auto med
  aktivering endast i minnet respektive explicit canonical, inklusive ordning,
  typer och attribut. Faktiska rader: 25/11/500/500/18/68.
- Verklig auto-P stoppas trots full14-manifest och befintligt lokalt råarkiv.
  Explicit canonical kan fortfarande läsa den privata prototypen (488 rader,
  bevarad källsumma 1 876 795, inte officiellt reconcilerat total). Saknat P-asset
  i delmanifest ger fortfarande fel; explicita källor passerar inte auto-spärren.
- Explicit local kan fortfarande välja den bevarade checksummeverifierade
  EU 2009-finalfilen. Befintliga tester för övriga lokala och remote-källor passerar.
- Samtliga tidigare registreringsfält, inklusive alla `auto_eligible`, är exakt
  oförändrade. Endast den nya centrala funktionslistan har tillkommit.
- Alla 206 aktuella canonical-filer/manifest och 1 300 skyddade historiska
  asset-/manifestreferenser har oförändrade kontrollsummor. Inga nya canonical-
  produkter har byggts och inget publiceringsmanifest har ändrats till åtta filer.

Lokala bevis: `.local-data/canonical-auto-function-gate-20261021/`, särskilt
`source-decisions.csv`, `selection-integrity.log`, `tests.log`, `tests.rds` och
`package-check/swelections.Rcheck/00check.log`. Nuvarande flaggor, simulering och
explicita privata testläsningar är separata; simuleringen sparar inga flaggändringar.

**188-asset-omfattningen är oförändrad. Ingen commit, push, aktivering eller publicering.**


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
