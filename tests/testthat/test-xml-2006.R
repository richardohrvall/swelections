test_that("2006 other-party partitions preserve separate parties and residual votes", {
  node <- xml2::read_xml('<AREA><GILTIGA PARTI="ÖVR" RÖSTER="9"><VARAV_ÖVRIGA PARTI="0524" RÖSTER="7"/><VARAV_ÖVRIGA PARTI="ÖVR" RÖSTER="2"/></GILTIGA></AREA>')
  .xml2006_other_parties(node)
  expect_length(xml2::xml_find_all(node, './GILTIGA'), 0L)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(node, './ÖVRIGA_GILTIGA/GILTIGA'), 'PARTI'), '0524')
  expect_identical(xml2::xml_attr(xml2::xml_find_all(node, './ÖVRIGA_GILTIGA/HANDSKRIVNA'), 'RÖSTER'), '2')
  expect_error(.xml2006_other_parties(xml2::read_xml('<AREA><GILTIGA PARTI="ÖVR" RÖSTER="10"><VARAV_ÖVRIGA PARTI="0524" RÖSTER="7"/></GILTIGA></AREA>')), 'partition disagrees')
})

test_that("2006 appointed slots preserve unfilled positions without person IDs", {
  make <- function(file) xml2::read_xml(paste0('<VAL FILNAMN="', file, '"><KOMMUN><GILTIGA><GRUPP_VALDA><VALD NAMN="Kunde ej utses"/><VALD NAMN="Example"/><ERSÄTTARE NAMN="Example"/></GRUPP_VALDA></GILTIGA></KOMMUN></VAL>'))
  x <- .xml2006_appointment_slots(make('slutresultat_0001K.xml'), 'KF')
  y <- .xml2006_appointment_slots(make('slutresultat_0002K.xml'), 'KF')
  expect_true(is.na(xml2::xml_attr(xml2::xml_find_first(x, './/VALD'), 'KANDNR')))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(x, './/VALD'), 'NAMN'), 'Kunde inte utses')
  ids <- xml2::xml_attr(xml2::xml_find_all(x, './/*[@KANDNR]'), 'KANDNR')
  expect_match(ids, '^2006:KF:slot:')
  expect_identical(anyDuplicated(ids), 0L)
  expect_false(any(ids %in% xml2::xml_attr(xml2::xml_find_all(y, './/*[@KANDNR]'), 'KANDNR')))
  expect_identical(xml2::xml_attr(xml2::xml_find_all(x, './/*[@KANDNR]'), 'NAMN'), c('Example', 'Example'))
})

test_that("2006 does not relabel election night as complete preliminary", {
  expect_error(.valresultat_2006(NULL, 'RD', 'riket', 'preliminar'), 'not the full preliminary')
  expect_error(.sources_2006('remote', NULL), 'preserved local')
  expect_error(.mandat_2006(NULL, NULL, 'preliminar'), 'final election XML')
})

test_that("2006 candidate observations do not merge equal names", {
  doc <- xml2::read_xml('<VAL><PERSONVAL NAMN="Same Name" PERSONKRYSS="5"/><PERSONVAL NAMN="Same Name" PERSONKRYSS="3"/></VAL>')
  nodes <- xml2::xml_find_all(doc, './PERSONVAL')
  geo <- list(area_code = '1010', area_name = 'Area', valomradeskod = '00', valomradesnamn = 'Sverige', valkretskod = '1010', valkretsnamn = 'Area')
  info <- list(partikod = '0001', partiforkortning = 'M', partibeteckning = 'Party')
  out <- .xml2006_preference_rows(nodes, doc, 'source.xml', 'RD', geo, info, 100L)
  expect_identical(out$antal_personroster, c(5L, 3L))
  expect_identical(out$andel_personroster, c(.05, .03))
  expect_identical(out$namn, c('Same Name', 'Same Name'))
  expect_identical(anyDuplicated(out$kandidatnummer), 0L)
  expect_false(any(out$kandidatnummer %in% .xml2006_preference_rows(nodes, doc, 'other-source.xml', 'RD', geo, info, 100L)$kandidatnummer))
  one <- .xml2006_preference_rows(xml2::read_xml('<PERSONVAL NAMN="One" PERSONKRYSS="1"/>'), doc, 'one.xml', 'RD', geo, info, NA_integer_)
  expect_identical(nrow(one), 1L)
  expect_identical(one$antal_personroster, 1L)
  expect_true(is.na(one$andel_personroster))
})

test_that("2006 source positions, zeros and qualification remain explicit", {
  doc <- xml2::read_xml('<VAL><VALSEDEL LISTNUMMER="00010001" RÖSTER="10"><PERSONVAL KANDIDAT="4" NAMN="Recorded" PERSONKRYSS="0"/></VALSEDEL></VAL>')
  list <- xml2::xml_find_first(doc,'./VALSEDEL')
  geo <- list(area_code='0101', area_name='Area', valomradeskod='00',valomradesnamn='Sverige',valkretskod='0101',valkretsnamn='Area')
  info <- list(partikod='0001',partiforkortning='M',partibeteckning='Party')
  x <- .xml2006_preference_rows(xml2::xml_find_all(list,'./PERSONVAL'),doc,'source.xml','RD',geo,info,20L,list)
  expect_identical(x$antal_personroster,0L)
  expect_identical(x$ordning,4L)
  expect_identical(x$listnummer,'00010001')
  expect_identical(x$andel_personroster,0)
  expect_identical(x$andel_personroster_lista,0)
  expect_true(is.na(x$kvalificerad_personval))
  expect_identical(.xml2006_id('RD','ballot','a|b'),.xml2006_id('RD','ballot','a|b'))
  expect_false(identical(.xml2006_id('RD','ballot','a|b'),.xml2006_id('RF','ballot','a|b')))
})

test_that("2006 cannot claim cross-area person aggregation", {
  local_mocked_bindings(.sources_2006=function(...) NULL, .personroster_2006=function(...) tibble::tibble(valar=2006L))
  expect_error(preference_votes(source = "local", 2006,election='municipal',level='municipality'), 'unsupported person linkage')
  expect_error(preference_votes(source = "local", 2006,election='regional',level='region'), 'unsupported person linkage')
})

test_that("2006 is registered for all supported observation families", {
  for (f in c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster'))
    for (v in c('RD','RF','KF')) expect_true(2006L %in% .stodd_valar(f,v))
  expect_false('election_night' %in% names(.english_argument_values$count))
})

test_that("2006 ballot values and full official constituency keys are preserved", {
  b <- tibble::tibble(valtyp='RD',area='00',county='10',constituency='10',
    constituency_name='Blekinge län',partikod='0001',partibeteckning='Party',
    listnummer='00010001',ordning=1L,valsedelsuppgift='Recorded ballot text',
    kon='M',alder_pa_valdagen=50L,status='Utkast',registered='Nej')
  local_mocked_bindings(.xml2006_ballots=function(...) b)
  x <- .read_candidacies_2006(NULL,'RD')
  expect_identical(x$valsedelsstatus,'Utkast')
  expect_identical(x$valkretskod,'1010')
  expect_identical(x$valsedelsuppgift,'Recorded ballot text')
  expect_identical(x$anmalda_kandidater,FALSE)
  expect_true(is.na(x$pa_namnvalsedel))
  expect_true(is.na(x$namn))
  expect_true(is.na(x$giltig))
})
