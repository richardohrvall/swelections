# Synthetic tests remain independent of preserved local sources.
eu2024_fixture <- function() {
 p <- list(partikod='0001',partibeteckning='Example',partiforkortning='EX',
   antalRoster=10L,listRoster=list(list(listnummer='0001-00001',antalRoster=10L,
     antalRosterMedPersonrost=3L,personroster=list(list(namn='A',kandidatNummer=1L,
       kandidatNummerPaListan=1L,antalPersonroster=3L)))))
 list(valtillfalle='EU-val_2024',valtyp='E',rakningstillfalle='slutlig',
  valomrade=list(kod='00',namn='Riket',rostfordelning=list(rosterPaverkaMandat=list(partiRoster=list(p)))))
}
eu2024_kd_fixture <- function() tibble::tibble(partikod='0001',kandidatnummer=c('1','2'),
 listnummer='00001',namn=c('A','B'),partiforkortning='EX',partibeteckning='Example')

test_that('EU public dispatch is shared across all seven interfaces and years', {
 fixture <- tibble::tibble(valar=2024L,valtyp='E',kandidatnummer='1',namn='A',
   partikod='0001',antal_roster=10L,antal_personroster=3L,valklass='ordinarie val')
 local_mocked_bindings(.eu2024_read=function(table,args) fixture,
   .eu2014_read=function(table,args) dplyr::mutate(fixture,valar=2014L),
   .eu2019_read=function(table,args) dplyr::mutate(fixture,valar=2019L))
 en <- c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
 sv <- c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster')
 for(i in seq_along(en)) {
   a <- do.call(get(en[i]),list(year=2024,election='european',source='local',detail='full'))
   b <- do.call(get(sv[i]),list(ar=2024,val='E',source='local',detaljniva='full'))
   expect_identical(a,.public_output_names(b,'en'))
   st <- do.call(get(en[i]),list(year=2024,election='E',source='local'))
   expect_identical(st,a[names(st)])
   expect_identical(do.call(get(en[i]),list(year='all',election='E',source='local',detail='full')),dplyr::bind_rows(dplyr::mutate(a,election_year=2014L),dplyr::mutate(a,election_year=2019L),a))
   expect_identical(do.call(get(en[i]),list(from=2023,to=2025,election='E',source='local',detail='full')),a)
 }
 expect_error(results(2022,election='E'), '2022')
 expect_error(results(2024,election='E',update=TRUE), 'read-only')
})

test_that('EU list totals guard zero completion and never propagate qualification to districts', {
 raw <- eu2024_fixture();base <- .eu2024_preference_base(raw,'personvalsomrade')
 x <- .eu2024_preference_view(base,'personvalsomrade',eu2024_kd_fixture(),TRUE,TRUE,'0001 1')
 expect_equal(x$antal_personroster,c(3L,0L));expect_equal(x$andel_personroster,c(.3,0))
 expect_equal(x$listnummer,c('00001','00001'));expect_identical(x$kvalificerad_personval,c(TRUE,FALSE))
 raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]$listRoster[[1]]$antalRosterMedPersonrost <- 4L
 expect_error(.eu2024_preference_base(raw,'personvalsomrade'),'totals disagree')
 raw <- eu2024_fixture();raw$valdistrikt <- list(raw$valomrade)
 raw$valdistrikt[[1]]$valdistriktskod <- '011400';raw$valdistrikt[[1]]$kommunkod <- '0114'
 raw$valdistrikt[[1]]$lankod <- '01';raw$valdistrikt[[1]]$valdistriktstyp <- 'uppsamlingsdistrikt'
 raw$valdistrikt[[1]]$kommunvalkretsKod <- '011400'
 b <- .eu2024_preference_base(raw,'valdistrikt')
 y <- .eu2024_preference_view(b,'valdistrikt',eu2024_kd_fixture(),FALSE,FALSE,'0001 1')
 expect_true(all(is.na(y$kvalificerad_personval)))
 expect_identical(y$valdistriktskod,'011400')
 expect_true(all(is.na(y$kommunvalkretskod)))
})

test_that('EU candidate snapshot completeness is bound to approved content hashes', {
 expect_length(.eu2024_candidate_hashes,2L)
 expect_false('c47cd8e967c4dbc72d3fd7293aea1199c103c005729eb1c3cd64a456768c5375' %in% .eu2024_candidate_hashes)
 expect_identical(.stodd_valar('kandidaturer','E'),c(2014L,2019L,2024L))
 expect_identical(.english_argument_value('european','election'),'E')
})

test_that('EU candidate aggregation sums lists but preserves the first source name', {
 raw <- eu2024_fixture()
 p <- raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]]
 p$antalRoster <- 15L
 p$listRoster[[2]] <- list(listnummer='0001-00002',antalRoster=5L,
   antalRosterMedPersonrost=2L,personroster=list(list(namn='A variant',
     kandidatNummer=1L,kandidatNummerPaListan=2L,antalPersonroster=2L)))
 raw$valomrade$rostfordelning$rosterPaverkaMandat$partiRoster[[1]] <- p
 b <- .eu2024_preference_base(raw,'personvalsomrade')
 x <- .eu2024_preference_view(b,'personvalsomrade',eu2024_kd_fixture(),FALSE,FALSE,character())
 expect_identical(x$antal_personroster,5L)
 expect_identical(x$namn,'A')
 expect_equal(x$andel_personroster,5/15)
})
