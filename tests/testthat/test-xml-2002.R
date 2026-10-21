make_2002_xml <- function(body, file = 'slutresultat_00K.xml', election = 'Kommunfullmäktigval', occasion = 'Allmänna val 15 September 2002', stage = 'SLUTLIG SAMMANRÄKNING RESULTAT') {
  xml2::read_xml(paste0('<VAL FILNAMN="',file,'" TILLFÄLLE="',occasion,'" VALTYP="',election,'" RAPPORTERING="',stage,'">',body,'</VAL>'))
}

test_that('2002 never treats election night as complete preliminary', {
  expect_error(.valresultat_2002(NULL,'RD','riket','preliminar'), 'collection results remain unrecovered')
  expect_error(.mandat_2002(NULL,NULL,'preliminar'), 'final election result')
  expect_error(.sources_2002('remote',NULL), 'preserved local')
  expect_false('election_night' %in% names(.english_argument_values$count))
})

test_that('2002 validates the occasion and guards embedded Orsa rerun values', {
  f <- tempfile(fileext='.xml'); on.exit(unlink(f))
  local_mocked_bindings(.xml2002_source=function(...) f)
  original <- '<NATION><KOMMUN KOD="2034" RÖSTER="4009"><VALDELTAGANDE SUMMA_RÖSTER="4070"/></KOMMUN></NATION>'
  xml2::write_xml(make_2002_xml(original),f)
  expect_s3_class(.xml2002_read(NULL,'slutresultat_00K.xml','KF'),'xml_document')
  wrong <- '<NATION><KOMMUN KOD="2034" RÖSTER="4303"><VALDELTAGANDE SUMMA_RÖSTER="4316"/></KOMMUN></NATION>'
  xml2::write_xml(make_2002_xml(wrong),f)
  expect_error(.xml2002_read(NULL,'slutresultat_00K.xml','KF'),'incorporates the Orsa rerun')
  xml2::write_xml(make_2002_xml(original,occasion='Omval 16 Mars 2003'),f)
  expect_error(.xml2002_read(NULL,'slutresultat_00K.xml','KF'),'occasion/counting stage')
  xml2::write_xml(make_2002_xml(original,stage='VALNATT RAPPORTERING'),f)
  expect_error(.xml2002_read(NULL,'slutresultat_00K.xml','KF'),'occasion/counting stage')
})

test_that('2002 combined OG does not become a fabricated invalid subcategory', {
  local_mocked_bindings(.xml2002_documents=function(...) list(make_2002_xml('<PARTI FÖRKORTNING="M" BETECKNING="Moderata Samlingspartiet"/><KOMMUN KOD="0980" NAMN="Gotland" RÖSTER="10"><GILTIGA PARTI="M" RÖSTER="10" PROCENT="100"/><OGILTIGA TEXT="OG" RÖSTER="2"/><VALDELTAGANDE RÖSTBERÄTTIGADE="20" RÖSTBERÄTTIGADE_KLARA_VALDISTRIKT="20" SUMMA_RÖSTER="12" PROCENT="60"/></KOMMUN>')))
  x <- .valresultat_2002(NULL,'KF','kommun','slutlig')
  expect_identical(x$valar,2002L)
  expect_identical(x$valdatum,'2002-09-15')
  expect_identical(x$ogiltiga_roster,2L)
  expect_true(is.na(x$blanka_roster))
  expect_true(is.na(x$ovriga_ogiltiga))
  expect_identical(x$andel_roster,1)
  expect_identical(x$valdel,.6)
})

test_that('2002 appointment IDs distinguish records and exclude unfilled slots', {
  x <- make_2002_xml('<KOMMUN><GILTIGA><GRUPP_VALDA><VALD ORDNING="1" NAMN="Same"/><VALD ORDNING="2" NAMN="Same"/><VALD ORDNING="3" NAMN="Kunde ej utses"/></GRUPP_VALDA></GILTIGA></KOMMUN>')
  x <- .xml2002_appointment_slots(x,'KF')
  ids <- xml2::xml_attr(xml2::xml_find_all(x,'.//VALD'),'KANDNR')
  expect_match(ids[1:2],'^2002:KF:slot:')
  expect_identical(anyDuplicated(ids[1:2]),0L)
  expect_true(is.na(ids[3]))
  expect_identical(xml2::xml_attr(xml2::xml_find_all(x,'.//VALD'),'NAMN')[3],'Kunde inte utses')
})

