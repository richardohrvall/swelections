# Releasekandidat: slutlig canonical-inventering

Datum: 21 oktober 2026. **Inventering, inte publicerings- eller aktiveringsbeslut.**
Ingen produktionskod, canonical-data, källfil eller eligibility-flagga ändras.

## Slutsats

Vi kan gå vidare till separat godkänd commit och ren rebuild av den granskade
implementationen. Ingen asset eller deklarerad vy har fallit bort.

Det finns **194 aktuella Parquet-assets i tolv produkter**. Alla följer
`data-v0.4.0`, schema **3**, value contract **1**, storage contract **1** och
har sanningsenligt `build_tree_dirty = true`. De omfattar 598 deklarerade
layout-/underlagstabeller; detta är inte 598 olika publika funktioner.

**Publiceringsurvalet är ännu inte slutligt beslutat.** Min rekommendation är
180 assets i elva produkter efter ren rebuild och godkännande, med EU 2009:s
14 assets kvar som explicit testbar prototyp tills den offentliga
personröstrepresentationen beslutats. Inget har exkluderats ur det lokala
194-asset-lagret genom denna rekommendation. Inga 2009-värden ändras.

## 214 jämfört med 194

Den tidigare kategoriska auditten inventerade **generationer**, inklusive både
den gamla publicerade/frysta och den granskade Ragunda-rättade RKL 2018-versionen.
Den räknade därför 13 generationer av tolv produkter, inte 214 unika aktuella
asset-ID:n. De två 2018-generationerna har samma 20 filnamn/asset-ID:n.

| Produkt/generation i tidigare 214 | Tidigare | Aktuella enligt nytt kontrakt |
| --- | ---: | ---: |
| RKL 2002 | 14 | 14 |
| RKL 2006 | 15 | 15 |
| RKL 2010 | 24 | 24 |
| RKL 2014 | 24 | 24 |
| RKL 2018, gammal publicerad/fryst generation | 20 | 0; ersatt i aktuellt urval |
| RKL 2018, granskad Ragunda-rättad generation | 20 | 20 |
| RKL 2022 | 24 | 24 |
| Folkomröstning 2003 | 1 | 1 |
| EU 2004 | 14 | 14 |
| EU 2009 | 14 | 14; publiceringsfråga öppen |
| EU 2014 | 14 | 14 |
| EU 2019 | 15 | 15 |
| EU 2024 | 15 | 15 |
| **Summa** | **214** | **194** |

Fullständig fil-för-fil-redovisning finns i
[CANONICAL_RELEASE_ASSET_INVENTORY.csv](CANONICAL_RELEASE_ASSET_INVENTORY.csv):
214 rader med tidigare produkt/generation, exakt asset-ID, filnamn, manifest,
SHA256, radantal och aktuell ersättning. Filtrera `in_current_194 = TRUE` för
exakt de 194 aktuella assetsen; `FALSE` ger exakt de 20 historiska 2018-filerna.
Ersättningsuppgifter på dessa 20 rader är länkar till de aktuella filerna,
inte ytterligare 20 assets. `release_recommendation` är en rekommendation,
inte en ändrad konfiguration.

De 20 ska **inte byggas en andra gång eller ingå som ytterligare en aktiv
2018-produkt**. Deras ersättare är redan omkodade från den granskade rättade
generationen. Den gamla publiceringen/referensen bevaras oförändrad som historik.
Före värdenormaliseringen var tolv av filerna byte-identiska mellan de två
2018-generationerna och åtta skilde sig genom den godkända Ragunda-rättelsen.
Det är alltså två versioner av samma produkt, inte tjugo identiska byte-dubbletter.

## Aktuellt releaseunderlag per produkt och valtillfälle

Vyer: **R** `results()`, **S** `seats()`, **Cd** `candidacies()`,
**C** `candidates()`, **E** `elected()`, **U** `substitutes()`,
**P** `preference_votes()`. Standard/full och svenska/engelska är presentationer
av samma underlag och behöver inte separata Parquet-filer.

Samtliga rader nedan följer det nya kontraktet. RKL-antalet är gemensamt för
RD/RF/KF, inte samma antal tre gånger. Kandidatbaser, partibeteckningstabeller,
personröstbaser och övriga funktionella beroenden ingår i filinventeringen;
endast slutliga analystabeller räcker inte som leverans.

