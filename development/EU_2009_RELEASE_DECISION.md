# EU 2009: releaseurval och faktisk API-täckning

Datum: 21 oktober 2026. Kompletterar
[releaseinventeringen](CANONICAL_RELEASE_READINESS.md); övriga produkter lämnas
oförändrade. Detta är ett beslutsunderlag, inte ett ändrat releaseurval.
Ingen produktionskod, canonical-fil, manifestfil eller auto-flagga ändras.

## Rekommendation: C, uttryckligt partiellt stöd med åtta assets

De **180 assetsen innehåller noll EU 2009-assets**. De kan därför inte ge
partiellt canonical-stöd för 2009 enligt alternativ A.

En mer precis avgränsning än att hålla alla 14 är möjlig:

- **Åtta assets** ger korrekt finalt stöd för `results()`, `seats()`,
  `candidacies()`, `candidates()`, `elected()` och `substitutes()`, med den
  specificerade luckan i småpartikandidaternas personröstberikning.
- **Sex personröstbaser** hålls som prototyp. Ingen kandidat-/geografiallokering
  ändras och ingen felande källkolumn raderas.
- Rekommenderad leverans blir då **188 Parquet-assets**, inte 180 eller 194.
  Sju av de åtta tilläggen används av de sex funktionerna; den åttonde är
  kompletterande källdokumentation om giltiga handskrivna partibeteckningar.
- **`auto_eligible = false` kvarstår för EU 2009.** Publicering av sex vyer ger
  inte automatiskt ett separat auto-godkännande.

Detta förutsätter ett separat godkännande av delurvalet och ett tydligt avgränsat
publiceringsmanifest samt dokumentation/tester för de stödda canonical-vyerna.
Inga sådana leveransändringar görs här. Alternativ B är säkert om vi i stället
vill publicera enbart hela sjufunktionsprodukter, men håller då tillbaka även
korrekta partiröster, mandat och dokumenterade kandidaturer utan datamässig grund.

## De tre öppna frågorna

Beteckningarna nedan följer [EU-readiness](CANONICAL_READINESS_EU.md):

- **Q1 – geografi:** 91 småpartipersonröster i 30 kommuner med flera
  onsdagsenheter saknar verifierad fördelning till onsdagsenhet/kommunvalkrets.
  Dagens prototyp har inte heller infört de 23 geografiskt entydigt härledbara
  rösterna i 21 kommuner. Den nuvarande geografiska resten för de övriga
  100 kolumnerna är därför **114 = 23 + 91**, inte enbart 91.
- **Q2 – Per Johansson:** den officiella resten är 34 röster gemensamt för två
  kandidaturer på lista 04536, position 18 respektive 32. Källkolumnerna 36/47
  anger vardera 22 nationellt, 28 summerat över län/kommuner och 32 över vanliga
  distrikt. Ingen individuell fördelning är verifierad.
- **Q3 – kandidaturkoppling:** 102 småpartikolumner saknar verifierad koppling
  till de 114 småpartipositionerna i valsedelsmaterialet. Källobservationerna finns;
  det är kopplingen, inte de 114 kandidaturerna, som saknas. Ingen personidentitet
  mellan lika namn antas.

Q1 och Q3 kan i sig avgränsas och dokumenteras. Q2 gör däremot den nuvarande
kandidatkolumnsumman olämplig som verifierad offentlig kandidatfördelning.
Det är tre frågor om källor/representation, **inte fjorton fel i fjorton filer**.

## Exakt inventering av de 14 assetsen

Samtliga finns i den oförändrade schema-3-prototypen och följer value/storage
contract 1/1. Varje asset används för både standard/full och svenska/engelska;
dessa är inte separata filer. Radantal nedan är **fysiska assetrader**, inklusive
basernas kontext-/list-/parti-/kvalifikationstabeller, inte nödvändigtvis antalet
publika kandidatrader.

Maskinläsbar förteckning med SHA256, nivå, frågekoppling och rekommendation finns
i [EU_2009_RELEASE_ASSET_DECISION.csv](EU_2009_RELEASE_ASSET_DECISION.csv).

