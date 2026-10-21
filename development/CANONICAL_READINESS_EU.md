> Uppföljning 21 oktober 2026: samtliga fem EU-produkter har nu lokala generationer enligt det gemensamma [värde- och lagringskontraktet](VALUE_CONTRACT.md). De tidigare rena generationerna nedan bevaras som referenser; arbetskopiegenerationerna har sanningsenligt `build_tree_dirty = true`. Ingen EU-källa har aktiverats eller publicerats. EU 2009:s öppna frågor och övriga dokumenterade källbegränsningar är oförändrade.

# Canonical-readiness: Europaparlamentsvalen 2004–2024

Granskad 20 oktober 2026. Detta är en data- och leveransgranskning, inte ett
beslut om automatisk användning. **Samtliga fem EU-år behåller
`auto_eligible = false`**, både i registreringen och i de granskade manifesten.
Den ursprungliga auditten ändrade inga produktionsfiler, källor eller canonical-data. Den tekniska uppföljningen nedan redovisar senare avgränsade ändringar och nya separata clean-generationer.

## Rekommendation per år

Rekommendationen avser den angivna resultatpopulationen och de sju befintliga
funktionerna. Gemensamma leveranskrav i avsnittet om aktivering måste också
klaras före faktisk automatisk användning. Frånvaro av en fullständig preliminär
källa eller av mandatperiodshistorik gör inte ett komplett slutresultat felaktigt.

| EU-val | Canonical komplett för beslutad täckning? | Valideringar | Kända problem/luckor | Extern fråga? | Rekommendation |
|---|---|---|---|---|---|
| 2004 | Ja: slutresultat, dokumenterade kandidaturer, rapporterade personröster, mandat och ursprungliga relationer | Godkända | 943 giltiga handskrivna röster saknar individuell partibeteckning; nycklar avser listpositioner, inte verifierade personer; full preliminär Wednesday-källa saknas | Ingen som behöver blockera denna population | **Redo med dokumenterad begränsning** |
| 2009 | Slutresultat/mandat/relationer ja; personrösternas kandidat- och finfördelning är inte färdigreconcilerad | Teknik och exakt källåtergivning godkända; officiell additivitet underkänd i småpartikomponenten | 34 röster utan säker kandidatfördelning; 91 utan säker finfördelning; 102 resultatkolumner utan säker lista/position; se särskilt nedan | Ja, de redan skickade frågorna | **Avvakta – offentlig representation av småpartipersonröster behöver beslutas/lösas** |
| 2014 | Ja: slutresultatet och de sju vyerna; clean-generation verifierad | Godkända, inklusive 14 byteidentiska clean-assets | 10 Vårdsberg-röster har orapporterad partibeteckning; en explicit nollkategori saknar numerisk partikod; full preliminär Wednesday-källa saknas | Nej för beslutad täckning | **Redo med dokumenterad begränsning** |
| 2019 | Ja: slutligt och fullständigt preliminärt rapporteringsresultat samt kandidat-/mandatvyer | Godkända | Avsiktliga populationsskillnader för ogiltiga kandidaturer; gallrade namn; preliminär övrigkategori förblir aggregerad | Nej för denna täckning | **Redo för `auto_eligible = true` efter separat publicerings-/aktiveringsbeslut; tekniska leveranssteg passerar** |
| 2024 | Ja, med den tidigare godkända kandidatsnapshot-avvikelsen | Godkända | Kandidat 1203 finns endast i den tidigare 9 juni-snapshoten; ingen resultat-/personröst-/mandatpåverkan | Orsaken är okänd men ytterligare svar krävs inte enligt tidigare beslut | **Redo med dokumenterad begränsning** |

Ingen ny numerisk avvikelse mellan canonical och den beslutade källvägen har
identifierats. 2009:s källkonflikt blir däremot inte löst av att en validering
bekräftar att dess felande källkolumner har kopierats exakt.

## Ursprungligen granskade referenser och teknisk fullständighet