| Produkt / ordinarie valdag | Assets | Vyer och räkningsstadier | Publiceringsrekommendation | Auto nu / senare möjlighet |
| --- | ---: | --- | --- | --- |
| RKL 2002 / 2002-09-15 | 14 | R/S/C/E/U/P final; inget komplett Cd-register | Redo med specificerade källbegränsningar efter ren rebuild | Nej / möjligt för stödda vyer efter beslut |
| RKL 2006 / 2006-09-17 | 15 | Alla sju; final | Redo med specificerade källbegränsningar efter ren rebuild | Nej / möjligt efter beslut |
| RKL 2010 / 2010-09-19 | 24 | Alla sju; R preliminary/final, S final | Redo med specificerade källbegränsningar efter ren rebuild | Nej / möjligt efter beslut |
| RKL 2014 / 2014-09-14 | 24 | Alla sju; R preliminary/final, S final | Redo med specificerade källbegränsningar efter ren rebuild | Nej / möjligt efter beslut |
| RKL 2018 / 2018-09-09 | 20 | Alla sju; final; preliminary avvisas | Rättad efterträdare till gamla publiceringen, efter ren rebuild | Ja i registret; aktuell lokal manifest krävs / ny URL efter beslut |
| RKL 2022 / 2022-09-11 | 24 | Alla sju; R/S preliminary/final | Redo med specificerade källbegränsningar efter ren rebuild | Nej / möjligt efter beslut |
| Folkomröstning / 2003-09-14 | 1 | Endast R final, sex geografiska nivåer; yes/no/blank och separat invalid | Redo med specificerad väljarsammansättnings-/preliminärbegränsning | Nej / möjligt för R efter beslut |
| EU 2004 / 2004-06-13 | 14 | Alla sju; final | Redo med 943-aggregatet och kandidaturidentitet dokumenterade | Nej / möjligt efter beslut |
| EU 2009 / 2009-06-07 | 14 | Alla sju; final; P behåller konfliktkolumner | **Avvakta publicering som färdig hel produkt**; beslut om P krävs | Nej / inte redo för oförbehållen auto |
| EU 2014 / 2014-05-25 | 14 | Alla sju; final | Redo med Vårdsbergs tio röster och övriga källgränser dokumenterade | Nej / möjligt efter beslut |
| EU 2019 / 2019-05-26 | 15 | Alla sju; R/S preliminary/final | Redo med dokumenterade populationsskillnader | Nej / möjligt efter beslut |
| EU 2024 / 2024-06-09 | 15 | Alla sju; R/S preliminary/final | Redo med dokumenterad snapshot-avvikelse för 1203 | Nej / möjligt efter beslut |

Exakta produktantal, bytes, kontraktsversioner, manifesthashar och befintliga
flaggor finns i [CANONICAL_RELEASE_PRODUCTS.csv](CANONICAL_RELEASE_PRODUCTS.csv).
Endast RKL 2018 har `auto_eligible = TRUE` i registret. Dess manifest saknar
separat flagga; tom CSV-cell är inte `FALSE` och registret styr. Övriga elva
registerposter och alla fem EU-år är fortsatt `FALSE`. En publicering innebär
inte automatiskt godkännande för auto. Nuvarande nya produkter kräver lokalt
konfigurerade manifest; någon ny publik fjärrplats är inte aktiverad.

## Specificerade begränsningar per valfamilj

Detta är leveransavgränsningar, inte skäl att ändra röster eller uppfinna
kandidatidentiteter. Detaljer och geografier finns i de länkade readiness- och
valideringsrapporterna; de ska följa med en publicering.