### Åtta assets utan blockerande felallokering

| Exakt filnamn | Rader | Funktion/innehåll och nivå | Koppling till Q1–Q3 | Varför tidigare tillbakahållen / ny bedömning |
| --- | ---: | --- | --- | --- |
| `eu2009-results-final.parquet` | 84 765 | Finala partiröster/kategorier, giltiga/ogiltiga, väljare och turnout: nation, län, kommun, kommunvalkrets, distrikt | Ingen | Hölls bara som del av hela produkten. Inget självständigt skäl att hålla korrekt finalt partiresultat. |
| `eu2009-seats-final.parquet` | 11 | Partiernas mandat nationellt, 18 ursprungliga mandat, inga obesatta | Ingen | Hela-produkt-avgränsning, inte ett mandatfel. Senare 18→20 är inte del av det fasta valresultatet. |
| `eu2009-candidacies.parquet` | 500 | Dokumenterade kandidaturer med parti, lista och position; nationell valkrets, inklusive 114 småpartipositioner | Ingen lucka i denna dokumenterade population; Q3 gäller resultatkopplingen | Korrekt kandidaturmaterial. Båda Per Johansson-positionerna finns separat; inga konstruerade person-ID:n. |
| `eu2009-candidates.parquet` | 500 | Nationell kandidat-/kandidaturpopulation med tillgänglig final resultatberikning | **Q3 som dokumenterad NA**, inte felallokering | 114 småpartiberikningar är NA. Kända kandidatsummor är 1 874 130, huvudpartikomponenten, inte officiellt total. Per Johansson har NA/NA, inte 22/22. Kan publiceras med denna uttryckliga begränsning. |
| `eu2009-elected.parquet` | 18 | Ursprungligt valda, parti/listanknytning/invaldsordning, nationellt valtillfälle | Ingen | Relationerna är verifierade och använder inte de två konfliktkolumnerna. |
| `eu2009-substitutes.parquet` | 68 | Ursprungliga valda–ersättarrelationer och ordning, nationellt valtillfälle | Ingen | 68 relationer, inte påstått 68 unika fysiska personer. Ingen småpartikonflikt i relationerna. |
| `eu2009-candidate-base.parquet` | 500 | `candidates(include_results = FALSE)`, kandidat-/kandidaturbas utan resultatberikning | Ingen | Korrekt bas; inga personröstkolumner eller osäkra allokeringar används. |
| `eu2009-source-designations.parquet` | 730 | Kompletterande källtabell: giltiga handskrivna **partibeteckningar** per kommunal källenhet; 1 127 betecknade röster + tre utan rapporterad beteckning | Ingen | Inte personröster och ingen direkt egen funktion bland de sju. Fristående provenance/sakunderlag som kan följa med, inte ett felaktigt preferensunderlag. |

500 är källans list-/positionsobservationer, inte en verifierad räkning av unika
personer. Frånvaro av småparti–personröstkoppling gör inte kandidaturerna saknade.

### Sex personröstbaser som bör hållas kvar som prototyp

Alla sex läses av `preference_votes()` och har dessutom ett verkligt
läsberoende på `eu2009-candidacies.parquet`. Varje bas innehåller
`votes`, `lists`, `parties`, `context` och `qualified`.