test_that('2002 preference records preserve observations without person-name linkage', {
  d <- make_2002_xml('<VALSEDEL LISTNUMMER="0001-00197" RÖSTER="10"><PERSONVAL KANDIDAT="4" NAMN="Same" PERSONKRYSS="5"/><PERSONVAL KANDIDAT="5" NAMN="Same" PERSONKRYSS="0"/></VALSEDEL>')
  list <- xml2::xml_find_first(d,'./VALSEDEL')
  geo <- list(area_code='1010',area_name='Area',valomradeskod='00',valomradesnamn='Sverige',valkretskod='1010',valkretsnamn='Area')
  info <- list(partikod='0001',partiforkortning='M',partibeteckning='Party')
  x <- .xml2002_preference_rows(xml2::xml_find_all(list,'./PERSONVAL'),d,'source.xml','RD',geo,info,20L,list)
  expect_identical(x$antal_personroster,c(5L,0L))
  expect_identical(x$andel_personroster,c(.25,0))
  expect_identical(x$andel_personroster_lista,c(.5,0))
  expect_identical(x$ordning,c(4L,5L))
  expect_true(all(is.na(x$namn)))
  expect_match(x$kandidatnummer,'^2002:RD:list:')
  expect_identical(anyDuplicated(x$kandidatnummer),0L)
  y <- .xml2002_preference_rows(xml2::xml_find_all(list,'./PERSONVAL'),d,'source.xml','RD',geo,info,NA_integer_)
  expect_true(all(is.na(y$andel_personroster)))
  expect_identical(y$antal_personroster,c(5L,0L))
})

test_that('2002 cannot claim person-linked broader aggregation or ballot completeness', {
  local_mocked_bindings(.sources_2002=function(...) NULL,.personroster_2002=function(...) tibble::tibble(valar=2002L))
  expect_error(preference_votes(source = "local", 2002,election='municipal',level='municipality'),'unsupported person linkage')
  expect_error(preference_votes(source = "local", 2002,election='regional',level='region'),'unsupported person linkage')
  expect_false(2002L %in% .stodd_valar('kandidaturer','RD'))
  for(f in c('valresultat','mandat','kandidater','valda','ersattare','personroster'))
    for(v in c('RD','RF','KF')) expect_true(2002L %in% .stodd_valar(f,v))
})

test_that('2002 requires complete district coverage and checksum-pinned ordinary Orsa', {
  s <- list(sources = data.frame(export = 'slutresultat_1380R.xml'))
  expect_error(.xml2002_files(s, 'RD', TRUE), '1/290')
  s <- list(sources = data.frame(export = 'slutresultat_0180L.xml'))
  expect_error(.xml2002_files(s, 'RF', TRUE), '1/289')
  f <- tempfile(); on.exit(unlink(f)); writeLines('<VAL/>', f)
  s <- list(root = dirname(f), sources = data.frame(export = 'slutresultat_2034K.xml',
    file = basename(f), bytes = unname(file.info(f)$size),
    md5 = unname(tools::md5sum(f)), sha256 = .canonical_sha256(f)))
  expect_error(.xml2002_source(s, 'slutresultat_2034K.xml'), 'pinned original election')
  s$sources$export <- 'slutresultat_0180K.xml'
  expect_identical(normalizePath(.xml2002_source(s, 'slutresultat_0180K.xml')),
    normalizePath(f))
  writeLines('<changed/>', f)
  expect_error(.xml2002_source(s, 'slutresultat_0180K.xml'), 'changed 2002 source')
})

test_that('2002 source observations do not assert candidacy or person counts', {
  population <- fixture_kandidaturer()
  population$valar <- rep(2002L, nrow(population))
  population$oppen_lista <- rep(NA, nrow(population))
  population$pa_namnvalsedel <- rep(NA, nrow(population))
  x <- .kandidater_2002(NULL, 'RD', FALSE, bundle = list(population = population))
  for (field in intersect(c('antal_kandidaturer', 'antal_listor', 'flera_listor',
    'antal_valomraden', 'flera_valomraden', 'antal_valkretsar', 'antal_partier',
    'flera_partier', 'antal_valtyper', 'flera_valtyper'), names(x)))
    expect_true(all(is.na(x[[field]])), info = field)
})

test_that('2002 unresolved internal party tokens never become public party codes', {
  x <- tibble::tibble(partikod = c('0001', 'source-unresolved:KF:2034:ABC', NA_character_),
    partiforkortning = c('M', 'ABC', 'Unknown'))
  y <- .xml2002_public_parties(x)
  expect_identical(y$partikod, c('0001', NA_character_, NA_character_))
  expect_identical(y$partiforkortning, x$partiforkortning)
})

