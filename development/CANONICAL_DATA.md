# Kanonisk datadistribution: RKL 2018, prototyp

Detta är ett internt bygg- och läskontrakt. Ingen GitHub Release finns ännu och
de publika funktionernas `source`-argument använder fortfarande enbart
Valmyndighetens råkällor (`local`, `remote`, `auto`). `auto` ändras inte.

## Vald modell

Parquet är det publika huvudformatet. Tillgångarna är fristående tabeller som
också kan läsas utanför R. Det lilla paketet `nanoparquet` ligger i `Suggests`;
råvägen får inget nytt obligatoriskt beroende. Inga CSV- eller DTA-dubbletter
distribueras. RDS används enbart för lokala tekniska mellanobjekt och som
benchmarkreferens.

Distributionen är en hybrid. `valresultat` lagras som en Parquet-fil per
valtyp, `mandat` i en fil och kandidatfunktionerna i var sin fil. Deras
publika kolumner, ordning och typer bevaras via manifestet. För `personroster`
lagras de glesa publika vyerna per valtyp/nivå; områdesvyerna omfattar även
nollkompletterade varianter. Små normaliserade basobjekt (`geo`, `parti`,
`lista`, `roster`, `listroster`) finns separat för att återskapa de stora
nollkompletterade distriktsvyerna med samma adapter som råvägen. Ingen
förgenererad nationell kandidat × valdistrikt-panel behövs.

En helt normaliserad modell även för övriga funktioner skulle kräva en
andra, mer komplex adapter för deras publika kontrakt. Endast färdiga
personrösttabeller skulle i stället duplicera miljontals nollrader. Den valda
hybriden bevarar explicita nollor, genuina `NA`, listnummer, kompletthet och
90000-semantik i små filer. I varje Parquet-fil anger `.table`, `.component`
eller `.person_view` undertabellen när flera delar delar fil.

RD:s valdistriktsresultat (100 199 rader, 51,4 MB i R) gav följande mätning:

| Format | Byte | Skrivtid | Lästid |
|---|---:|---:|---:|
| Parquet gzip | 2 345 722 | 0,24 s | 0,09 s |
| Parquet snappy | 2 887 464 | 0,15 s | 0,29 s |
| Parquet zstd | 3 547 313 | 0,12 s | 0,11 s |
| RDS gzip, teknisk referens | 2 746 423 | 0,61 s | 0,32 s |
| RDS xz, teknisk referens | 1 831 584 | 5,68 s | 0,89 s |

Parquet gzip valdes. Provade tabeller rundturstestades för kolumnordning,
R-typ, värden och `NA`.

## Assets och manifest

`data-raw/build-canonical-2018.R` skapar lokala RDS-mellanobjekt i
`.local-data/canonical-build/data-v0.1.0/`.
`data-raw/export-canonical-parquet-2018.R` konverterar dem till 20 Parquet-
tillgångar (totalt cirka 40,7 MB) i
`.local-data/canonical-build/parquet-data-v0.1.0/`. Endast
Parquet-tillgångarna och `manifest.json` är avsedda för en framtida release.
`mandat` behöver inte hämta personröstdata och ett distriktsuttag behöver
bara relevant valtyp. Båda byggkatalogerna är Git-ignorerade.
RDS-mellanobjekten upptar 13,6 MB tillsammans, men är R-specifika och
saknar de färdiga fristående personrösttabeller som ingår i Parquet-samlingen.

| Asset (`.parquet`) | Rader | Byte |
|---|---:|---:|
| rkl2018-valresultat-rd | 108 948 | 2 632 579 |
| rkl2018-valresultat-rf | 87 759 | 2 482 288 |
| rkl2018-valresultat-kf | 84 972 | 2 473 403 |
| rkl2018-mandat | 4 374 | 39 062 |
| rkl2018-kandidaturer | 184 197 | 1 334 452 |
| rkl2018-kandidater | 72 255 | 478 905 |
| rkl2018-valda | 14 723 | 137 656 |
| rkl2018-ersattare | 76 297 | 189 619 |
| rkl2018-person-bas-omrade-rd | 34 253 | 114 846 |
| rkl2018-person-publik-omrade-rd | 122 876 | 503 386 |
| rkl2018-person-bas-distrikt-rd | 951 606 | 1 880 752 |
| rkl2018-person-publik-distrikt-rd | 685 502 | 5 002 063 |
| rkl2018-person-bas-omrade-rf | 52 968 | 185 667 |
| rkl2018-person-publik-omrade-rf | 202 174 | 1 139 765 |
| rkl2018-person-bas-distrikt-rf | 1 143 157 | 2 311 762 |
| rkl2018-person-publik-distrikt-rf | 905 633 | 6 560 335 |
| rkl2018-person-bas-omrade-kf | 129 275 | 533 301 |
| rkl2018-person-publik-omrade-kf | 262 335 | 2 568 504 |
| rkl2018-person-bas-distrikt-kf | 1 224 345 | 2 830 987 |
| rkl2018-person-publik-distrikt-kf | 1 006 364 | 7 285 052 |