| Exakt filnamn | Rader | Publik nivå / detalj | Fråga | Varför inte publicera som färdig personröstvy nu? |
| --- | ---: | --- | --- | --- |
| `eu2009-preference-base-area.parquet` | 567 | `level = "preference_vote_area"`, den enda nationella personvalskretsen; med/utan listvy/nollkomplettering | **Q2, Q3** | 102 kolumnobservationer utan verifierad ballotkoppling; Per-kolumnerna 22+22. Kandidatrader summerar till 1 876 795 mot officiellt 1 876 785. |
| `eu2009-preference-base-national.parquet` | 567 | `level = "national"`; alternativ till områdesvyn, inte en extra röstpopulation | **Q2, Q3** | Samma nationella konflikt. Att nivåerna använder separata assets löser inte fördelningen av 34. |
| `eu2009-preference-base-county.parquet` | 10 305 | `level = "county"`, 21 län; med/utan listvy/nollkomplettering | **Q2, Q3** | 102×21 småparticeller. Kolumnerna ger 2 677 småpartiröster mot officiellt 2 655; Per-kolumnerna vardera 28 över länen. |
| `eu2009-preference-base-municipality.parquet` | 95 195 | `level = "municipality"`, 290 kommuner; med/utan listvy/nollkomplettering | **Q2, Q3**; Q1 är jämförelse mot finare nivå | 102×290 småparticeller. Kommunlokaliseringen finns, men konfliktkolumnerna ger samma 2 677. De 91 saknar finare fördelning, inte kommunidentitet. |
| `eu2009-preference-base-municipal-constituency.parquet` | 47 134 | `level = "municipal_constituency"`, 186 faktiska kommunvalkretsar; huvudpartiernas observationer | **Q1, Q3**, ingen direkt Q2-kolumn | **Inga småpartikandidatceller alls**, inte två felaktiga Per-celler. Huvudpartidata är korrekta. Hålls tillsammans med personröstvyn för att inte framställa detta som komplett småpartitäckning; ett separat begränsat nivågodkännande vore en annan omfattning. |
| `eu2009-preference-base-district.parquet` | 1 176 531 | `level = "district"`: 5 664 vanliga +396 onsdagsenheter i geografin; med/utan listvy/nollkomplettering | **Q1, Q2, Q3** | Småpartikällan har 102×5 664 vanliga distriktsceller, **inga småparticeller för onsdagsenheter**. Resten 114 är inte införd; Per-kolumnerna summerar vardera till 32 över vanliga distrikt. Ingen säker lista/position. |

Nollkomplettering skapar ingen källa för saknad lista/position/onsdagsfördelning.
Okänd listposition är inte en saknad observerad röst; de faktiska kolumnraderna
bevaras i prototypen. Ingen av tabellerna ändras nu. Kommunvalkretsasseten har
inte en egen numerisk Per-konflikt; att hålla alla sex är en tydlig gemensam
funktionsavgränsning, inte ett påstående att varje cell är fel.

För perspektiv är dagens nationella officiella total fortfarande
**1 874 130 +2 655 = 1 876 785**. Prototypens kandidatrader summerar till
1 876 795 nationellt, 1 876 807 över län/kommuner och 1 876 701 över distriktsvyn.
Dessa skillnader blandar Q1 och Q2 och ska inte benämnas enbart ”de 91 rösterna”.
Listvyer och geografiska nivåer är alternativa representationer, inte tabeller
som ska läggas ovanpå varandra.

## Faktiskt API-beteende med 180 assets och inga EU 2009-filer

Antag att endast de andra elva produkternas manifest/assets är tillgängliga och
att inget privat 2009-manifest är konfigurerat. Att 2009 har en registrerad läsare
innebär inte att canonical-data för det året har publicerats.

| EU 2009-anrop | Relevant nivå/variant | `source = "canonical"` med endast 180 | `source = "auto"` utan användarens råarkiv |
| --- | --- | --- | --- |
| `results(2009, "E", ...)` | Nation/län/kommun/kommunvalkrets/distrikt; final | Fel: EU 2009 kräver konfigurerat lokalt manifest; ingen annan årgång ersätter det | Historisk råväg väljs; fel om pinnade originalkällor saknas |
| `seats(2009, "E", ...)` | Nationellt; final | Samma konfigurationsfel | Samma råkällkrav |
| `candidacies(2009, "E", ...)` | Alla dokumenterade listpositioner | Samma konfigurationsfel | Samma råkällkrav |
| `candidates(2009, "E", ...)` | `include_results = TRUE` eller `FALSE` | Samma konfigurationsfel | Samma råkällkrav |
| `elected(2009, "E", ...)` | Ursprungligt valda nationellt | Samma konfigurationsfel | Samma råkällkrav |
| `substitutes(2009, "E", ...)` | Ursprungliga ersättarrelationer | Samma konfigurationsfel | Samma råkällkrav |
| `preference_votes(2009, "E", ...)` | Alla sex nivåer; `by_list` FALSE/TRUE, `include_zeros` FALSE/TRUE | Samma konfigurationsfel | Samma råkällkrav; ingen ny förenklad fördelning |

