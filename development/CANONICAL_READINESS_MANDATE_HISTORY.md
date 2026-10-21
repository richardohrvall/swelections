> Senare beslut: canonical-historik i första releasen gäller bara 2014–2018 och
> 2018–2022. För 2022–2026 används aktuell remote-källa tills separat frysningsbeslut
> efter 2026-10-31. Förslaget om tre extra assets nedan är ersatt av två: aktuell
> plan är 190 assets och tolv manifest. Se
> [genomförd source-modell](MANDATE_HISTORY_SOURCE_SELECTION.md).

# Canonical readiness: mandatperiodshistorik

Datum: 21 oktober 2026. Separat inventering inför första releasen.
**Ingen produktionskod, registrering, flagga, canonical-asset eller befintlig
releaseinventering har ändrats.** Rekommendationen nedan är ännu inte genomförd.

## Rekommendation

**Ta med samtliga tre perioder i första releasen.** Underlaget räcker för
källbaserad historik över tilldelade mandat och deras innehavare/vakanser inom
de uttryckliga täckningsdatumen. Ingen period behöver vänta på svar från
Valmyndigheten eller ytterligare källåtervinning.

Det finns däremot **inga distributionsfärdiga canonical-mandatperiodsassets i
dagens 188-asset-kandidat**. Det som finns är produktionsläsare, validerade lokala
källor och materialiserade lokala RDS-tabeller. Dessa ska inte beskrivas som redan
publicerbara Parquet-produkter med manifest och canonical-backend.

| Period | Innehållsstatus | Verifierad datumtäckning, inkl. slutdatum | Intervall | Aktiva mandat | Besatta / vakanta vid slutdatum | Föreslaget tillskott | Teknisk status |
| --- | --- | --- | ---: | ---: | --- | --- | --- |
| 2014–2018 | Redo med dokumenterad datum-/källkonvention | 2014-09-14–2018-11-07 | 18 684 | 14 807 | 14 719 / 88 | 1 Parquet, cirka 0,92 MB | Tekniskt arbete återstår |
| 2018–2022 | Redo med dokumenterad datum-/källkonvention | 2018-09-09–2022-10-31 | 18 422 | 14 745 | 14 674 / 71 | 1 Parquet, cirka 0,90 MB | Tekniskt arbete återstår |
| 2022–2026 | Redo med uttrycklig snapshotgräns | 2022-09-11–2026-10-15 | 18 079 | 14 683 | 14 583 / 100 | 1 Parquet, cirka 0,89 MB | Tekniskt arbete återstår |

Alla rader omfattar **RD, RF och KF samt alla tre funktionerna**
mandate_history/members_at/vacant_seats_at och deras svenska motsvarigheter.
Inget mandat saknar rekonstruerad status inom den verifierade populationen.
För vart och ett av åren omfattar den ursprungliga mandatpopulationen 29 RD-valkretsar,
20 RF-regioner och 290 KF-kommuner; tilldelningsvalkretsarna bevaras i respektive mandatnyckel.
Datumen beskriver Valmyndighetens administrativa valhistorik, inte lagstadgad
tjänstgöringsstart, mötesnärvaro eller ett antaget juridiskt mandatperiodsslut.
Källsnapshots efter nästa ordinarie val ska därför inte tolkas som att den gamla
mandatperioden juridiskt förlängts.

2022-data får **inte** beskrivas som verifierade efter 2026-10-15.
Avgångsexportens senare genereringsdatum utökar inte historikens täckning.
Datumfrågor utanför respektive täckning ska fortsatt ge fel, inte extrapolera
öppna intervall. Vid övergångsdatum bör originalåret väljas uttryckligen.
Nuvarande year = NULL väljer senaste *stödda* ursprungliga valår på/före datumet.

## Källor och deras roller

Alla tre perioder kräver den oberoende mandatpopulationen från det ursprungliga
slutresultatets **mandatfördelning**, inklusive otillsatta mandat, samt ursprungliga
valda från samma resultat. Dessa finns redan i de validerade RKL-underlagen.
Medlemsfilerna får inte ensamma definiera mandatpopulationen.

Tabellen anger **bevarade lokala filnamn**. Suffixet _20221031 är en
snapshotbeteckning i det bevarade materialet; det påstås inte vara ett officiellt
ursprungsfilnamn.

