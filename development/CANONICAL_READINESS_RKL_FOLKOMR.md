> Uppföljning 21 oktober 2026: de sex RKL-produkterna och folkomröstningen har lokala omkodade generationer enligt [värde- och lagringskontraktet](VALUE_CONTRACT.md), inklusive den granskade Ragunda-rättelsen 2018. Dessa arbetskopiebyggen har `build_tree_dirty = true`; gamla publicerade och validerade referenser bevaras oförändrade. Ren produktionsrebuild och separat publiceringsbeslut återstår. Ursprungsauditens fynd nedan avser dess tidigare generationer.

# Canonical-readiness: folkomröstning 2003, RD/RF/KF och omval

> Uppdatering 20 oktober 2026: T18/K18 har nu implementerats i arbetskopian.
> Se [2018-rättelserna](CANONICAL_2018_CORRECTIONS.md). Den nya lokala
> generationen är inte publicerad; ren-commit-reproduktion återstår eftersom
> implementationen enligt instruktion ska förbli ocommittad. Ursprungliga
> auditfynd och kontrollresultat nedan avser den frysta referensgenerationen.

Granskad 20 oktober 2026. Detta är en inventering av befintliga data och en
leveransbedömning, inte ett publicerings- eller aktiveringsbeslut.
Ursprungsauditen var read-only; den separat godkända 2018-uppdateringen redovisas nedan.
EU-materialet, inklusive dess rapporter, är uttryckligen utanför ändringsomfånget.

## Huvudslutsats

Det finns rena, byggda och tidigare rådatavaliderade lokala canonical-generationer
för RKL 2002, 2006, 2010, 2014, 2022 samt folkomröstningen 2003. De är inte
publicerade. Deras dokumenterade källbegränsningar ska följa med leveransen.
RKL 2018 är redan publicerad och auto-aktiverad, men granskningen identifierar
två konkreta problem inför fortsatt leverans: en saknad valresultaträttelse för
Ragunda KF och en felaktig explicit canonical-väg för preliminär räkning.

Inga canonical-produkter för RD/RF/KF 2026 eller de fem omvalen har påträffats.
Deras rådatastöd och lokala valideringsutdata är inte färdiga canonical-produkter.

**Redo** avser den specificerade funktionella täckningen, med godkända källval.
**Redo med dokumenterad begränsning** betyder att avgränsningen måste beskrivas
för användaren; det betyder inte att saknade observationer är konstruerade.
**Avvakta – konkret problem behöver lösas** används för identifierade fel.
**Tekniskt arbete återstår** används när canonical-produkt/distribution saknas.
Publiceringsversion, manifest-/assetplats och aktivering kräver separata beslut
även för innehållsmässigt färdiga produkter. Inget sätts automatiskt till `true`.

## Översikt: ordinarie val och folkomröstning

Vyer: **R** resultat, **S** mandat, **Cdy** kandidaturer, **C** kandidater,
**E** valda, **U** ersättarrelationer, **P** personröster.
"Ren lokal" betyder en faktiskt byggd canonical-generation med
`build_tree_dirty = false`, inte enbart en läsare eller byggplan.
Alla angivna råjämförelser gäller beslutade/stödda vyer, inte hypotetiska
kandidaturpopulationer eller personlänkningar som källorna inte etablerar.