Felmeddelandet för canonical är
`eu 2009 canonical data require a configured local build manifest.`
Råvägen utan godkänt arkiv stoppar med
`Missing approved EU 2009 source: slutresultat.zip`.

Med ett fullständigt pinnat råarkiv använder `auto` den befintliga historiska
råläsaren för samtliga funktioner. Det är användarens sparade material i det
stödda formatet, inte de 180 andra canonical-filerna. Den aktuella råbundeln
kräver sina fem verifierade källroller även när en enskild vy efterfrågas.
Ingen aktuell fjärrnedladdning ersätter de äldre, pinnade originalen.
**Rå personröstutdata behåller samma kända källkonflikter**; `auto_eligible = false`
är inte ett förbud mot rådataanrop eller en automatisk korrigering av dem.

Om användaren uttryckligen konfigurerar den fullständiga lokala 14-asset-
prototypen fungerar `canonical` fortfarande för alla tidigare stödda vyer,
inklusive de oförändrade källkolumnerna i P. Detta är privat prototypåtkomst,
inte stöd från 180-filspubliceringen. Samma prototyp väljs **inte** av `auto`.
Ett flerårsanrop som behöver 2009 misslyckas för det året; året filtreras inte
bort tyst och 2014/2024 returneras inte som ersättning.

Full preliminary är fortsatt ostött både i canonical och råväg. De fem
resultatnivåerna gäller finalt resultat; EU-mandat fördelas bara nationellt.

## Alternativ C: vad åtta EU 2009-assets faktiskt skulle ge

Detta testades med manifesturvalet **endast i minnet**. Inga manifest eller
canonical-filer skapades/ändrades. Åtta befintliga assets behölls, de sex
personröstbaserna utelämnades ur minnessimuleringens deklaration.

| Funktion | `canonical` med uttryckligt konfigurerat åtta-asset-manifest | `auto`, fortsatt `auto_eligible = false` |
| --- | --- | --- |
| `results()` | Fem finala nivåer; identiskt med full prototyp | Råväg, inte det partiella canonical-underlaget |
| `seats()` | Nationellt, 18 mandat; identiskt | Råväg |
| `candidacies()` | 500 dokumenterade positioner; identiskt | Råväg |
| `candidates()` | 500 rader; bägge `include_results`-lägen identiska; 114 NA i berikade P-summor kvar | Råväg |
| `elected()` | 18 rader; identiskt | Råväg |
| `substitutes()` | 68 relationer; identiskt | Råväg |
| `preference_votes()` | **Ostött för alla sex nivåer.** Stopp, inga tomma tabeller, ingen fallback | Befintlig råväg; kända källkonflikter kvar om arkiv finns |

Beroendena i de sex framgångsrika funktionerna är endast:

| Anrop | Lästa EU 2009-assets |
| --- | --- |
| `results()` | `eu2009-results-final` |
| `seats()` | `eu2009-seats-final` |
| `candidacies()` | `eu2009-candidacies` |
| `candidates(include_results = TRUE)` | `eu2009-candidates` |
| `candidates(include_results = FALSE)` | `eu2009-candidate-base` |
| `elected()` | `eu2009-elected` |
| `substitutes()` | `eu2009-substitutes` |

De färdiga kandidat-/valda-/ersättartabellerna läser inte om personröstbaserna
vid anropet. `eu2009-source-designations` är ett åttonde, fristående
reproducerbarhetsunderlag. Det används inte som ersättning för P.