| Period | Bevarade medlems-/kontrollfiler | Snapshot enligt filhuvud | Funktion vid bygg/validering |
| --- | --- | --- | --- |
| 2014–2018 | rkl/2014/kandidater/nuvarande_ledamoter.skv | 2018-11-07 | Slutinnehavare och stolnummer; ankare för kedjor |
| 2014–2018 | samma katalog: avgangna_ledamoter.skv | 2018-11-07 | Avgångar och explicita efterträdarlänkar; kedjor rekonstrueras framåt och bakåt |
| 2014–2018 | samma katalog: tommastolar.skv | 2018-11-07 | Oberoende kontroll: 88 vakanser i 59 kommun-/partigrupper |
| 2018–2022 | rkl/2018/kandidater/ledamoter_med_historik_20221031.skv | 2022-10-31 | Primär intervallhistorik, 18 422 källrader |
| 2018–2022 | samma katalog: nuvarande_ledamoter_20221031.skv | 2022-10-31 | Oberoende kontroll av samtliga 14 674 slutinnehavare |
| 2018–2022 | samma katalog: avgangna_ledamoter_20221031.skv | 2022-10-31 | Kompletterande avgångskontroll, 3 615 rader |
| 2018–2022 | samma katalog: tommastolar_20221031.skv | 2022-10-31 | Oberoende kontroll: 71 vakanser i 45 grupper |
| 2022–2026 | ledamoter_med_historik.csv | 2026-10-15 | Primär historik, 17 996 källrader |
| 2022–2026 | nuvarande_ledamoter.csv | 2026-10-15 | 14 583 innehavare samt 100 kandidatfria mandat; ger även senare vakansintervall |
| 2022–2026 | avgangna_ledamoter.csv | 2026-10-17 | Kompletterande avgångskontroll, 3 396 rader |
| 2022–2026 | tomma_stolar.csv | **2026-10-14** | Oberoende kontroll: 100 vakanser i 60 grupper |

