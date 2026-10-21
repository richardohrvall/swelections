# Mandatperioder: canonical 2014/2018 och remote 2022

21 oktober 2026. Implementerad arbetskopiekandidat, inte committad eller publicerad.
Denna modell ersätter förslaget om tre canonical-perioder i readiness-auditen.

| Period | Auto för alla tre funktionerna | Canonical-historik | Täckning |
| --- | --- | --- | --- |
| 2014–2018 | canonical | rkl2014-mandate-history.parquet | 2014-09-14–2018-11-07 |
| 2018–2022 | canonical | rkl2018-mandate-history.parquet | 2018-09-09–2022-10-31 |
| 2022–2026 | remote | Ingen i första releasen | Dynamisk enligt hämtade källdatum |

Alla tre funktionerna betyder mandate_history/members_at/vacant_seats_at och deras
svenska wrappers. Datumfunktionerna filtrerar samma mandatpopulation och samma
halvöppna intervall. Initiala och senare vakanser finns kvar. Inga separata
snapshotassets skapas och ingen fysisk personharmonisering görs.

## Source-semantik

Auto väljer endast godkänd canonical eller stödd remote, aldrig lokala råfiler.
Canonical-behörigheten för mandatperiodsfunktionerna finns enbart för 2014/2018,
och kontrolleras separat för var och en av de tre funktionerna. RKL 2022:s
funktionslista för fasta valresultat är oförändrad: inga historikfunktioner
tillkommer. Ett fullständigt privat 2022-manifest kan inte utöka auto-behörigheten.

Explicit canonical läser ett faktiskt historikasset; första releasens 2022-manifest
saknar ett sådant och ger ett tydligt fel. Explicit remote läser aktuella
2022-medlemsfiler. Explicit local behåller den befintliga lokala råbyggaren;
data_dir/files är lokala indata, och files-överskrivningar kräver uttryckligt local.

Det gamla source = canonical, som bara valde ursprungsresultatets källa men ändå
krävde lokala medlemsfiler, har ersatts av komplett canonical-historik.
Detta är en avsiktlig källvalsändring före första samlade releasen.

Remote-historik behöver fortfarande en oberoende, fullständig mandatpopulation.
För 2022 används det fasta ursprungsresultatet genom dess normala godkända
source-väg: canonical mandatfördelning och ursprungliga valda. Frågan kombinerar
alltså **aktuella medlemsfiler med en fast validerad valresultatbaslinje**.
Slutanvändaren behöver inga lokala råarkiv. Vid kall cache behövs nätåtkomst även
till den publicerade baslinjen, som därefter använder vanlig canonical-cache.

De planerade GitHub-assetsen är ännu opublicerade. Normalanrop har verifierats
med faktisk registrering och en lokal HTTP-spegel av distributionsfilerna.
Den verkliga livekontrollen använde den validerade canonical-prototypen som
ursprungsresultat. Det påstås inte att opublicerade GitHub-URL:er redan fungerar.

## Aktuell 2022-källa och datum

Fyra filer hämtas i sekvens vid varje remote-anrop från
https://resultat.val.se/filer/val2022/info/:

- ledamoter_med_historik.csv
- nuvarande_ledamoter.csv
- avgangna_ledamoter.csv
- tomma_stolar.csv

Ingen beständig medlemscache låser historiken till ett äldre snapshot.
Full output behåller officiell käll-URL, genereringsdatum, MD5 och källrad i
befintliga provenienskolumner. CR-only-filer läses från fil så att sista raden
bevaras. Temporära nedladdningar städas efter parsningen.

CSV-filerna saknar numeriska partikoder. Dessa kopplas, som tidigare, till
ursprunglig mandatfördelning. Den oberoende innehavarkontrollen använder
källans partiförkortning, geografi, stol, valtillfälle och kandidatnummer samt
kontrollerar unika nycklar. Namn används inte för identitetsmatchning.
En första version av den nya kontrollen använde numeriska partikoder även i
den oifyllda källtabellen och stoppade felaktigt alla rader. Kontrollnyckeln
rättades, och regressionstestet använder nu samma CSV-struktur utan partikod.
Ingen källa eller kandidatidentitet ändrades.

Samtliga slutliga innehavare/vakanser måste stämma mot innehavarexporten.
Motstridiga exportsnapshots eller nätverksfel ger fel, aldrig lokal fallback.

coverage_end begränsas till det tidigaste datumet i historik- respektive
innehavarfilen. En senare avgångsexport förlänger inte täckningen.
Datum efter gränsen ger fel; öppna intervall extrapoleras inte.

Verklig fjärrhämtning 21 oktober passerade: **18 079 intervall, 14 683 aktiva
mandat = 14 583 besatta + 100 vakanta**, täckning till **2026-10-21**.
Responser med URL, hämtningstid, storlek, MD5 och SHA256 är separat bevarade
lokalt. Äldre snapshots har inte skrivits över.