| Familj / år | Konkret avgränsning och eventuellt ytterligare innehållsarbete |
| --- | --- |
| RD 2002 | Nio ej publicerade supplementceller av 116; finfördelning av fyra småpartier inte komplett; 41 523 övrigpartipreferenser endast aggregerade; +547 mot SCB:s separata personröstkontroll. Finala partiröster täcker även de tre kompletterade kommunerna. |
| RF 2002 | 13 542 övrigpartipreferenser endast aggregerade; fyra områdeslistkonflikter, listvyer avvisas; +28 i separat SCB-personröstkontroll. |
| KF 2002 | 8 675 övrigpartipreferenser endast aggregerade; sexton områdeslistkonflikter, listvyer avvisas; 13 274 tilldelade mandat, 13 271 valda, tre obesatta. |
| RD/RF/KF 2002 gemensamt | Inget återfunnet komplett kandidaturregister, inga verifierade preliminära uppsamlingsenheter; separat blank/övrigt-ogiltigt saknas, kombinerat OG finns. Numeriska partikoder saknas i 21 854/8 657/6 318 resultatrader. Resultatnycklar är inte verifierade personer. De tre saknade kommun-XML-filerna ersätts för partiröster av reconcilerad SCB/SND och för återvunna P av Valmyndighetens 312 webbsidor; XML-specifik information kan inte återskapas. |
| RD 2006 | Detaljkällan +4 089 personröster i fem kretsar mot separat statistik; känt källproblem, ingen justering. |
| RF 2006 | 102 dubbletter i SCB:s valideringstabell bevaras i råkällan; käll-/kandidatur-ID, inte personlänkning. |
| KF 2006 | 38 personrösters källskillnad; tre parti/kommun-kombinationer utan numerisk kod; 13 092 tilldelade mandat, 13 078 valda, 14 obesatta. |
| RD/RF/KF 2006 gemensamt | Full preliminär uppsamlingskälla saknas; småpartisupplement kan inte fullständigt länkas till listor/distrikt; personidentitet inte etablerad över kandidaturer. |
| RD 2010 | 171 kandidatsummor NA; endast redan godkända och avgränsade identitetsregler tillämpade. |
| RF 2010 | 53 kandidatsummor NA; nio helt orapporterade preliminära uppsamlingsenheter behålls med NA. |
| KF 2010 | Tio kandidatsummor NA; nio helt orapporterade preliminära uppsamlingsenheter; fyra resultat-/medlems-ID-konflikter bevaras. |
| RD/RF/KF 2010 gemensamt | Alla 722 delrapporterade preliminära sidor och 4 213 tomma kategoriantal bevaras; sju svagare identitetspar lämnas olösta. Senare medlemshistorik redefinierar inte valresultatet. |
| RD 2014 | 126 kandidatsummor NA; kandidatpopulation +1 mot SCB:s personpopulation. |
| RF 2014 | 113 kandidatsummor NA; kandidatpopulation −18 mot SCB. |
| KF 2014 | 40 kandidatsummor NA; kandidatpopulation −177 mot SCB; +394 personröster lokaliserade till Båstad-omval/snapshotskillnader; 17 initialt obesatta mandat kvarstår. |
| RD/RF/KF 2018 | Final-only. Separata invalid/total-värden saknas för 321/320/321 uppsamlingsenheter; enheterna och giltiga partiröster finns. Ingen sådan missingness fylls från andra nivåer. |
| KF 2018, Ragunda | Rättad ursprunglig innehavare 534885 från 2018-09-09, rättelse 2018-12-12. Fem Stugubyn-personröster finns i icke-listvyer; deras ursprungliga listfördelning är inte belagd och konstrueras inte. |
| RD 2022 | 14 kandidat–kretskombinationer med 15 rösters skillnad mellan områdes- och distriktskälla; värden/proveniens bevarade. |
| RF 2022 | Dokumenterad Norrbotten-rekonstruktion av ursprungliga relationer och strikt avgränsad Bo Larsson-regel; ingen senare medlemsförändring införd. |
| KF 2022 | Korrigerade kandidat-/valda-berikningar bevarade; okända nämnare förblir NA. |
| RD/RF/KF 2022 gemensamt | `total_votes` saknas i källan på 29/53/41 kretsnivåer i båda stadierna; inte samma sak som saknade röster. |
| Folkomröstning 2003 | Väljarsammansättning komplett endast för riket och 21 län, inte lägre nivåer; ingen nedfördelning. 396 onsdagsenheter saknar egna väljartals-/turnout-nämnare. Full preliminär onsdagssnapshot saknas. Blank är ett giltigt alternativ. |
| EU 2004 | 943 giltiga handskrivna röster kvar som aggregat utan individuell partibeteckning; kandidaturer är listpositioner, inte verifierade personer; full preliminär onsdagssnapshot saknas. SD:s korrekta 14 450 personröster används i stället för felaktiga SSD-nollor. |
| EU 2009 | 34 gemensamma röster utan kandidatallokering mellan Per Johansson-positionerna; 91 utan säker finfördelning; 102 resultatkolumner utan verifierad lista/position. Dagens småpartidistriktsvyer har även 23 ännu inte införda entydigt härledbara röster, totalt 114 geografiskt ofördelade. Officiellt total 1 876 785, kandidatrader nationellt 1 876 795. Inget nytt residualupplägg implementeras. Full preliminär onsdagssnapshot saknas. |
| EU 2014 | Tio giltiga handskrivna Vårdsberg-röster med orapporterad partibeteckning; Socialisterna=0 utan numerisk kod; historiska namn/attribut saknas där de gallrats; full preliminär onsdagssnapshot saknas. |
| EU 2019 | Preliminärt tio särredovisade partier + övrigaggregat. Giltig kandidatpopulation 556 av 562 kandidaturer; 7 455 röster för ogiltiga kandidat–partirelationer finns i P men inte i giltiga kandidaters summering. Väljarkåren är den reconcilerade 7 576 917. |
| EU 2024 | Kandidat 1203 finns endast i tidigare snapshot, ingen resultat-/P-/mandatpåverkan. 1 395 kandidaturer, 1 390 giltiga rader och 1 385 kandidatrader är skilda populationer; 2 324 röster för fem ogiltiga relationer bevaras i P. |