| Familj | År/valtillfälle | Canonical finns / täckning | Råkällvalidering | Känd begränsning, tekniskt fynd, extern fråga | Rekommendation |
|---|---|---|---|---|---|
| Folkomröstning | 2003-09-14 | Ren lokal; R final, sex geografiska vyer | Ja; ny XML/SND/SCB-kontroll | F1: finfördelad väljarsammansättning saknas; full preliminär källa saknas | **Redo med dokumenterad begränsning** |
| RD | 2002 | Ren lokal; R/S/C/E/U/P final; inte Cdy | Ja; komplettering och webåtervinning validerade | H02: nio ej offentliggjorda supplementceller, fyra partiers finfördelning; kandidaturregister saknas; +547 mot SCB i personröstkontroll | **Redo med dokumenterad begränsning** |
| RF | 2002 | Ren lokal; samma sex funktioner; P utan listvy | Ja för tillgängliga vyer | H02: fyra verifierade områdeslistkonflikter; listvyer avvisas; +28 mot SCB i personröstkontroll; fråga till Valmyndigheten | **Redo med dokumenterad begränsning** |
| KF | 2002 | Ren lokal; samma sex funktioner; P utan listvy | Ja för tillgängliga vyer | H02: sexton verifierade områdeslistkonflikter; listvyer avvisas; fråga till Valmyndigheten | **Redo med dokumenterad begränsning** |
| RD | 2006 | Ren lokal; alla sju funktioner, final | Ja; separat SCB-kontroll | H06: +4 089 personröster i fem kretsar; källfråga öppen; nycklar avser källobservationer | **Redo med dokumenterad begränsning** |
| RF | 2006 | Ren lokal; alla sju funktioner, final | Ja; separat SCB-kontroll | H06: 102 dubbletter i SCB:s valideringstabell; separata källroller och begränsad personlänkning | **Redo med dokumenterad begränsning** |
| KF | 2006 | Ren lokal; alla sju funktioner, final | Ja; separat SCB-kontroll | H06: 38 personrösters källskillnad; tre parti/kommun-kombinationer saknar numerisk kod | **Redo med dokumenterad begränsning** |
| RD | 2010 | Ren lokal; alla sju; R preliminär/final, S final | Ja; preliminära officiella kontroller finns | H10: 171 kandidatsummor NA; godkända, strikt avgränsade ID-regler; svagare identitetsfall olösta | **Redo med dokumenterad begränsning** |
| RF | 2010 | Ren lokal; samma täckning | Ja | H10: nio helt orapporterade preliminära uppsamlingsdistrikt, partiell rapportering; 53 kandidatsummor NA | **Redo med dokumenterad begränsning** |
| KF | 2010 | Ren lokal; samma täckning | Ja | H10: nio helt orapporterade preliminära uppsamlingsdistrikt; tio kandidatsummor NA; fyra XML/medlems-ID-skillnader | **Redo med dokumenterad begränsning** |
| RD | 2014 | Ren lokal; alla sju; R preliminär/final, S final | Ja; XML/SKV/Excel/SCB | H14: 126 kandidatsummor NA; kandidatpopulation +1 mot SCB:s nominerade personer | **Redo med dokumenterad begränsning** |
| RF | 2014 | Ren lokal; samma täckning | Ja | H14: 113 kandidatsummor NA; kandidatpopulation −18 mot SCB, olika populationer | **Redo med dokumenterad begränsning** |
| KF | 2014 | Ren lokal; samma täckning | Ja; korrekt partiförkortning i ren generation | H14: 40 kandidatsummor NA; kandidatpopulation −177; personröstskillnad +394 är lokaliserad till omval/snapshots | **Redo med dokumenterad begränsning** |
| RD | 2018 | Publicerad fryst referens + ny lokal 20-asset-generation; alla sju, final | Ny raw/canonical-kontroll; finala partirader oförändrade | T18 avvisar nu preliminär begäran; ingen preliminär produkt konstrueras | **Tekniskt arbete återstår**: ren-commit-reproduktion och separat leveransbeslut |
| RF | 2018 | Samma omfattning | Ny raw/canonical-kontroll; finala partirader oförändrade | T18 löst i arbetskopian | **Tekniskt arbete återstår**: samma rena reproduktion |
| KF | 2018 | Ny lokal rättad generation; alla sju, final | Raw/canonical och den dokumenterade Ragunda-rättelsen | K18: 534885 ursprungligt vald, fem Stugubyn-röster; deras listfördelning är inte fastställd | **Redo med dokumenterad begransning**, efter ren-commit-reproduktion och leveransbeslut |
| RD | 2022 | Ren lokal; alla sju; R/S preliminär och final | Ja; bred rå/canonical-validering | H22: 14 kandidat–kretskombinationer/15 personröster mellan områdes- och distriktskälla; bevarad källskillnad | **Redo med dokumenterad begränsning** |
| RF | 2022 | Ren lokal; samma täckning | Ja; Norrbotten-rekonstruktion dokumenterad | H22: ursprungliga relationer och scoped Bo Larsson-rättelse; inga senare mandatperiodsbyten införda | **Redo med dokumenterad begränsning** |
| KF | 2022 | Ren lokal; samma täckning | Ja; tre korrigerade kandidatberikningar verifierade | H22: källspecifik missingness/okända nämnare; inga nya avvikelser identifierade | **Redo med dokumenterad begränsning** |
| RD | 2026 | Canonical saknas; rådataväg finns | Ingen canonical att validera | N26: bygg-/leveransprodukt saknas; öppen ID-/namnrollsfråga för kandidatvyer | **Tekniskt arbete återstår** |
| RF | 2026 | Canonical saknas; korrigerade råkällor aktiva | Korrigerad råkälla validerad; inte ett canonical-bygge | N26: använd 5 oktober-rättelsen; kandidatnamnsfrågan är inte en godkänd ID-harmonisering | **Tekniskt arbete återstår** |
| KF | 2026 | Canonical saknas; rådataväg finns | Ingen canonical att validera | N26: byggprodukt saknas; öppen ID-/namnrollsfråga | **Tekniskt arbete återstår** |

Detta är **22 separata familj × år-rader**. Att 2018 redan är aktivt ändras
inte av rapportens rekommendation; inga registerflaggor ändras här.
Statusarna avser uttryckligen de redovisade funktionerna, räkningarna och geografierna.
## Faktiskt valda generationer

Alla sju använder engelskt Parquet-schema 2. Assetantalet avser det gemensamma
RKL-årspaketet, inte samma antal separat för RD, RF och KF.

| Produkt | Vald lokal generation under `.local-data/canonical-build/` | Assets | Parquet-bytes | Byggcommit | Ren? | Publicerad? |
|---|---|---:|---:|---|---|---|
| RKL 2002 | `2002-web-clean-ca57c2f` | 14 | 13 817 649 | `ca57c2f` | Ja | Nej |
| Folkomröstning 2003 | `2003-clean-c65242a` | 1 | 552 678 | `c65242a` | Ja | Nej |
| RKL 2006 | `2006-clean-bf97568` | 15 | 32 549 598 | `bf97568` | Ja | Nej |
| RKL 2010 | `2010-r-only-clean-9b72617` | 24 | 45 573 472 | `9b72617` | Ja | Nej |
| RKL 2014 | `2014-r-only-clean-9b72617` | 24 | 48 241 797 | `9b72617` | Ja | Nej |
| RKL 2018 | `2018-clean-aab7c87` | 20 | 40 694 225 | `aab7c87` | Ja | Samma data som publicerad version |
| RKL 2022 | `2022-r-only-clean-9b72617` | 24 | 51 995 114 | `9b72617` | Ja | Nej |