| År | Lokal referens under `.local-data/canonical-build/` | Parquet | Bytes | Byggcommit | Oren byggkopia? |
|---|---|---:|---:|---|---|
| 2004 | `eu-2004-clean-1b83fe41` | 14 | 2 188 439 | `1b83fe41` | Nej |
| 2009 | `eu-2009-clean-4dd88b15` | 14 | 3 588 007 | `4dd88b15` | Nej |
| 2014 | `eu-2014-reviewed-20261016` | 14 | 3 767 830 | `140d1da4` + dåvarande arbetskopia | **Ja** |
| 2019 | `eu-2019-clean-140d1da` | 15 | 6 153 264 | `140d1da4` | Nej |
| 2024 | `eu-2024-clean-5b2dadc` | 15 | 6 208 936 | `5b2dadc2` | Nej |

**72/72 assets** har rätt storlek, SHA256, radantal och deklarerade tabellkolumner.
Alla 72 passerar en ny exakt Parquet skriv-/läsrundresa. Samtliga 72 källposter i
manifesten har återfunnits genom de befintliga lokala källresolvrarna och matchar
sina SHA256. Alla manifest använder engelskt schema 2 och opublicerad
`data-v0.0.0`. Inga maskinspecifika absoluta sökvägar hittades i dessa manifest.

2014-implementationen finns i commit `dbfe6f7`, men det gör inte automatiskt den
äldre, granskade arbetskopiebyggnaden clean. Den valda referensen redovisar
korrekt `build_tree_dirty = true`; ett senare rent bygge med samma Parquet-bytes
måste visas före aktivering. Ingen clean-märkt EU-2014-referens finns bland de
inventerade canonical-build-generationerna.

Assets täcker `results`, `seats`, `candidacies`, `candidates`, `elected`,
`substitutes` och `preference_votes`, inklusive kandidatbas utan resultatberikning
och sex personröstbaser. 2004/2009/2014 har även källorienterade
partibeteckningstabeller. 2019/2024 har separata slutliga och preliminära resultat-
och mandattabeller. Component-rader i personröstbaserna är inte extra kandidater.

## Kontrollsummor för data och geografi

### Slutliga röster och mandat

| År | Giltiga | Ogiltiga | Avgivna | Röstberättigade | Tilldelade mandat | Valda observationer | Tomma mandat |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2004 | 2 512 069 | 72 395 | 2 584 464 | 6 827 870 | 19 | 19 | 0 |
| 2009 | 3 168 546 | 59 015 | 3 227 561 | 7 088 303 | 18 | 18 | 0 |
| 2014 | 3 716 778 | 42 173 | 3 758 951 | 7 359 962 | 20 | 20 | 0 |
| 2019 | 4 151 470 | 36 378 | 4 187 848 | 7 576 917 | 20 | 20 | 0 |
| 2024 | 4 198 011 | 42 448 | 4 240 459 | 7 942 272 | 21 | 21 | 0 |

Parti-/kategorisummorna, giltiga + ogiltiga = avgivna och mandat = valda + tomma
stämmer. Ogiltighets-/blankkategorierna kontrolleras mot respektive källstruktur;
blank är ogiltig i dessa EU-val. Senare medlemsbyten, 2009 års senare utökning
18→20 och Brexit-utökningen 2019 års mandat 20→21 ingår inte i de fasta resultaten.

| År | Nation/län/kommun | Faktiska kommunvalkretsar | Vanliga distrikt | Wednesday/enheter | Samtliga distriktsenheter |
|---|---|---:|---:|---:|---:|
| 2004 | 1 / 21 / 290 | 185 | 5 875 | 396 | 6 271 |
| 2009 | 1 / 21 / 290 | 186 | 5 664 | 396 | 6 060 |
| 2014 | 1 / 21 / 290 | 181 | 5 837 | 390 | 6 227 |
| 2019 | 1 / 21 / 290 | 53 | 5 984 | 321 | 6 305 |
| 2024 | 1 / 21 / 290 | 41 | 6 275 | 314 | 6 589 |

Samtliga förväntade enheter finns. Även Katrineholms uttryckliga noll-Wednesday
i 2004 finns kvar. Nation/län/kommun/distrikt summerar till samma slutliga röster.
Kommunvalkretsvyn omfattar de verkliga valkretsarna i delade kommuner, inte en
alternativ nationell population: dess summa ska inte adderas till kommun- eller
distriktsvyn eller förväntas ensam täcka landet. Tekniska `00`-grenar blir inte
extra kommunvalkretsar. Wednesday-enheter får inte uppfunnen väljarkår/valdeltagande.
De äldre XML-filernas 29 RD-redovisningsgrupper är inte EU-mandatvalkretsar och
ligger utanför det beslutade femnivåkontraktet; originalmaterialet bevaras.