Ingen kalenderstyrd övergång till canonical sker efter 2026-10-31.
Frysning kräver ett senare separat beslut, bygge och validering.

## Förberedda assets och releaseomfattning

Två gemensamma full-tabeller har byggts: 18 684 intervall för 2014 och 18 422
för 2018. Båda har befintliga 31 engelska full-kolumner; standard är en projektion
med 23 kolumner. Svenska värden/kolumner skapas vid presentation.
Datumtyper, radordning och de tidigare granskade innehavar-/vakansintervallen
bevaras, inklusive Ragunda från 2018-09-09 med rättelse 2018-12-12.
source_file lagras som portabel källetikett med bevarad hash/rad/datum.

Byggare: data-raw/build-canonical-mandate-history.R. Den kopierar förälderns
valresultatassets byteidentiskt och lägger till ett historikasset med separat
komponent-/källproveniens. Den avvisar 2022. Originalmanifest skrivs inte över.

Förberedd omfattning: **190 Parquet-assets + 12 manifest = 202 filer**.
RKL 2014 har 25 assets, RKL 2018 har 21; RKL 2022 behåller sina 24 fasta
valresultatassets. Övriga produkter och de tidigare 188 Parquet-filerna är
oförändrade. Ingen EU-fråga eller kandidat-ID-regel ändras.

Auto_eligible-flaggorna är oförändrade. Endast RKL 2014/2018:s centrala
auto_functions utökas med de tre mandatperiodsfunktionerna.
Alla nya byggen har sanningsenligt build_tree_dirty = true.

Exakt arbetskopieinventering: [CANONICAL_RELEASE_UPLOADS.csv](CANONICAL_RELEASE_UPLOADS.csv).
Ren rebuild och slutliga manifest/checksummor återstår efter commitgodkännande.

## Valideringsbevis

Lokalt: .local-data/mandate-source-selection-20261021/.

- full-tests.log/rds: hela sviten; source-tests.log: riktade source- och datumtester.
- live-remote-verified.log och remote-snapshot-verified/provenance.csv:
  verklig auto-fjärrhämtning, fyra aktuella officiella medlemskällor.
- build-final.log: endast två canonical-historikbyggen, 2022 avvisat.
- actual-validation.log samt actual-canonical-calls.csv/actual-transports.csv:
  faktisk registrering med lokal HTTP-distribution, utan råarkiv eller
  manifestoverride. Exakta live-responser återspelas i transporttestet;
  detta skiljs från den separata riktiga livehämtningen.
- metadata-validation.log: gamla 188 assets oförändrade, två deklarerade tillägg,
  ingen absolut maskinsökväg i distributionsmanifest.
- package-check/check.log: R CMD check.

Ingen commit, push, tagg eller publicering.



## Slutresultat för denna arbetskopiekandidat

- Hela sviten: **5 076 passerade kontroller**, 16 explicita integrations-skips,
  inga fel eller varningar. R CMD check: **0 fel, 0 varningar, 0 noter**.
- **96 normala canonical-varianter** utan source-argument är identiska med både
  explicit canonical och tidigare granskad råreferens (med portabla källetiketter).
  De omfattar alla tre funktioner, båda perioderna, RD/RF/KF/alla, svenska/engelska
  och standard/full. Ytterligare datumkontroller passerar för start, slut och
  före/på Båstad/Falun-omvalen.
- Faktisk registrering och den förberedda HTTP-distributionen har verifierats
  utan raw-arkiv eller manifestoverride. För 2022 passerar samtliga tre funktioner
  via remote-transporten; 2026-10-22 avvisas när responserna anger 2026-10-21.
  Ingen begäran om ett 2022-historikasset görs. Sexton CSV-källupplösningar i
  transporttestet visar att de fyra responserna läses på nytt för varje fråga.
- Separat riktig livehämtning av de fyra officiella filerna passerar, utan
  någon lokal medlemskälla. Ursprungliga valresultat använder den godkända
  canonical-prototypen tills den publicerade baslinjen finns.
- Gamla **188 Parquet-assets och de tio övriga distributionsmanifesten är
  byteidentiska**. Endast RKL 2014/2018:s manifest utökas. Alla 206 ursprungliga
  lokala canonical-/prototypfiler är oförändrade.
- De två nya historikassetsen är byteidentiska mellan upprepade byggen och klarar
  Parquet-rundtur. Gzipstorlekar: **532 173 respektive 512 762 byte**, totalt
  **1 044 935 byte**. Alla tolv distributionsmanifest saknar absoluta lokala
  maskinsökvägar. Registreringens enda behörighetsförändringar är de två
  historiska funktionslistorna; alla aktiveringsflaggor är oförändrade.
- git diff --check passerar. Inga råfiler eller genererade Parquet-assets spåras.

Detta är arbetskopiebyggen med build_tree_dirty = true. Ingen commit, ren
produktionsrebuild, push, tagg eller publicering har genomförts i detta steg.