test_that('2002 retains separately reported smaller-party votes without double counting', {
  doc <- make_2002_xml('<PARTI FÖRKORTNING="M" BETECKNING="Moderaterna"/><PARTI FÖRKORTNING="ABC" BETECKNING="Local party"/><KOMMUN KOD="0980" NAMN="Gotland" RÖSTER="15"><GILTIGA PARTI="M" RÖSTER="10"/><GILTIGA PARTI="ÖVR" RÖSTER="5"><VARAV_ÖVRIGA PARTI="ABC" RÖSTER="2"/><VARAV_ÖVRIGA PARTI="ÖVR" RÖSTER="3"/></GILTIGA><OGILTIGA TEXT="OG" RÖSTER="1"/><VALDELTAGANDE RÖSTBERÄTTIGADE="20" RÖSTBERÄTTIGADE_KLARA_VALDISTRIKT="20" SUMMA_RÖSTER="16"/></KOMMUN>')
  local_mocked_bindings(.xml2002_documents = function(...) list(doc))
  x <- .valresultat_2002(NULL, 'KF', 'kommun', 'slutlig')
  expect_identical(sum(x$antal_roster), 15L)
  expect_identical(x$antal_roster[x$partiforkortning == 'ABC' & !is.na(x$partiforkortning)], 2L)
  expect_identical(x$antal_roster[x$ovriga_partier %in% TRUE], 3L)
  expect_true(is.na(x$partikod[x$partibeteckning == 'Local party']))
})

test_that('2002 includes municipality-level collection districts exactly once', {
  doc <- make_2002_xml('<KOMMUN KOD="0114" NAMN="Upplands Väsby"><KRETS_KOMMUN KOD="011401"><VALDISTRIKT KOD="01140001"/><ONSDAGSDISTRIKT KOD="K-0114-01"/></KRETS_KOMMUN><ONSDAGSDISTRIKT KOD="L-0114-12"/></KOMMUN>')
  x <- .xml2002_nodes(doc, 'valdistrikt', 'RF')
  expect_identical(xml2::xml_attr(x, 'KOD'), c('01140001', 'K-0114-01', 'L-0114-12'))
  expect_identical(anyDuplicated(xml2::xml_path(x)), 0L)
  s <- list(cache = new.env(parent = emptyenv()))
  assign('geography-RF', list(areas = tibble::tibble(code = '0112', name = 'Source regional constituency'),
    municipalities = tibble::tibble(municipality = '0114', code = '0112')), s$cache)
  g <- .xml2002_geography(s, x[[3]], 'RF', 'valdistrikt', doc)
  expect_identical(g$valkretskod, '0112')
  expect_true(is.na(g$kommunvalkretskod))
  expect_identical(g$kommunkod, '0114')
  assign('geography-RF', list(areas = tibble::tibble(code = '0107', name = 'Source area'),
    municipalities = tibble::tibble(municipality = '0114', code = '0107')), s$cache)
  expect_identical(.xml2002_geography(s, x[[3]], 'RF', 'valdistrikt', doc)$valkretskod, '0107')
})

test_that('2002 collection cast votes are derived only from complete valid and combined invalid counts', {
  make <- function(invalid) make_2002_xml(paste0('<PARTI FÖRKORTNING="M" BETECKNING="Moderaterna"/><KOMMUN KOD="0980" NAMN="Gotland"><ONSDAGSDISTRIKT KOD="K-0980-01" NAMN="Collection" RÖSTER="10" TID_RAPPORT="20020918192354"><GILTIGA PARTI="M" RÖSTER="10"/>', invalid, '</ONSDAGSDISTRIKT></KOMMUN>'))
  doc <- make('<OGILTIGA TEXT="OG" RÖSTER="2"/>')
  local_mocked_bindings(.xml2002_documents = function(...) list(doc))
  x <- .valresultat_2002(NULL, 'KF', 'valdistrikt', 'slutlig')
  expect_identical(x$totalt_antal_roster, 12L)
  expect_identical(x$ogiltiga_roster, 2L)
  expect_true(x$raknat)
  expect_true(is.na(x$valdel))
  expect_true(is.na(x$blanka_roster))
  doc <- make('')
  y <- .valresultat_2002(NULL, 'KF', 'valdistrikt', 'slutlig')
  expect_true(is.na(y$totalt_antal_roster))
  expect_true(is.na(y$ogiltiga_roster))
})

test_that('2002 candidate enrichment retains positive and zero observations without inventing missing slot votes', {
  raw <- .xml2006_candidacy_raw(3L)
  raw$kandidatnummer <- c('2002:RD:area:a', '2002:RD:area:b', '2002:RD:slot:c')
  raw$valtyp <- rep('RD', 3L); raw$partikod <- rep('0001', 3L)
  raw$valomradeskod <- rep('00', 3L); raw$valomradesnamn <- rep('Sverige', 3L)
  raw$valkretskod <- rep('0101', 3L); raw$valkretsnamn <- rep('Area', 3L)
  population <- parse_kandidaturer_2026(raw, 2002L)
  pref <- tibble::tibble(kandidatnummer = raw$kandidatnummer[1:2], valtyp = 'RD',
    partikod = '0001', antal_personroster = c(5L, 0L), kvalificerad_personval = NA,
    valomradeskod = '00', valkretskod = '0101')
  x <- .kandidater_2002(NULL, 'RD', TRUE, bundle = list(population = population,
    pref = pref, relations = list(valda = tibble::tibble())))
  j <- match(raw$kandidatnummer, x$kandidatnummer)
  expect_identical(x$antal_personroster_totalt[j], c(5L, 0L, NA_integer_))
})