### Politiska kategorier, kandidaturer och rapporterade personröster

| År | Slutliga partier/kategorier | Kandidaturer | `candidates()`-rader | Ersättarrelationer | Nationella rapporterade personröster |
|---|---|---:|---:|---:|---:|
| 2004 | 27 namngivna + 943 handskrivna aggregatröster | 382 listpositioner | 382 | 71 | 1 480 960 |
| 2009 | 24 namngivna + 1 130 handskrivna aggregatröster | 500 listpositioner | 500 | 68 | Officiellt **1 876 785**, nuvarande kandidatrader **1 876 795** |
| 2014 | 21 positiva namngivna + Socialisterna=0 + 5 618 handskrivna aggregatröster | 376 | 376 | 74 | 1 859 375 |
| 2019 | 66 individuellt identifierade positiva partier | 562, varav 556 giltiga | 556 | 74 | 1 634 596 |
| 2024 | 100 positiva namngivna + uttrycklig övrigkategori=0 | 1 395, varav 1 390 giltiga | 1 385 | 77 | 1 914 494 |

Ersättarrader är relationer, inte antal personer: de unika källnycklarna är
27/27/30/27/27. 2024:s giltiga kandidat–partinycklar är 1 385, dess distinkta
kandidatnummer 1 340; olika list-/partirepresentationer är inte borttappade personer.
För 2004/2009/2014 saknar källan den moderna administrativa giltighetsvariabeln;
`NA` betyder inte att samtliga kandidaturer är ogiltiga.

2004 och 2009 använder dokumenterade kandidatur-/källobservationsnycklar, inte
påhittade person-ID:n. 382 listpositioner mot SCB:s 372 nominerade 2004, respektive
500 mot SCB:s 488 år 2009, är inte en verifierad person-till-person-korsning.
Det motiverar inte att listpositioner eller personröstobservationer tas bort.
För alla år ska kandidatur, kandidatnummer i källan och fysisk person hållas isär.

2019:s tre ogiltiga kandidat–partirelationer har **7 455** rapporterade röster;
2024:s fem har **2 324**. Dessa finns kvar i personröstutdata men inte i den giltiga
kandidatpopulationens totalsummering. Därför är `candidates()`-summorna
1 627 141 respektive 1 912 170 korrekta för sina populationer. Det är inte
borttappade röster. Kontroll mot candidacy-status har utförts för alla åtta fallen.

## 2009: tre öppna frågor, skilda bedömningar

### 91 röster utan säker finfördelning

**Källans geografiska detaljbegränsning, inte en ny transformation som tappar
kända distriktsvärden.** De berörda 30 kommunerna har flera Wednesday-enheter.
Ingen verifierad fördelning per Wednesday eller kommunvalkrets finns.
Kommunuppgifterna får inte kastas bort; den okända finfördelningen kan däremot
förbli oallokerad och tydligt dokumenterad. Detta behöver inte ensamt blockera
canonical med uttryckligt ofullständig finfördelning. Frågan till Valmyndigheten
är extern/öppen och kan ge den saknade fördelningen.

Dagens prototyp innehåller **inga småpartikandidatceller för Wednesday eller
kommunvalkrets**, precis som dess workbookkälla. Det finns även 23 geografiskt
entydigt härledbara röster i 21 kommuner med en Wednesday-enhet; de är utredda men
**inte införda**. Totalt är den nuvarande kommun-minus-ordinarie-rest som avser de
övriga 100 källkolumnerna 114 röster i 51 kommuner: 23 + 91. De 91 är alltså inte
hela dagens skillnad mellan denna komponents kommun- och distriktsobservationer.

### 34 röster utan säker fördelning mellan Per Johansson-kandidaturerna

**Källkonflikt med konsekvens för offentlig modellering; blockerar nuvarande
oförbehållna automatiska användning av personröstvyn.** Listan är 04536, parti
0909. De dokumenterade kandidaturerna är position 18, tågförare i Stockholm,
48 år, och position 32, sjuksköterska i Sundsvall, 38 år. Källkolumner 36 och 47
har identiska vektorer och anger vardera 22 nationellt, 28 över kommuner/län och
32 över ordinarie distrikt. Inget av dessa kolumnvärden har verifierats som en
fördelning på de två listpositionerna.