Nuvarande explicit-canonical-läsare stoppar på ett saknat preferensasset med
`Unknown canonical asset: eu2009-preference-base-...`. Det är säkert men tekniskt
formulerat; det får inte beskrivas som fungerande personröststöd. Före eventuell
delleverans ska releasekatalog/help tydligt ange **sex stödda canonical-funktioner,
inte sju**, alla saknade P-nivåer, och den 114-raders berikningsbegränsningen.
Det partiella manifestet ska enbart deklarera faktiskt levererade assets/layouts;
man får inte publicera originalets fulla manifest och sedan utelämna sex filer.
Ett tydligare användarmeddelande kan bedömas separat; det finns ingen tyst
råfallback eller fabricerad lyckad tabell i dagens explicit-canonical-väg.

## Bedömning A / B / C och auto

- **A som formulerat: nej.** De 180 innehåller inga EU 2009-assets. Det ger
  noll canonical-vyer för 2009, inte partiellt stöd.
- **B: säkert men bredare än problemen motiverar.** Hela produkten hålls då
  tillbaka; API:s råstöd finns ändå kvar och kräver användarens egna källor.
  Det är inte fjorton olösta frågor, utan tre frågor som direkt berör sex baser
  och begränsar en kandidatberikning.
- **C rekommenderas:** 180 +åtta verifierade EU 2009-assets = **188**. Publicera
  sex uttryckligen avgränsade canonical-funktioner efter godkännande och ren
  rebuild, håll personröstvyn som prototyp. Kandidaturerna och de valda/
  ersättarrelationerna behöver inte invänta fördelningen av 34 eller 91 röster.

**Behåll `auto_eligible = false` nu**, både vid 180 och en eventuell 188-leverans.
Med 180 finns inget EU 2009-manifest att välja; att aktivera året skulle ge
konfigurationsfel före någon verifierad canonical-vy. Med åtta filer är framtida
auto för stödda vyer en möjlig separat prövning, eftersom den gemensamma
coverage-kontrollen är vybaserad. Det är inte beslutat och ska inte följa
implicit av publiceringen; P är fortfarande inte godkänt för canonical-auto.
Inga övriga valtillfällens urval eller flaggor ändras av rekommendationen.

## Kontrollernas omfattning och integritet

- Alla 14 befintliga filers SHA256/storlek och kontrakt verifierade.
- 35 olika anropsvarianter: fem resultatnivåer, mandat, kandidaturer, två
  kandidatlägen, valda, ersättare samt sex P-nivåer ×fyra list-/nollkombinationer.
- För varje variant provades canonical och auto med full prototyp, utan
  EU 2009-manifest, och med det minnesbaserade åtta-asset-urvalet. De elva
  lyckade icke-P-varianterna i delurvalet var exakt identiska med full prototyp,
  inklusive ordning, typer och attribut. Alla 24 P-varianter stoppade.
- Auto utan råarkiv valde aldrig prototypen, inte ens när hela 14-asset-manifestet
  uttryckligen var konfigurerat. Med användararkiv verifierades 35 råvägar fram
  till läsargränsen med en avsiktlig testmarkör; råfilerna lästes inte om här.
  Den tidigare fulla rå/canonical-valideringen kvarstår som innehållsreferens.
- Canonical-transporten i testprocessen var en kontrollsummaverifierad direktläsning
  av befintliga Parquet-filer, utan cachekopior/nätverk. Endast manifestinnehållet
  för hypotetiskt delurval filtrerades i minnet. Produktionsfunktionernas läsning,
  vyberäkning och presentation användes i övrigt oförändrade.
- Flerårs- och felårsförfrågningar samt ostött preliminary testades; inga
  ersättningsår eller tomma framgångsresultat returnerades.

Lokala bevis: `.local-data/eu2009-release-decision-20261021/`, särskilt
`physical-assets.csv`, `api-source-decisions.csv`, `api-source-audit.log` och
`decision-table.log`. Detta är riktade källvals-/beroendekontroller, inte en ny
bred test-/optimeringsomgång eller en ny canonical-build.

Den fullständiga lokala prototypen har fortsatt 14 assets och sanningsenligt
`build_tree_dirty = true`. Produktionsfiler, samtliga aktuella canonical-assets/
manifest och samtliga registry-/eligibility-fält verifieras oförändrade.
**Ingen commit, push eller GitHub Release.**