`manifest.json` innehåller `schema_version`, `data_version`, `valserie`,
`valar`, UTC-byggtid, byggande paketversion, byggkodens Git-SHA, publika
dataytor och per asset namn, roll, radantal, filnamn, byte och SHA256. Det
innehåller även undertabellernas ursprungliga kolumner och ordning. Råkällorna
anges med officiell identitet/URL, klassning, MD5 och SHA256. Slutresultatets
klassning är `official_archived_snapshot`. Inga lokala sökvägar ingår. Dataversionen
är en version för hela kollektionen; senare år kan läggas till en ny release av
samma format. Paketversionen är separat.

Råkällornas verifierade kontrollsummor i detta bygge:

| Källa | MD5 | SHA256 |
|---|---|---|
| Slutresultatets ZIP, officiell arkiverad snapshot | `f8f0e87f7652c8ef258d011bd645c943` | `cb4a490b576e5a57b42b5ca26d38fa1074c692b4cd7eeb2aca2c3de80560b3a6` |
| Deltagande partier, officiell SKV | `44f9ce072b0035c8d79439752c75f54a` | `5b2ea5698b131ddbb92dd102629110e52cc6d75b9b77d4d0f3567759d191c01e4` |
| Kandidaturer, nu publicerad gallrad officiell SKV | `9855ac4280c2a5165389a88c647ae49f` | `8d9fa91b0c7257e0c8bec840209fabf23a78b7837aadb58a849cf47cbb7aabb5` |

Första byggsteget kräver arkiverad officiell
`slutresultat.zip`, Valmyndighetens `deltagande_partier.skv` och den nu
publicerade **gallrade** `kandidaturer.skv`. Den namngivna lokala
forskningssnapshoten och dess README ändras inte och används inte som
byggkälla. Skriptet kontrollerar kandidatfilens verifierade MD5 och
slutresultatets SHA256 innan det skriver assets. Byggsteget använder en
temporär byggrot; varken råfilerna eller deras tillfälliga kopior distribueras.

Byggordningen är `Rscript data-raw/build-canonical-2018.R RAW_ROOT
OFFICIAL_CANDIDATE_FILE` följt av `Rscript
data-raw/export-canonical-parquet-2018.R STAGE_DIR OUTPUT_DIR`. Det andra
steget kräver `nanoparquet` vid byggning. En ny dataversion ska byggas om och
checksummeverifieras efter att byggkoden har committats, så att manifestets
Git-SHA pekar på just den kod som skapade tillgångarna.

Läsprototypen `.canonical_manifest()`, `.canonical_asset()` och
`.canonical_public_2018()` är intern.
Cache-nyckeln innehåller dataversion, assetnamn och checksumma. Cacheträff
kontrolleras mot både byte och SHA256; skadade filer underkänns och kan hämtas
om från en explicit given URL. Standardcache är
`tools::R_user_dir("valresultat", "cache")`; tester injicerar en isolerad
cache. Ingen nedladdning sker utan URL. Parquet-läsning kräver `nanoparquet`
först när ett sådant asset används; installationen kräver inte `.local-data`
eller utvecklingsfiler.

En framtida release kan använda taggen `data-v0.1.0` och adresser av formen
`https://github.com/richardohrvall/valresultat/releases/download/data-v0.1.0/<asset>`.
Paketet bör läsa en **explicit** dataversion från ett litet versionsregister,
aldrig `latest`. En framtida publik `source = "canonical"` bör föreslås och
beslutas separat; nuvarande råkällebetydelse bevaras.

Integrationen har två nivåer. Det ordinarie nätfria testet är deterministiskt
och använder små fixtures. Den separata 2018-integrationen jämför alla
Parquet-vyer exakt med de RDS-mellanobjekt som byggts av råvägen, inklusive
personrösternas fyra områdesvarianter och båda glesa distriktsvarianterna.
Den kan aktiveras med `VALRESULTAT_TEST_CANONICAL_DIR` och
`VALRESULTAT_TEST_CANONICAL_STAGE_DIR`. En full omparsning av rå-XML för
varje variant är dessutom möjlig med `VALRESULTAT_TEST_CANONICAL_FULL_RAW=1`,
men är ett separat långsamt test. För nollkompletterade distriktsvyer verifieras
de fem normaliserade grundtabellerna per valtyp/nivå exakt; samma interna
adapter körs sedan som på råvägen.