Övriga 100 kolumner ger 2 621 nationellt/kommunvis. Det officiella aggregatet
2 655 ger den **härledda gemensamma resten 34**, inte en individuell fördelning.
`candidates()` tilldelar inte de två listpositionerna 22 var: deras berikning är
okänd. `preference_votes()` bevarar däremot 22 + 22 under separata
`2009:E:source-column:36/47`-nycklar. Att återge källkolumner exakt är tekniskt
korrekt för en källorienterad prototyp, men gör inte värdena verifierade som
kandidatallokering eller officiell summa.

| Nuvarande publika vy | Alla personröstrader summerade | Skillnad mot officiellt 1 876 785 |
|---|---:|---:|
| Nation / personvalsområde | 1 876 795 | +10 |
| Län / kommun | 1 876 807 | +22 |
| Distrikt inklusive rapporterade Wednesday | 1 876 701 | −84 |

Officiellt total = huvudpartikomponent **1 874 130** + officiellt småpartiaggregat
**2 655** = **1 876 785**, verifierat mot original-XML och SCB. Den tidigare stora
avvikelsen är löst; tabellens skillnader är inte en ny stor avvikelse.

Det tidigare underlaget för en framtida konservativ finfördelning är också
återkontrollerat: ordinarie, exklusive de två konfliktkolumnerna **1 810 128** +
rapporterade Wednesday **66 509** + entydigt härledbara **23** = **1 876 660**;
resten **125 = 91 geografiskt + 34 kandidatallokering**. Siffran 66 532 avser
rapporterat **plus härlett**, inte dagens lagrade Wednesday-rader. Denna
beräkning är diagnostik, inte en implementerad omfördelning.

34 får inte bara försvinna ur det officiella totalet. Den individuella
fördelningen kan lämnas okänd, men en offentlig representation av den gemensamma
resten/officiella aggregatet måste beslutas innan hela 2009-produkten markeras som
färdig för auto. Svaret från Valmyndigheten kan lösa allokeringen; annars behövs
ett separat godkännande av hur osäkerheten representeras. Ingen sådan ändring
görs i denna audit. Att bara ta bort en 22-kolumn skulle inte lösa problemet.

### 102 kolumner utan säker lista/valsedelsposition

**Ofullständig källkoppling; kan vara en dokumenterad begränsning utan att
källobservationerna försvinner.** Alla 102 kolumner är bevarade, inklusive
explicit noll: 102 × 290 kommuner och 102 × 5 664 ordinarie distrikt. De positiva
raderna exponeras med källkolumnnyckel, rapporterat namn och källans parti, utan
påstådd lista/position/personidentitet. Mappningen till de 114 småpartipositionerna
i ballotmaterialet är inte verifierad. `candidates()` har därför 114 okända
personröstberikningar, inte 114 konstaterat saknade kandidater eller nollor.

Lista och position kan lämnas `NA` tills Valmyndigheten kan ge ursprungliga
nycklar. Detta blockerar inte en uttryckligt källobservationsbaserad
personrösttabell, men blockerar påståendet att kandidatur–personröstkopplingen
är komplett. De två Per Johansson-kolumnernas räknekonflikt är ett separat,
allvarligare problem. Fysisk-person-länkning är ytterligare en annan dimension.

## Åtgärder per år

- **2004:** behåll 943-aggregatet och kandidatur-ID-semantiken. Behåll stöd för
  explicit noll, inklusive noll-Wednesday och 22 listpositioner utan personröster.
  SD:s 14 450 personröster stöds av slutprotokollet/detaljkällorna; de 270
  felaktiga nollcellerna i SCB SSD ska inte kopieras. SCB:s total 1 480 960 stämmer.
  Ingen ny källåtervinning eller numerisk rättelse krävs före godkännande.
- **2009:** avvakta beslutad offentlig behandling av 34-rösterskonflikten.
  Dokumentera finfördelningens faktiska gräns (114, varav 23 härledbara och 91
  externa) och de 102/114 olänkade käll-/kandidaturpopulationerna. Redovisa
  officiellt aggregat separat från konfliktkolumnsummor. Partiröster, 18 mandat,
  valda och ersättare har ingen motsvarande källkonflikt; de vyerna är redo i sak.