**122 assets finns faktiskt och har verifierats.** De är inte 122 utlovade filer.
Den nuvarande officiella GitHub-releasen `data-v0.1.0` kontrollerades via release-API
samt dess nedladdade manifest. Den publicerade rena manifestcommitten är
`d297bb6b`; dess 20 assets, tabellayouter och källposter matchar den valda
rena 2018-reproduktionen. Olika byggdatum/byggcommit är inte olika valdata.
Manifestets äldre avsaknad av `auto_eligible`/`release_status` är inte ett
integritetsfel: den nuvarande registreringen styr den godkända 2018-aktiveringen.
Se [den befintliga releasen](https://github.com/richardohrvall/swelections/releases/tag/data-v0.1.0).

Övriga år är lokala, opublicerade valideringsprodukter. 2002/2003/2006/2010
har provisorisk dataversion `data-v0.0.0`, 2014 `data-v0.3.0`, 2022 `data-v0.2.0`.
En versionssträng bevisar inte att något har publicerats.

### Äldre/provisoriska generationer är inte leveransreferenser

- RKL 2002:s äldre 13-asset-generationer saknar den senare RD-distrikts-
  personröståtervinningen. Använd inte dem i stället för de 14 aktuella assetsen.
- 2003:s tidiga 43-kolumnsprototyp saknar de tre väljarsammansättningsfälten;
  aktuell asset har 46 fysiska kolumner och 20 694 rader.
- RKL 2010:s äldre 21-asset-generation saknar preliminära resultat. De aktuella
  24 assetsen innehåller dem, inklusive avsiktlig rapporteringsmissingness.
- 2014:s tidiga smutsiga prototyp hade felaktiga KF-partiförkortningar i valda.
  Det felet finns inte i den valda rena generationen. Äldre rapporters krav på
  clean rebuild beskriver deras dåvarande checkpoint, inte dagens faktiska lager.
- RKL 2018:s äldre RDS/schema-1-generationer är inte den publicerade schema-2-produkten.
- 2022:s tidiga prototyper föregår KF-beriknings-/sorteringsrättelserna. Den valda
  R-only-generationen innehåller dem och har clean-proveniens.
- Omvalens tillfälliga Parquet-filer från rundresetester är valideringsutdata,
  inte en versionerad canonical-release med manifest och läsare.

Inget nytt stort bygge behövs enbart för att de första checkpoint-rapporterna
sade `build_tree_dirty = true`. De faktiskt valda generationernas flaggor är
`false`. Inför slutlig publicering ska version/distribution bindas till den då
godkända committade produktionen och reproducerbarheten verifieras enligt vanlig
releaseprocedur. Den nuvarande arbetskopians nya ändringar är inte committade
bara för att de äldre datagenerationerna har clean-proveniens.

## Vilka assets behövs?

| Produkt | Nödvändig uppsättning för befintlig funktionell täckning |
|---|---|
| Folkomröstning 2003 | 1 resultatasset, sex geografiska tabeller. Tre giltiga röstalternativ; inga påhittade parti-/kandidat-/mandatassets. |
| RKL 2002 | 3 final-resultat, 1 final-mandat, 4 kandidat-/valda-/ersättar-/kandidatbasassets, 6 personröstassets = 14. Ingen kandidaturasset fabriceras. |
| RKL 2006 | Som 2002 plus verkliga dokumenterade kandidaturer = 15. |
| RKL 2010/2014 | 6 resultatassets för två stadier, 1 final-mandat, 5 kandidat-/populations-/relationsassets samt 12 personröst- och normaliserade basassets = 24. |
| RKL 2018 | 3 final-resultat, 1 final-mandat, 4 kandidat-/relationsassets samt 12 personröst-/basassets = 20. |
| RKL 2022 | 6 resultat, 2 mandatstadier, 4 kandidat-/relationsassets samt 12 personröst-/basassets = 24. |
| RKL 2026 | Ingen byggd canonical-uppsättning. Fastställ leveransinventering först när 2026-backenden ska byggas ut. |
| Omval | För nu implementerade omvalsvyer behövs final R/S med valhändelse, omfattning och källproveniens. Inte automatiskt sju vyer. Ingen sådan canonical-produkt finns ännu. |

Normaliserade baser och tabellayouter är funktionella beroenden, inte bara extra
exporter: de behövs för bland annat listvyer, stödd nollkomplettering och
urvalsberoende kandidatberikning. Leverera inte enbart de synliga analystabellerna.
`standard` och språkval kräver inte egna duplicerade Parquet-produkter.

### Geografisk och stadiebunden täckning

För RKL 2002/2006/2010/2014/2018 stöder finala resultat RD:s sex nivåer
(riket, län, riksdagsvalkrets, kommun, verklig kommunvalkrets, distrikt), RF:s
sex (riket, region, regionvalkrets, kommun, verklig kommunvalkrets, distrikt)
och KF:s fem (riket, län, kommun, verklig kommunvalkrets, distrikt).
Tekniska `00`-behållare är inte ytterligare kommunvalkretsar.
2010/2014 har motsvarande preliminära resultatnivåer, men endast finala mandat.
2002/2006/2018 har ingen komplett implementerad preliminär canonical-produkt.

2022 har tre resultatnivåer per valtyp: RD distrikt/riksdagsvalkrets/riket,
RF distrikt/regionvalkrets/region, KF distrikt/kommunvalkrets/kommun, för båda
räkningarna. Mandat finns på respektive två icke-distriktsnivåer, även preliminärt.
Att 2026 har fler JSON-geografier innebär inte att dessa finns i 2022-källan.

Folkomröstningen har sex resultatnivåer: riket, län, riksdagsvalkrets, kommun,
verklig kommunvalkrets och distrikt. Röstalternativen är inte politiska partier.

## F1 – folkomröstningen 2003

Slutresultatet är komplett för JA, NEJ, BLANK och kombinerat OG, med 290 kommuner,
5 976 vanliga distrikt och 396 onsdagsenheter. JA + NEJ + BLANK = 5 840 313 giltiga;
med 3 475 ogiltiga blir det 5 843 788 avgivna röster. BLANK är giltigt och ingår
inte i `invalid_votes`.

Tre disjunkta väljarkategorier är kompletta för riket och 21 län, summerar exakt
till 7 077 502 röstberättigade och är NA på kommun-, krets- och distriktsnivå.
Alla 396 onsdagsenheter saknar eget väljartals-/valdeltagandenämnarunderlag.
Ingen nedfördelning har gjorts. Full separat preliminär onsdagssnapshot har inte
återfunnits. Det är en återvinningsbegränsning, inte brist i finala rösträkningen.
Se [VALIDATION_2003.md](VALIDATION_2003.md).

## H02 – RKL 2002

Partiuppdelningen inklusive residualer och mandat är verifierade. Orsas ordinarie
15 september 2002 används; omvalet 16 mars 2003 ingår inte i ordinarie aggregat.
Halmstad 1380, Laholm 1381 och Kungsbacka 1384 saknar sina ursprungliga kommun-XML,
men distrikts-/kommunpartirösterna är kompletterade med verifierade SCB/SND-källor.
Personrösterna för dessa områden kommer från de 312 officiella Valmyndigheten-
webbsidorna, inte SCB/SND. Alla 5 852 återvunna observationer/26 835 röster finns.
Rapporterade RD-distriktspreferenser är kompletta för den verifierade populationen
6 266 enheter; okänd valsedelsposition i de nya raderna är inte en saknad röst.

Begränsningar som måste följa med publiceringen:

- Fullt kandidaturregister är inte återfunnet; `candidacies()` är avsiktligt
  ostött 2002. Kandidatnycklar är resultat-/källobservationer, inte personer.
- 41 523 RD-, 13 542 RF- och 8 675 KF-personröster finns endast aggregerade för
  övriga partier. De kan inte läggas på individuella kandidater utan källa.
- Fyra områdeslistkonflikter i RF och sexton i KF är dokumenterade. De berörda
  områdes-/distriktslistvyerna avvisas; canonical returnerar fel för saknad tabell,
  inte en fabricerad tom kandidatfördelning. Avvikelserna är frågor för
  Valmyndigheten; ingen ny fördelning görs. Förteckningen är inte en fullständig
  uppräkning av alla möjliga distriktslistfel.
- Nio av 116 celler i fyrpartisupplementet är ej offentliggjorda; 107 införda
  värden bevaras. Sju län–parti-projektioner är därmed okända och positiva
  korrigeringars lägre geografiska fördelning är inte fullständigt publicerad.
  Alla röster finns kvar i partitionen; residualer ska inte brytas upp genom gissning.
- Numeriska partikoder saknas i 21 854 RD-, 8 657 RF- och 6 318 KF-resultatrader;
  benämningar och röster är bevarade. Separata blank-/övrigt-ogiltigt-tal saknas:
  endast kombinerat OG är känt. XML-minus-SCB-personröster är +547 RD/+28 RF;
  KF överensstämmer. Dessa skillnader påverkar inte ordinarie partiröster/mandat.
- Inga verifierade preliminära uppsamlingsenheter har återfunnits. Valnatt
  exponeras inte som komplett preliminär räkning.

KF har 13 274 tilldelade mandat, 13 271 valda och tre obesatta positioner.
Kandidat-/personröstlänkningens missingness och exakta kategorier beskrivs i
[COMPLETENESS_2002.md](COMPLETENESS_2002.md). Detta är en färdig avgränsad
källprodukt, inte ett återfunnet komplett nomineringsregister.

## H06 – RKL 2006

Alla sju vyer bygger på dokumenterade valsedels-, resultat- och tillsättnings-
observationer. ID:n är käll-/kandidaturanknutna och säger inte att två poster på
olika listor avser samma person. Obekräftad personlänkning är inte en förlorad
personröstobservation.

RD:s detaljerade källa har 4 089 fler personröster än den separata officiella/
SCB-statistiken: krets 11 +433, 12 +493, 13 +564, 14 +532 och 28 +2 067.
KF:s detaljerade 1 554 153 överensstämmer med detaljerad SCB men avviker med 38
från Valmyndighetens separata 1 554 115. Ingen kandidat får ändrade röster för
att få dessa källor att stämma. Uppgifterna är källrapporterade, inte en garanti
att motstridiga publicerade aggregat är identiska. Frågan om KF 38 är öppen.

Övriga avgränsningar: tre KF parti/kommun-koder saknas (Vänsterdemokraterna,
Gnesta 0461 och Flen 0482; Kommunpartiet, Bengtsfors 1460); 102 exakta dubbletter
i RF:s SCB-valideringstabell bevaras i råkällan; supplementära småpartiröster kan
inte säkert länkas till listor/distrikt; komplett preliminär källa saknas.
KF:s 13 092 tilldelade mandat skiljs från 13 078 valda och 14 tomma positioner.
Se [VALIDATION_2006.md](VALIDATION_2006.md).

## H10 och H14 – RKL 2010/2014

2010 har 395/392/395 preliminära uppsamlingsenheter RD/RF/KF och 1 067 verifierade
officiella aggregatkontroller. Nio RF- och nio KF-enheter är helt orapporterade
med NA; 722 delrapporterade sidor och 4 213 tomma kategoriantal bevaras. Dessa
är delar av en publicerad rapporteringssnapshot, inte borttappade distrikt och
inte värden som får fyllas från finala XML-filer. Kandidatsummors missingness
171 RD/53 RF/10 KF är separat från bevarade observerade personröster.

2010:s enda godkända identitetsregler är de dokumenterade Björn Andersson-
kopplingarna till 442089, med RF:s rå-ID 451964 och den strikt scoped RD-
valsedelskopplingen. Fyra KF XML/medlems-ID-skillnader och sju svagare par är inte
automatiskt harmoniserade. Frågan om säkra medlems-/efterträdar-ID:n 2010–2014
är fortfarande extern och blockerar inte det avgränsade fasta valresultatet.
Se [SOURCE_ID_RECONCILIATION_2010.md](SOURCE_ID_RECONCILIATION_2010.md) och
[IMPLEMENTATION_2010_VALIDATION.md](IMPLEMENTATION_2010_VALIDATION.md).

2014:s preliminära resultat kombinerar valnattens vanliga distrikt och den
separata preliminära uppsamlingskällan, aldrig finala uppsamlingsröster.
Kandidatsummor är NA i 126 RD-/113 RF-/40 KF-fall. Jämförelsen med SCB:s
nominerade personer har residualer +1/−18/−177, efter beaktande av populationer.
Kandidat×parti-rader får inte förväxlas med SCB:s personantal.
KF-personröster +394 är lokaliserat: Båstad +403 (ordinarie val mot omval),
Nacka −3, Sigtuna −3, Bjuv −1 och Älvdalen −2 (snapshots).
KF:s partiförkortningsfix finns i den rena generationen. De 17 initiala
obesatta mandaten förblir obesatta, inte konstruerade personer.
Se [IMPLEMENTATION_2014_VALIDATION.md](IMPLEMENTATION_2014_VALIDATION.md).

## T18 – löst i arbetskopian: final-only canonical respekterar räkningen

Den frysta referensen återger bara slutlig räkning. Den tidigare explicita
canonical-dispatchen ignorerade en preliminär begäran och returnerade final.
Felet låg i source-logiken: `.canonical_source()` nådde 2018-läsaren före
råvägens räkningsguard. Det var inte ett fel i de finala röstsiffrorna.

En gemensam guard avvisar nu icke-finala 2018-anrop för resultat och mandat,
före manifest/asset-hämtning. Samma semantik gäller som för den stödda
rådatavägen. Regressioner täcker RD/RF/KF och svenska/engelska gränssnitt.
Inga preliminära assets konstrueras och finala partiröster ändras inte.

### Källspecifik missingness i de frysta 2018-resultaten

Samtliga 321 RD-, 320 RF- och 321 KF-uppsamlingsenheter saknar separat
`invalid_votes` och `total_votes` i de frysta distriktsvyerna. De 6 004/5 963/6 004
vanliga distrikten och rapporterade giltiga partiröster finns. Detta är en
annan dimension än T18/K18: saknade källfält får inte räknas fram genom att
fördela högre nivåers ogiltiga röster. Bevarad NA är inte noll eller en saknad
geografisk enhet. Dessa fält behöver beskrivas även efter de två rättelserna.

## K18 – rättad lokal generation: Ragundas ursprungliga tredje SD-ledamot

Den publicerade frysta generationen återger äldre XML: tre SD-mandat, två
valda och en vakans i Ragunda. Den ändras inte på distributionsplatsen.
Den nya lokala generationen innehåller den godkända rättelsen för kandidat
534885, stol 3, från 2018-09-09. VPN 877-2018 dateras separat 2018-12-12.
Inget administrativt verkställighetsdatum hittas på och inga senare
mandatperiodsförändringar förs in i det fasta valresultatet.

Kandidatur-/kandidat-/valda-/mandatbilden kompletteras. KF får 12 679 valda
och 21 initiala vakanser, med 12 700 tilldelade mandat oförändrade.
Övriga invalds- och ersättarrelationer bevaras. Historikens lista 0110-17638
och position 3 är källbelagda; uppgift om tryckt namnvalsedel och ej stödda attribut
är NA. Publika namn följer det etablerade NA-kontraktet.

Beslutet identifierar också fem personröster i Stugubyn (23030409). Dessa
ingår i områdes-/distriktsvyn och kandidatberikningen. De ursprungliga
listnumren för fyra tillskrivna namnvalsedlar och en partivalsedel anges
inte i beslutet. Listvyn bevaras därför och saknar denna femröstersfördelning.
Det reviderade länsprotokollet/underlaget behövs för att fylla just den
listfördelningen, inte för att återinföra osäkerhet om den rättade stolen.

Se [rättelse och reproduktion](CANONICAL_2018_CORRECTIONS.md) och
[förstudien](MANDATE_HISTORY_FEASIBILITY.md). Manifestet skiljer råsnapshot
från rättelseproveniens; originalfiler och den publicerade generationen
bevaras byteoförändrade. Ren-commit-reproduktion återstår efter granskning.

## H22 – RKL 2022

Rena assets innehåller de korrigerade KF-berikningarna. Kandidat 35910/12565/39734
har nu 3 575/205/477 i både kandidater och valda, med bevarad invaldsgeografi.
RF Norrbotten använder ursprungliga valda-/ersättarrelationer och endast den
godkända Bo Larsson-regeln 50975→488. Äldre råkällor är oförändrade och senare
mandatperiodsbyten blandas inte in. Detta är en explicit rekonstruktion, inte
ett påstående att en osparad officiell mellanfil har återfunnits.

Ny canonical-kontroll bekräftar de 14 RD kandidat–kretskombinationerna:
områdestotalen är 15 personröster högre än summan av rapporterade distriktsröster.
Tidigare jämförelser visar att områdesvärdena stöds av de fem kretsprotokollen
och den publika presentationen. Distriktsvärdena ändras eller omfördelas inte.
Källornas olika värden måste fortsätta framgå av proveniens/dokumentation;
detta är inte ett nytt normaliseringsfel. Okända partinämnare förblir NA.
Se [CANONICAL_2022_BUILD_VALIDATION.md](CANONICAL_2022_BUILD_VALIDATION.md).

På 2022 års kretsnivåer saknas källans `total_votes` för 29 RD-kretsar,
53 RF-kretsar och 41 KF-kretsar, både preliminärt och finalt. Kända giltiga/
ogiltiga värden bevaras; ett saknat uttryckligt totaltal görs inte till noll.
Detta är verifierad källmissingness, inte ett nytt tapp i Parquet-transformeringen.

## N26 – 2026: korrigerade källor är inte en canonical-produkt

Det finns ingen registrerad 2026-canonical-läsare, inget 2026-manifest och inga
färdiga 2026-canonical-assets i den undersökta samlingen. Råfunktionernas stöd
ska inte beskrivas som färdig canonical. Bygginventering, manifest/proveniens,
byggverktyg och full canonical/rå-validering återstår för RD/RF/KF.

RF:s rättade filer från 5 oktober 2026 är aktiva och tidigare verifierade:
−4 002 giltiga röster i fyra Norrtäljedistrikt, −612 personröster i Nordost,
ändrad valgrund för Britt Mari Canhasi (ID oförändrat) och oförändrad
mandattilldelning. Det är en färdig råkällaktivering, inte ett canonical-bygge.
Se [RF_2026_SOURCE_CORRECTION.md](RF_2026_SOURCE_CORRECTION.md).

ID-/namnrollsfrågan för 2026 är fortfarande extern. Det tidigare bevarade
underlaget omfattar nationell RD, 290 KF och RF Stockholm, inte alla RF-regioner.
Olika listnamn och folkbokföringsnamn får inte automatiskt klassas som olika
personer eller rättas genom namnmatchning. Ingen ny identitetsregel införs här.

## Omval: egna valhändelser, ännu inga canonical-produkter

| Familj / händelse | Råstöd och verifierad omfattning | Canonical / nödvändigt återstående arbete | Status |
|---|---|---|---|
| KF Orsa 2003-03-16 | Final R/S, 31 mandat; skilt från ordinarie 2002 | Manifest, assets, canonical-läsare och leveransvalidering saknas | **Tekniskt arbete återstår** |
| RF Västra Götaland 2011-05-15 | Final R/S, 149 mandat; samma mandatperiod som 2010 | Samma canonical-arbete; jämförelsefiler är råunderlag, inte assets | **Tekniskt arbete återstår** |
| KF Örebro Nordöstra 2011-05-15 | Final R/S för 17 mandat; ingen ny kommunomfattande 2011-räkning | Event-scope måste bevaras i framtida produkt | **Tekniskt arbete återstår** |
| KF Båstad 2015-05-10 | Final R/S, 41 mandat | Ingen canonical-produkt ännu | **Tekniskt arbete återstår** |
| KF Falun 2019-04-07 | Final R/S, 61 mandat | Ingen canonical-produkt ännu | **Tekniskt arbete återstår** |

De fem eventraderna är verifierade i `election_events()` med
`canonical_available = false`. Råimplementationen avvisar explicit canonical.
`seats(after_re_election = TRUE)` är en härledd komponentkomposition, inte
omvalets egen mandatfördelning. För Örebro kombineras 48 opåverkade 2010-mandat
med 17 från omvalet till 65; ordinarie valår/mandatperiod är fortfarande 2010.
Det finns ingen separat canonical-kompositionsprodukt. En framtida sådan måste
behålla varje komponents proveniens och får inte räknas fram genom en ny
kommunomfattande mandatallokering på blandade röster.

Full kandidatur-/personröst-/medlemshistorik blir inte obligatoriska omvalsassets
bara för att sju funktioner finns för ordinarie val. Implementerad omvalstäckning
är R/S. Kandidatunderlag från source-inventeringen ska bedömas separat innan
fler vyer utlovas. Okända beslutsreferenser/datum och oåterfunna Orsa-protokoll-
bilagor är specificerade källluckor; inte skäl att omtolka eventets 31 mandat.
Se [SOURCE_INVENTORY_OMVAL.md](SOURCE_INVENTORY_OMVAL.md),
[IMPLEMENTATION_OMVAL.md](IMPLEMENTATION_OMVAL.md) och
[VALIDATION_OMVAL.md](VALIDATION_OMVAL.md).

Mandatperiodshistorik och datumfrågor om innehavare/vakanser är ytterligare en
produkt med lokala medlemskällor. De täcks inte automatiskt av originalvalens
mandat-/valda-assets. Ingen ny canonical-historikprodukt påstås finnas här.

## Valideringens omfattning och lokala bevis

Arbetsmaterialet finns i `.local-data/non-eu-canonical-readiness-20261020/`:

- `all-manifests.csv` inventerar även äldre/smutsiga/legacy-generationer.
  `profiles.log` redovisar den valda generationens faktiska assets och metadata.
- `audit.log`, `assets.csv`, `requests.csv`, `summary.csv`: 122 assethashar,
  storlekar, rader, tabellkolumner och exakta Parquet skriv-/läsrundresor; 124
  relevanta funktion×valtyp×år-kombinationer i fyra språk-/detaljvarianter
  (496 jämförelser) på defaultvyerna. Kandidaturer och mandat påstås inte
  existera för val där de inte är meningsfulla/stödda.
- `publication.log`, `published-manifest.json`, `published-assets.csv`: faktisk
  GitHub-release och matchning mot publicerade 2018-asset-/käll-/layoutmetadata.
- `source-integrity-2010-2022.log`: 9 529 bevarade källposter och 92 assethashar
  verifierade på nytt med tidigare integritetsprocedur; 20 extra rundresor.
- `validate-2003.log`: ny körning av befintlig oberoende XML/SND/SCB-validator,
  alla sex geografier och språk-/detalj-/raw/canonical-varianter.
  `validate-electorate-2003.log`: 22 oberoende SCB-gruppkontroller och 16
  national-/länspar; finare typad missingness och Blank-semantik bevarade.
- `validate-complement-2002.log`: 1 697 nya numeriska SCB/SND/publikationskontroller
  för de tre kompletterade RD-kommunerna. Kungsbackas källspecifika nämnare
  48 602 på distriktsunderlaget och 48 603 i Valmyndighetens kommun-XML blandas inte.
- `validate-scb-2006.log`: samtliga 8 712 oberoende SCB-kontroller passerar.
- `target-2022.log`: de tre KF-fallen, Bo Larsson 488 och exakt 14/15 RD-differens.
- `ragunda.log` och dess CSV-filer: exakt skillnad mellan fryst canonical och
  den godkända historikrättelsen. `2018-stage-bug.csv`/`stage-2018.log`: sex
  reproducerade felaktiga explicita preliminäranrop; auto/local avvisar korrekt.
- `exceptions.log`: de fyra saknade RF/KF-listvyerna 2002 avvisas faktiskt;
  `unavailable_views` i manifestet förklarar varför. Eventmetadata sparas separat.

- `geography.csv`/`geography.log`: 143 faktiska lagrade resultatvyer, inklusive
  samtliga deklarerade nivåer/stadier. De 18 helt orapporterade 2010-enheterna
  är kontrollerade som NA och uppräknade i `2010-unreported-rf.txt` och
  `2010-unreported-kf.txt`.
- `focused-tests.log`: befintliga source-selection-, canonical-backend- och
  referendumtester passerar med **479 assertions, inga skips/fel/varningar**.
  Dessa testsviter täcker inte de nya 2018-felen med negativa regressioner;
  deras gröna utfall ska inte misstolkas som att T18/K18 är lösta.

Tidigare fullständiga rå/canonical-svep återanvänds som historisk evidens för
respektive ren generation; denna audit är inte en ny full rådataparsning av alla
år, distrikt och list-/nollkombinationer. Den nyligen genomförda gemensamma
840-jämförelse-regressionen och fulla paketkontrollen (4 494 godkända tester,
16 explicita skips; `R CMD check` 0 fel/0 varningar/0 notes) gäller samma
oförändrade produktionskod. Den är tidigare evidens, inte en ny full svit här.
En grön råjämförelse med gammal XML kan inte bevisa att Ragundas senare
valresultaträttelse finns med. Nya regressioner måste täcka de identifierade felen.

Auditens första lokala kontrollantaganden justerades till verkliga scheman:
RF/KF-default är inte ett enda riksaggregat, och äldre valda använder generisk
`elected_electoral_area_code`. Detta ändrade inga produktionsfält eller källvärden.

## Externa frågor och deras betydelse för leverans

| Produkt | Extern fråga / återstående officiellt stöd | Blockerar vad? |
|---|---|---|
| Folkomröstning 2003 | Ingen extern fråga behövs för den kompletta finala rösträkningen; finare väljarkomponenter är inte återfunna | Blockerar inte avgränsad final-produkt |
| RKL 2002 | De 20 områdeslistfallen, RD/RF-personröstskillnader och saknat helt kandidaturregister är specifika källfrågor | Blockerar fullständiga list-/kandidaturanspråk, inte verifierade finala parti-/mandatresultat |
| RKL 2006 | RD +4 089 och KF 38 är källkonflikter; uppdelning i vissa källroller/partikoder saknas | Kräver synlig källkvalifikation; inga fabricerade korrigeringar eller personjoins |
| RKL 2010 | Fyra KF medlems-/XML-ID-par, sju svagare identitetspar och 2010–2014:s efterträdar-ID-länkning | Blockerar säker person-/mandatperiodslänkning, inte source-observationerna i fasta valresultatet |
| RKL 2014 | SCB-populationsresidualer och snapshotavvikelser dokumenterade; inget ytterligare individuellt underlag identifierat för tvångsreconciliation | Inget känt externt blockerande svar för beslutad täckning |
| RKL 2018 | Reviderat länsprotokoll/underlag behövs för de fem rättade personrösternas exakta listfördelning och administrativ verkställighetsdag | Inget av detta skapar osäkerhet om den styrkta ursprungliga stolen eller valdagens start; fördelningen lämnas okonstruerad |
| RKL 2022 | Förklaringen till RD:s 14/15 distriktsavvikelse är en kvarvarande källfråga; protokoll stöder områdesvärdena | Ingen godtycklig omfördelning; blockering behöver inte gälla en öppet källkvalificerad produkt |
| RKL 2026 | Valmyndighetens besked om namnroller/identifierare avvaktas | Kräver separat hantering före löften om identitet, inte en automatisk ändring av namn eller ID |
| Omval | Specificerade oåterfunna protokollbilagor/beslutsdatum; råa finala R/S är verifierade | Utred provenienskrav vid framtida canonical-leverans; inga datum eller relationer fabriceras |

Tabellen anger frågestatus och behov, inte ett påstående att nya meddelanden har
skickats under auditten. Inga kontakter eller nya breda källsökningar har gjorts.

## Ursprungliga rekommendationer (T18/K18 nu genomforda; se uppdatering)

1. Granska och godkänn separat T18:s räkningsguard; implementera därefter
   en liten kodrättelse och negativa regressioner. Finala RD/RF-assets behöver
   inte ändrade värden för denna rättelse.
2. Granska separat K18:s fasta Ragunda-rättelse. Fastställ nödvändiga officiella
   relations-/personröstdetaljer, bygg rättad KF/candidate-/relationsprodukt och
   verifiera alla övriga 2018-värden oförändrade. Publicerad data får inte
   ersättas som en del av en odokumenterad metadataändring.
3. För redo-produkterna 2003/2002/2006/2010/2014/2022: besluta om dokumenterade
   avgränsningar, riktiga releaseversioner, separata manifest-/assetplatser och
   vilka vyer som senare får automatisk användning. Behåll exakta källskillnader.
4. Planera 2026 och omval som nya canonical-leveranser; förväxla inte detta med
   att deras resultatläsare redan fungerar. Hantera externa namn-/ID-frågor utan
   nya ogrundade personharmoniseringar.
5. Låt EU-materialet stå kvar enligt dess egen avslutade audit. Inga EU-flaggor
   eller 2009-modeller ändras genom dessa beslut.

Ingen commit, push, publicering, ändrad aktivering eller ändring av befintliga
canonical-data har gjorts i denna audit.

## Ursprungsauditens andringskontroll

`final-check.log` verifierar att endast denna utvecklingsrapport har tillkommit.
Alla 346 tidigare spårade/ospårade arbetsfiler är byteoförändrade, liksom 122
kontrollerade icke-EU-assets och 108 skyddade EU-asset-/manifestfiler.
EU-rapporterna är oförändrade. Alla EU-flaggor förblir false; endast den redan
aktiva RKL 2018-registreringen är fortsatt true. `git diff --check` samt separat
whitespacekontroll av den nya rapporten passerar. Inga käll-/canonicalfiler har
lagts till i Git. Den redan befintliga orena arbetskopian har inte städats eller
committats som del av auditen.

## Genomförd 2018-uppdatering inför leverans

T18 och K18 är implementerade och validerade i en ny lokal generation under
`.local-data/canonical-2018-corrections-20261020/parquet/`. Den innehåller
20 assets: 8 ändrade enbart för Ragunda, 12 byte-identiska med referensen.
Alla tre partiröst-assets och ersättartabellen är oförändrade.
Se [exakta skillnader och valideringar](CANONICAL_2018_CORRECTIONS.md).

168 publika raw/canonical-jämförelser och 713 integrationsassertioner passerar.
Hela testsviten har 4 539 godkända tester, 16 uttryckliga skips och inga fel
eller varningar. R CMD check har 0 fel, 0 varningar och 0 noter. Manifest,
checksummor, 20 Parquet-rundturer, 840 historiska regressioner och skyddade
referensfiler är verifierade. Originala råfiler och publicerad data-v0.1.0
är orörda.

Ett ärligt bygge med de ännu ocommittade ändringarna anger
`build_tree_dirty = true`. Ren-commit-reproduktion återstår efter granskning;
kraven att både inkludera ändringen och inte committa tillåter inte att den
redan genomförts. Inför publicering krävs också ny dataversion, valda
manifest-/assetplatser och separata aktiveringsbeslut. Publicerade 2018-assets
får inte ersättas i den gamla releasen.

EU 2004, 2014, 2019 och 2024 förblir tekniskt färdiga enligt sin granskning,
med respektive dokumenterad källbegränsning. EU 2009:s frågor om 91 geografiskt
ofördelade röster, 34 gemensamma Per Johansson-röster och 102 ej listkopplade
kandidatkolumner kvarstår. Samtliga EU-flaggor är fortfarande false. Ingen
EU-fil, release-asset, kandidat-ID-regel eller source-design har ändrats här.