2022-filerna är bevarade i den lokala mandatstatusauditen, separat från äldre
snapshots. Officiell källa är
[Valmyndighetens exportkatalog för 2022](https://resultat.val.se/filer/val2022/info/),
med de fyra CSV-basnamnen i tabellen. Fullständig hämtproveniens, storlekar,
MD5 och SHA256 finns i auditens retrieval-manifest.json.
Den nya kontrollen läser filhuvudet för tomma_stolar.csv som **2026-10-14**;
den tidigare förstudiens sammanfattning angav 15 oktober. Detta är en
datummetadataförtydligande, inte en ändring av vakansdata: de 60 grupperna och
100 stolarna stämmer mot innehavarfilen daterad 15 oktober.

Ytterligare redan bevarade underlag behövs som bygg-/rättelseproveniens:

- Ursprungliga finalresultat, valda och mandatfördelning för 2014/2018/2022.
  Den korrigerade 2018-generationen ska användas, inte äldre publicerad generation.
- Båstad 2015 och Falun 2019: verifierade omvalsfördelningar,
  ersättningsgeografi och datum. De ersätter komponenter inom samma period.
- Ragunda: beslut 877-2018, rättelsedatum 2018-12-12 och de bevarade
  historik-/innehavarraderna med start 2018-09-09.
- Utökade ledamots-/ersättarfiler och kommunala handlingar används som
  kompletterande belägg för Överkalix/Kiruna och andra redan utredda specialfall.
  De behövs inte för att slutanvändaren ska filtrera färdig canonical-historik.

2014 saknar en enhetlig historikfil; detta är **inte** en kvarstående lucka i den
rekonstruerade intervallpopulationen. Nuvarande + avgångar + ursprunglig
mandatfördelning + vakanskontroll räcker med de redan verifierade stolslänkarna.
Namn används inte för att konstruera personidentiteter.

## Gemensam canonical-tabell för alla tre funktionerna

Rekommendera **en fullständig intervalltabell per period**, inklusive både besatta
och vakanta mandat. Filtrera samma tabell för datumfrågorna:

- mandate_history: hela urvalets historik.
- members_at: start_date <= datum, datum < end_date eller öppet slut, status occupied.
- vacant_seats_at: samma datumvillkor, status vacant.

Detta är redan den befintliga modellens logik, inte ett nytt datamodellförslag.
Initiala vakanser får egna intervall även utan personrad; senare vakanser följer
verifierad avgång. För varje datum inom täckningen gäller
**besatta + vakanta = tilldelade aktiva mandat**.

Behåll befintliga 31 full-kolumner: originalår och komponentens valdatum/valklass,
chair_id/interval_id, RD/RF/KF och tilldelningsgeografi, parti/stol,
kandidatnummer/namn, status, start/slut, datumgrund, rättelseuppgifter,
coverage_end och den fulla källproveniensen. Standard är samma radmängd med
23 kolumner. Engelska kolumner/värden lagras en gång; svenska värden/kolumnnamn
och standard/full skapas i presentationen. Datum behåller Date och heltalsdagar.

Ett separat person-snapshot-asset eller vakans-asset behövs inte. Inte heller
behövs förgenererade datumtabeller. Den fulla mandatpopulationen finns i
intervallen och verifieras mot de ursprungliga tilldelningarna vid byggandet.

Omvalskomponenterna gör att historiken innehåller 14 848 respektive 14 806
distinkta event-/stolnycklar för 2014 och 2018: gamla och ersättande komponenter
är aktiva vid olika datum. De får inte summeras som samtidiga mandat.
Antalet aktiva mandat är hela tiden 14 807 respektive 14 745.

## Föreslagen releaseutökning – inte utförd

| Befintligt produktmanifest | Föreslagen ny asset | Funktioner som asseten stödjer |
| --- | --- | --- |
| rkl2014-manifest.json | rkl2014-mandate-history.parquet | Alla tre |
| rkl2018-manifest.json | rkl2018-mandate-history.parquet | Alla tre |
| rkl2022-manifest.json | rkl2022-mandate-history.parquet | Alla tre |

Lägg dem i de befintliga RKL-produkterna, med egna historikvyer och
täckningsmetadata. Historiken är en separat datavy från det fasta valresultatet;
den ska inte etiketteras som en ny räkning eller ett nytt ordinarie val.
Inga nya valfamiljer eller tre ytterligare produktmanifest behövs.

**Föreslagen omfattning:** 188 + 3 = **191 Parquet-assets**, fortfarande
**12 produktmanifest**, alltså **203 distributionsfiler**.
De tre perioderna innehåller tillsammans **55 185 intervall**.
Temporär diagnostisk Parquet-serialisering gav 921 444 / 903 469 / 891 059 byte,
totalt **2 715 972 byte (cirka 2,72 MB)**. Detta är en storleksmätning, inte nya
canonical-prototyper. De temporära Parquet-filerna har tagits bort; inga
distributionsfiler eller manifest har byggts. Slutlig storlek/hash fastställs vid
det godkända bygget, bland annat efter portabel proveniensnormalisering.

Canonical ska vara självförsörjande vid läsning: ingen historikfråga ska
anropa råbyggaren, hämta ursprungliga valda/mandat igen eller öppna lokala
medlemsfiler. Källor och rättelser deklareras i manifestet för granskning.
source_file behöver portabla källetiketter i den lagrade tabellen, inte
maskinsökvägar; råkällans hash/rad/snapshot och ursprunglig lokal proveniens
bevaras separat. Rader härledda från mandatfördelningen får inte tillskrivas
påhittade personrader eller källrapporterade datum.

## Vad auto kan göra i dag och vad som återstår

**I dag: nej, ingen av perioderna kan användas helt utan lokala medlemsfiler.**
Det har verifierats för alla tre funktionerna. source = canonical väljer
endast ursprungsresultatets källa; mandate_history kräver fortfarande data_dir
och läser historik-/innehavarfiler lokalt. Nuvarande canonical-register och
manifest har inga mandatperiodsvyer.

För den rekommenderade leveransen återstår avgränsat tekniskt arbete:

1. Reproducerbar R-byggare för de tre intervallassetsen, med fixerade
   källsnapshots, befintliga kontroller, kod-/källhashar och versionsmärkt
   schema/value/storage-kontrakt.
2. Canonical-läsare och source-routing för de tre funktionerna och svenska
   wrappers. source = auto/canonical ska välja **hela historiken**, inte bara
   ursprungligt valresultat. Detta ändrar innebörden av det nuvarande
   source = canonical i just mandatperiodsfunktionerna och ska dokumenteras.
   source = local behåller den explicita råkällsvägen.
3. Utöka den centrala funktionslistan för RKL 2014/2018/2022 med
   mandate_history, members_at och vacant_seats_at; deras coverage-kontroll
   pekar på samma periodasset. Manifestinnehåll får inte ge extra behörighet.
   Befintliga auto_eligible-flaggor behöver inte ändras för dessa redan aktiva
   produkter. Ingen annan period ska ges sådan behörighet.
4. Ingen remote-historikväg behöver införas för denna release. Auto får aldrig
   välja local. Utan godkänd historikasset/behörighet ska ett tydligt fel ges.
5. Tester som fungerar **utan data_dir, files eller utvecklingsarkiv**, med
   distribuerade manifest/assets: alla tre funktioner, RD/RF/KF,
   standard/full, English/Swedish, datumgränser, vakanser och omval;
   även kall cache/hämtning, hashes, schema och Parquet-rundtur.
6. Därefter uppdatera distributionslistan och de tre manifesten, köra full
   testsvit/check, samt ren rebuild efter commit och slutvalidering.

Detta är inte skäl att vänta med någon av perioderna av innehållsskäl.
Men de ska inte kallas tekniskt releasefärdiga förrän dessa steg är verifierade.
Den aktuella 188-asset-listan och aktiveringen har inte ändrats i denna audit.

## Färska kontroller och kvarstående avgränsningar

Auditen körde de befintliga publika funktionerna med de aktuella validerade
ursprungsresultaten, utan att ändra källor eller produktionskod.

- 866 / 891 / 837 distinkta start-/slut-/täckningsdatum kontrollerades.
  Samma aktiva mandatantal, inga dubbla aktiva stolnycklar och inga okända
  statusvärden vid samtliga datum; noll saknade startdatum.
- Samtliga 14 719 / 14 674 / 14 583 slutinnehavare matchar respektive
  oberoende innehavarexport på event, parti, geografi, stol och kandidatnummer.
- Initiala vakanser är 17 / **21** / 17. 2018 gäller det korrigerade resultatet,
  inklusive Häggkvist; äldre XML:s 22 får inte återinföras.
- Slutvakanserna 88 / 71 / 100 stämmer med kontrollkällorna.
  De elva valda medlems-/kontrollsnapshotarnas hashreferenser och de tretton
  kompletterande bevarade källornas SHA256 verifierades.
- Alla tre fulla tabeller klarar exakt Parquet-rundtur. Standard är en exakt
  projektion av full; den befintliga mandatperiodstestfilens **50 kontroller
  passerar utan fel, varningar eller skips**.
- 2014- och 2022-output är identiska med de tidigare granskade materialiserade
  tabellerna. För 2018 är enda skillnaden original_candidate_number på
  Ragunda-raden: tidigare NA, nu 534885 med den korrigerade originalkällan.
  Innehavare, intervall, rättelsedatum, mandatantal och vakansstatus är identiska.
- Ingen ny full paketcheck behövs för en rapport utan kodändringar.
  Senaste fulla svit/check i releasekandidaten: 5 000 passerade, 16 explicita
  integration-skips; R CMD check 0 fel/0 varningar/0 noter. Detta är tidigare
  releasevalidering, inte en påstådd ny körning av hela sviten i denna audit.

Avgränsningar som ska följa med canonical-leveransen:

- Tidpunkter följer källans administrativa valhistorik. Faktisk närvaro,
  tillfällig ersättartjänstgöring och juridisk tjänstgöringsstart ingår inte.
- Historiska ändringar i ersättarordning är inte en fullständigt tidsatt
  separat historik; endpointfiler får inte göras om till påhittade intervall.
- Partiet avser mandatets valmässiga tilldelning, inte en verifierad historik
  över partibyten/medlemskap.
- Kandidatnummer och namn är källvärden. Ingen longitudinell fysisk
  personidentitet eller ny ID-harmonisering konstrueras.
- Den exakta tidpunkten för länets verkställighet av Ragunda-rättelsen är
  fortfarande inte belagd, men blockerar inte den godkända korrigerade
  valhistoriken: start 2018-09-09 och separat rättelse 2018-12-12.
- Överkalix-vakanserna följer exportens 2025-12-15; tidigare kommunala
  avgångshandlingar omtolkas inte till nya övergångsdatum. Kiruna 54150 finns
  med som innehavare. Inga kvarstående okända stolar har identifierats.
- 2010–2014 ingår inte; de tidigare dokumenterade luckorna i
  kandidatidentifierad efterträdarlänkning är inte lösta av denna inventering.

Lokala auditbevis: .local-data/mandate-canonical-readiness-20261021/
(periods.csv, sources.csv, audit-history-*.rds och checks.log), samt
.local-data/mandate-readiness-audit.log. Inga sådana källor/RDS-filer läggs till Git.

Se även [mandatmodell och tidigare validering](MANDATE_HISTORY.md),
[källförstudien](MANDATE_HISTORY_FEASIBILITY.md) och
[nuvarande releasekandidat](CANONICAL_RELEASE_CANDIDATE.md).

**Slutsats:** godkänn att samtliga tre perioder läggs till den planerade
releaseomfattningen, med en gemensam historikasset per period. Genomför sedan den
avgränsade canonical-leveransen och verifiera att alla tre API-funktioner fungerar
utan användarens lokala källfiler. Ingen implementation eller aktivering har gjorts här.