- **2014:** verifiera ett clean bygge och identiska 14 Parquet-assets innan
  aktivering. Behåll de 10 giltiga handskrivna Vårdsberg-rösterna som orapporterad
  partibeteckning, inte som ogiltiga röster. Behåll Socialisterna=0
  med saknad numerisk kod. Gallrade namn och ej rapporterade attribut för 376
  kandidaturer är avsiktliga `NA`, inte nya borttappade observationer.
- **2019:** inga återstående innehållsrättelser identifierade. Behåll rätt
  väljarkår 7 576 917; den äldre +983-snapshoten är inte bygginput. Preliminärt
  särredovisas tio partier och aggregeras övriga; slutligt särredovisas alla 66.
  Behåll de 7 455 ogiltiga kandidaturernas personröster utanför den giltiga
  kandidatpopulationens berikning, inte utanför personröstobservationerna.
- **2024:** behåll den godkända 11 juni/december-populationen och dokumenterad
  den tidigare snapshotens Felix Österberg, kandidat 1203/parti 1659. 9 juni-posten bevaras
  som proveniens, inte en extra final kandidatur. Inget fastställer varför den
  försvann; enligt tidigare beslut behöver detta inte undersökas vidare för
  implementationen. Inga personröster/valda/ersättarposter för 1203 har identifierats.
  Behåll de fem ogiltiga kandidaturernas 2 324 rapporterade personröster.

2004/2009/2014 saknar återfunnen komplett preliminär Wednesday-källa och avvisar
`count = "preliminary"`; de är inte preliminärt kompletta. 2019 och 2024 har
fullständiga preliminära rapporteringssnapshots med 6 305 respektive 6 589 enheter.
Detta påstår inte att en separat valnattsfrysning eller full mandatperiodshistorik
är verifierad. Inga nya sådana krav läggs på en färdig final-produkt.

## Gemensamma fynd före faktisk aktivering (ursprunglig audit)

1. **Valideringsverktygen behöver en kompatibilitetsrättelse.** Alla fem
   `data-raw/validate-eu-YYYY.R` lägger `data_dir` i `common` och skickar detta
   även till explicita canonical-anrop. Den nya, avsiktliga argumentkontrollen
   avvisar detta. Det är ett verkligt underhållsfel i validatoranropen, inte ett
   konstaterat fel i Parquet-data. Canonical-anrop ska utelämna det rådataspecifika
   argumentet; råanrop ska behålla det. Originalskripten är inte ändrade här.
   För 2024 har en lokal auditkopia med endast den ändringen och en separat
   cacheplats körts genom hela jämförelsematrisen. För äldre år har de oförändrade
   oberoende källkontrollerna anropats direkt mot canonical-vyerna.
2. **Versions-, distributions- och cachekonfiguration måste beslutas.** De fem
   prototyperna är opublicerade och saknar EU-release-URL i registreringen.
   Vanliga användare ska inte behöva utvecklarens lokala arkiv. Publicerad eller
   uttryckligt konfigurerad godkänd manifest-/assetplats måste finnas. Välj en
   verklig datareleaseversion och registrera bara verifierade vyer/stadier.
3. **Årsvisa manifestcache-nycklar behövs om flera EU-produkter delar version.**
   En ny reproduktion visar att standardnyckeln `series/event_kind/data_version`
   kolliderar för EU 2019/2024 med samma version. Det andra årets manifest ger då
   det avsedda valideringsfelet "Cached canonical manifest is invalid".
   Inga data blandas, men anropet fungerar inte. Den redan befintliga registreringens
   `cache_key` kan sättas unikt per år/version; detta har verifierats utan någon
   produktionsändring. Alternativt kan en senare ändring lägga år i standardnyckeln.
   Dagens explicita prototypmanifest använder inte denna publiceringscacheväg.
4. **Clean release-proveniens:** 2014 saknar en clean-märkt vald referens.
   Övriga fyra har clean-proveniens, men en senare release från den då godkända
   produktionscommitten ska fortfarande visa oförändrade bytes. Att ändra flaggor
   i gamla manifest är inte en ersättning för ett verifierat bygge.

Inget av dessa fynd motiverar att nu ändra ett rösttal, en kandidatidentitet eller
ett schema. Inga befintliga frågor till Valmyndigheten har förklarats lösta genom
antaganden. Inga ytterligare källsökningar eller kontakter har gjorts.

## Validering och reproducerbarhet för denna audit