Dessa begränsningar bedöms enligt [RKL/folkomröstnings-readiness](CANONICAL_READINESS_RKL_FOLKOMR.md)
och [EU-readiness](CANONICAL_READINESS_EU.md). De öppna 2002/2006/2010/2022-
källfrågorna innebär ingen ny ändring av den tidigare godkända avgränsningen.
EU 2009:s offentliga P-representation är däremot fortfarande ett konkret beslut,
inte bara en fotnot som gör konfliktkolumnerna till verifierade kandidatvärden.

## Inte canonical-assets i denna releaseinventering

- **RD/RF/KF 2026:** inga byggda canonical-produkter; korrigerade RF-råkällor är
  inte en canonical-release. Återstår att implementera/bygga/validera separat.
- **Omval:** Orsa KF 2003-03-16; Västra Götaland RF och Örebro Nordöstra KF
  2011-05-15; Båstad KF 2015-05-10; Falun KF 2019-04-07. De har R/S-råstöd,
  men inga versionerade canonical-manifest/assets/läsare. De fanns inte i de
  tidigare 214 heller. Örebros 17 eventmandat och 65-mandatskomposition är inte
  extra lagrade canonical-produkter.
- **Mandatperiodshistorik:** råbaserade intervall och datumfrågor, ingen separat
  byggd canonical-historikprodukt. Inte ett bortfall ur 214→194.
- **Valnatt och saknade preliminära stadier:** inga nya tillfällen/stadier
  konstrueras för att fylla denna inventering. Originalkällor är provenance.

Folkomröstning 2003 och Orsa-omval 2003 är separata familjer/tillfällen; ett
årtal i båda fallen innebär inte att omvalet ingår i folkomröstningens asset.

## Ny kontroll av releasekandidaten

- Alla **214 äldre inventerade filer** matchar auditens lagrade SHA256.
- Alla **194 aktuella filer** matchar både aktuella manifest och senaste
  godkända normaliseringsvaliderings SHA256, storlek och radantal.
- Samtliga **598 deklarerade tabellnycklar** motsvarar tidigare godkända
  nycklar efter exakt den beslutade språk-/lagringsöversättningen. Alla tolv
  ursprungliga källinventeringar är oförändrade. Ingen vy tappad.