Arbetsmaterial och maskinläsbara resultat finns lokalt under
`.local-data/eu-canonical-readiness-20261020/`:

- `metadata.csv`, `assets.csv`, `sources.csv`: exakta generationer, manifesthashar,
  asset-/källhashar och storlekar. 72 assetkontroller och 72 exakta rundresor passerar.
- `summary.csv`, `geography.csv`, `preferences.csv`, `scope-details.csv`: faktiska
  publika nycklar, populationsstorlekar, nivåsummeringar och källmissingness; typer bevaras i exakta rundresor och API-jämförelser.
- `independent.log` samt `independent-2019.log`: nya oberoende kontroller av XML,
  listor, kandidaturer, valda/ersättarordning, SCB och där tillämpligt SND/protokoll.
  De separata bevarad-källa-testerna passerar utan skips: 54 assertions för 2004,
  65 för 2009, 56 för 2014 och 42 för 2019 (217 sammanlagt). Ett inledande
  audit-harnessanrop för 2019 gav fel nyckelstruktur till kontrollfunktionen;
  det korrigerades till dess befintliga räkning/nivå-nycklar och kördes om.
  Ingen källa, produktionsfunktion eller acceptansgräns ändrades.
- `validate-2024.log`: hela 2024-matrisen passerar raw/canonical, EN/SV,
  standard/full, lista och nollkomplettering; även de största distriktsvyerna på
  3 092 601 och 3 093 041 rader passerar. 393 607 positiva list-/kandidat-/distriktsrader
  matchar Excel; SCB:s 6 275 vanliga distrikt och aggregerade postalrader stämmer.
- `2009-residuals.log`, `2009-geo-residuals.csv`, `2009-source-grids.rds`: den
  uttryckliga 23/91/34-reconcileringen. Ingen fördelning skrivs in i canonical.
- `validator-compatibility.csv`, `manifest-cache-check.txt`: reproducerade
  verktygs-/aktiveringsfynd och den verifierade cachekonfigurationslösningen.

De nyligen godkända raw/canonical-körningarna i
`.local-data/source-selection-20261020/` återanvänds också: 294 exakta jämförelser
för de äldre EU-läsarna och 840 jämförelser över alla valfamiljer, inklusive alla
fem EU-år. De ersätter inte denna audits oberoende kontroller av källor och summor.
Den föregående paketvalideringens 4 488 tester/16 explicita skips och rena
`R CMD check` redovisas som tidigare evidens, inte som en ny full paketkörning här.
Produktionskoden har inte ändrats under auditten.

Källkontroller är inte en ny formell DTD-/signaturautentisering av historiska
XML-filer. Den tidigare dokumenterade 2019-begränsningen kvarstår. Det är ingen
identifierad röst-/nyckeldifferens i den verifierade källpopulationen.

Se även respektive [2004](COMPLETENESS_EU_2004.md),
[2009](COMPLETENESS_EU_2009.md), [2014](COMPLETENESS_EU_2014.md),
[2019](COMPLETENESS_EU_2019.md) och [2024](VALIDATION_EU_2024.md) för tidigare
källbeslut och den exakta historiska täckningen.

## Genomförd teknisk leveransuppföljning – 20 oktober 2026

De ursprungliga fynden ovan bevaras som audithistorik. Punkterna 1, 3 och 4
är nu åtgärdade/verifierade enligt nedan. Publiceringsbesluten i punkt 2 återstår.

### Avgränsade kod- och verktygsändringar

- Alla fem `data-raw/validate-eu-YYYY.R` utelämnar `data_dir` enbart i canonical-anrop.
  Råanropen behåller argumentet; API:s kontroll av källspecifika argument ändras inte.
- `R/canonical_distribution.R` använder standardcache-nyckeln
  `series/event_kind/year/data_version`. År kan därmed dela en releaseversion utan
  manifestkollision. Uttryckliga `cache_key` behålls, särskilt publicerad RKL 2018.
- `tests/testthat/test-source-selection.R` verifierar EU 2019/2024 med samma version,
  separata cacher och återanvändning utan tillgänglig ursprungsmanifestfil.
- Inga täcknings-/aktiveringsflaggor, publika scheman, källvärden eller kandidatregler ändras.

### Nya rena generationer

En separat lokal Git-klon av den redan committade produktionen
`39622e7b3e2a37c4b35c272f03fb6535734d9e8f` användes. Ingen commit skapades.
Byggarna kördes med bevarade källor och utdata utanför klonen. Git-status var ren;
båda manifesten rapporterar sanningsenligt `build_tree_dirty = false`.
De använder alltså committad produktionskod, inte den nuvarande ocommittade
arbetskopians prestanda-/källvalsändringar. Verktygsrättelserna valideras separat
från denna arbetskopia. Referensgenerationerna har inte skrivits över.

| År | Ny lokal generation under `.local-data/eu-canonical-delivery-20261020/` | Parquet | Bytes | Jämförelse |
|---|---|---:|---:|---|
| 2014 | `eu-2014-clean-39622e7` | 14 | 3 767 830 | Samtliga byteidentiska med `eu-2014-reviewed-20261016` |
| 2019 | `eu-2019-clean-39622e7` | 15 | 6 153 264 | Samtliga byteidentiska med `eu-2019-clean-140d1da` |

Samtliga 29 assets har identiska SHA256, storlekar, rader, kolumner, typer och
ordning. Alla 29 passerar också en exakt Parquet skriv-/läsrundresa.
Manifestens källposter, källval, tabellayout och assetmetadata är identiska.
Endast `built_at_utc`, `build_commit` och (för 2014) `build_tree_dirty` ändras.
Den nya manifesthashen följer dessa förklarade proveniensändringar;
inga röster, relationer eller övriga datavärden ändras.

### Slutkontroller

- Alla fem underhållna EU-validatorer passerar direkt, utan auditkopior:
  35 publika varianter per år 2004/2009/2014 och 41 per år 2019/2024,
  vardera i fyra språk-/detaljkombinationer (748 canonical/raw-jämförelser).
  De äldre årens sju svenska wrapperfunktioner kontrolleras också separat.
  Källornas dokumenterade specialfall och oberoende SCB/XML/Excel-kontroller behålls.
- 840 exakta regressionsjämförelser över 105 fall i alla stödda valfamiljer passerar.
  Resultat, ordning, typer och attribut matchar tidigare granskad implementation.
- Full testsvit: 4 494 godkända, 16 explicita externa integrationsskips,
  inga fel eller varningar. De äldre EU-årens opt-in-källtester körs utan skips
  i respektive validator (217 ytterligare assertions).
- `R CMD check --no-manual --no-vignettes`: 0 fel, 0 varningar, 0 notes.
  Verklig publicerad 2018-väg: 8 assertions passerar, 3 andra externa tester skippar.
- 9 529 historiska källhashar, 208 skyddade assetposter och 20 historiska
  Parquet-rundresor passerar. De fem tidigare EU-manifesten, 72 EU-assets och
  72 valda EU-källposter är dessutom byteoförändrade mot readiness-auditen.
- `git diff --check` och granskning av uppgiftens avgränsade filändringar passerar.

Lokala bevis finns i `.local-data/eu-canonical-delivery-20261020/`:
`build-2014.log`, `build-2019.log`, `compare-builds.log`, `manifest-changes.csv`,
`delivery-inventory.csv`, `validate-YYYY.log`, `tests.log`, `R-CMD-check.log`,
`equivalence.log`, `integrity.log`, `protected-assets.log`, `reference-integrity.log`
och `final-scope.log`. Manifest-/asset-SHA256 finns i leveransinventeringen.

### Beslut som fortfarande återstår

- Välj publiceringsversion och distributionsplats; versionen är ännu opublicerad
  `data-v0.0.0`. Inga GitHub-assets har publicerats.
- Godkänn därefter uttryckligen vilka år/vyer som får automatisk användning.
  Alla fem EU-år har fortfarande `auto_eligible = false`, även i nya manifest.
- 2009 inväntar fortsatt den öppna källfrågan/offentliga representationen för
  34 kandidatofördelade röster, 91 geografiskt ofördelade röster och 102 kolumners
  list-/positionskoppling. Inga föreslagna restposter eller fördelningar införs.
- 2004:s 943-rösterskategori och 2024:s kandidat-1203-snapshotavvikelse kvarstår
  exakt enligt godkända källbegränsningar. 2014:s Vårdsberg-begränsning kvarstår.

2014 och 2019 har därmed klarat de efterfrågade tekniska leveransstegen.
Ingen commit, push, release eller automatisk aktivering har gjorts.