- Alla **20 aktuella 2018-filer** är exakt den godkända Ragunda-rättade
  referensen efter enbart beslutad value/storage-transformering. Kandidat
  534885, SD 0110, Ragunda 2303, invaldsordning 3 och fem personröster verifierade;
  tre SD-mandat och noll obesatta i kommunen. KF totalt har 12 700 tilldelade = 12 679 valda + 21 obesatta mandat. Totalkontrollen summerar kommunnivån separat; kommunvalkretsrader läggs inte ovanpå samma mandat. Start 2018-09-09 och separat
  beslutsdatum 2018-12-12 finns i manifestets rättelseproveniens.
- Alla **1 300 skyddade referensfiler** är byteoförändrade. De 194 aktuella
  tillgångarna och deras tolv manifest kontrolleras också före/efter inventeringen.
- Befintlig slutvalidering är fortsatt referens: 4 633 tester passerade,
  16 explicita skips, `R CMD check --no-manual` 0 fel/0 varningar/0 notes,
  600 historiska rå/canonical-jämförelser, 856 canonical-anrop och elva
  avgränsade 2026-råurval. Ingen kod har ändrats nu, därför har hela testsviten
  inte körts om enbart för denna dokumentationsinventering.

Läsande R-kontroller och lokala bevis finns i
`.local-data/release-candidate-inventory-20261021/`. De genererar inte nya
canonical-assets och ändrar inte gamla manifest. Nya dokument är denna rapport
och de två CSV-förteckningarna; produktionsfiler lämnas orörda.

## Återstående leveranssteg och beslut

1. **Efter uttryckligt commitgodkännande:** committa den granskade koden och gör
   ren rebuild. Alla aktuella lokala manifest behåller tills dess `dirty = true`.
   Den rena generationen ska ge samma Parquet-bytes; manifestens commit,
   tidsstämpel och dirty-status ska ändras sanningsenligt. Upprepa slutkontrollerna.
2. **EU 2009:** besluta om produkten tills vidare hålls utanför första publiceringen
   (rekommenderat, då 180 assets/11 produktmanifest), eller om annan offentligt
   kvalificerad omfattning ska granskas separat. Ingen ändring av produkt/data
   eller ny kandidat-/geografiallokering genomförs här. Hela aktuella lagret är
   fortsatt 194 assets/12 produktmanifest.
3. **Gemensam publiceringsplats och manifestnamn:** 194 asset-filnamn är unika,
   men tolv filer med basnamnet `manifest.json` kan inte ligga som tolv likanamnade
   assets i samma GitHub Release. Unika produkt-/familj-/år-manifestnamn och
   faktisk registrerad manifest-/assetplats måste fastställas. Nuvarande
   fjärrhämtare söker `base_url/manifest.json`; en flat samlad release med andra
   manifestnamn kräver en avgränsad anpassning/konfiguration före publicering,
   alternativt separata understödda platser. Detta är leveransarbete, inte ett
   hittat fel i valdata. Inget sådant ändras nu.
4. **2018:** använd ny version/plats med matchande manifest och checksummor;
   skriv inte över gamla `data-v0.1.0`. Inget permanent legacy-upplager behövs.
5. **Auto:** separat beslut per produkt och verifierad vy/stadium. Ingen flagga
   ändras här och EU 2009 markeras inte färdig för auto av denna tekniska kontroll.

Inget konkret nytt dataproblem blockerar commit och ren rebuild av den granskade
standardiseringen. EU 2009:s omfattning, distributionsupplägget och eventuell
aktivering återstår före själva publiceringen. **Ingen commit, push, tagg eller
GitHub Release har gjorts.**

## Bilaga: exakt de 20 historiska 2018-filerna

Dessa är den frysta generationens filer från
`.local-data/canonical-build/2018-clean-aab7c87/`; aktuella ersättare ligger i den
nya generationen enligt CSV-förteckningen. Samma basnamn är inte samma version.
| Äldre fil (20) | Aktuell ersättning |
| --- | --- |
| `rkl2018-results-rd.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-results-rf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-results-kf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-seats.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-candidacies.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-candidates.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-elected.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-substitutes.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-area-rd.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-area-rd.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-district-rd.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-district-rd.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-area-rf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-area-rf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-district-rf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-district-rf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-area-kf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-area-kf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-base-district-kf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
| `rkl2018-preference-votes-district-kf.parquet` | `rkl2018` / samma filnamn, nytt kontrakt |
