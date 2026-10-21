# Hand-built allocations exercise the public selection/composition paths without
# archived personal data or live requests.
re_test_raw <- function(table, e, level) {
  if(table=='seats') {
    x<-.mandat_schema_2026()[1,,drop=FALSE]
    x$valtyp<-e$election_code;x$geografiniva<-level
    x$valomradeskod<-if(e$election_code=='KF')substr(e$scope_code,1,4)else e$scope_code
    x$valomradesnamn<-e$scope_name;x$partiforkortning<-'A';x$partibeteckning<-'Test party'
    x$partikod<-'0001';x$antal_mandat<-e$seats_expected;x$totalt_antal_mandat<-e$seats_expected
    x$rakningstillfalle<-'slutlig'
    if(e$scope_level=='municipal_constituency'){x$valkretskod<-e$scope_code;x$valkretsnamn<-e$scope_name}
    return(.re_metadata(x,e))
  }
  x<-.valresultat_schema()[1,,drop=FALSE]
  x$valtyp<-e$election_code;x$geografiniva<-level;x$rakningstillfalle<-'slutlig'
  x$valomradeskod<-if(e$election_code=='KF')substr(e$scope_code,1,4)else e$scope_code
  x$valomradesnamn<-e$scope_name;x$kommunkod<-if(e$election_code=='KF')substr(e$scope_code,1,4)else NA_character_
  x$kommunnamn<-if(e$election_code=='KF')'Test municipality'else NA_character_
  if(e$scope_level=='municipal_constituency'){x$kommunvalkretskod<-e$scope_code;x$kommunvalkretsnamn<-e$scope_name}
  x$partiforkortning<-'A';x$partibeteckning<-'Test party';x$partikod<-'0001';x$ovriga_partier<-FALSE
  x$antal_roster<-100L;x$giltiga_roster<-100L;x$totalt_antal_roster<-102L
  x$antal_rostberattigade<-200L;x$blanka_roster<-1L;x$ovriga_ogiltiga<-1L;x$ogiltiga_roster<-2L
  .re_metadata(x,e)
}

re_test_sources <- function() {
  testthat::local_mocked_bindings(.re_file=function(...)list(path='fixture.xml',sha256='fixture-sha'),
    .re_verify_allocation=function(...) invisible(TRUE),
    .re_xml=function(e,file,table,level)re_test_raw(table,e,level),
    .re_2011=function(e,file,table,level)re_test_raw(table,e,level),.env=parent.frame())
}

test_that('event registry identifies five separate reruns and continuing periods', {
  x<-election_events(election_kind='re_election')
  expect_equal(nrow(x),5L);expect_false(anyDuplicated(x$election_event)>0L)
  e<-x[x$scope_code=='188004',]
  expect_equal(e$seats_expected,17L);expect_equal(e$original_year,2010L)
  expect_equal(e$mandate_period,'KF-2010-2014')
  expect_equal(e$electoral_roll_reference_date,'2011-04-15')
  expect_true(all(is.na(x$annulment_decision_reference)))
  expect_equal(nrow(election_events(2011,'regional','re_election')),1L)
})

test_that('ordinary-only defaults never substitute a re-election', {
  expect_error(results(year=2011,election='municipal'),'election_kind.*re_election')
  expect_error(seats(year=2015,election='municipal'),'Re-election available')
  expect_error(results(year=2011,election='municipal',election_kind='bad'),'election_kind')
  expect_error(seats(year=2010,after_re_election=NA),'TRUE or FALSE')
})

test_that('all five event selections retain scope, year, metadata and projections', {
  local_mocked_bindings(.re_file=function(...)list(path='fixture.xml',sha256='fixture-sha'),
    .re_verify_allocation=function(...) invisible(TRUE),
    .re_xml=function(e,file,table,level)re_test_raw(table,e,level),
    .re_2011=function(e,file,table,level)re_test_raw(table,e,level))
  for(i in seq_len(nrow(.re_elections()))) {
    e<-.re_elections()[i,]
    for(f in list(results,seats)) {
      a<-list(year=e$election_year,election=e$election_code,election_kind='re_election',source='local')
      standard<-do.call(f,c(a,list(detail='standard',names='en')))
      full<-do.call(f,c(a,list(detail='full',names='en')))
      sv<-do.call(f,c(a,list(detail='standard',names='sv')))
      expect_identical(standard,full[names(standard)])
      expect_identical(.public_output(sv,'en'),standard)
      expect_true(all(standard$event_scope_code==e$scope_code))
      expect_true(all(standard$election_year==e$election_year))
      expect_true(all(standard$original_election_event==e$original_election_event))
      if(identical(f,seats))expect_equal(sum(standard$seats),e$seats_expected)
    }
  }
})

test_that('event ranges select all reruns and do not reinterpret year as parent year', {
  local_mocked_bindings(.re_file=function(...)list(path='fixture.xml',sha256='fixture-sha'),
    .re_verify_allocation=function(...) invisible(TRUE),
    .re_xml=function(e,file,table,level)re_test_raw(table,e,level),
    .re_2011=function(e,file,table,level)re_test_raw(table,e,level))
  x<-seats(from=2002,to=2022,election='municipal',election_kind='re_election',source='local')
  expect_identical(x$election_year,c(2003L,2011L,2015L,2019L))
  expect_error(seats(year=2010,election='municipal',election_kind='re_election'),'No matching')
  expect_error(results(year=2011,from=2010,election='municipal',election_kind='re_election'),'alternative')
  expect_error(seats(year=2011,election='municipal',election_kind='re_election',source='canonical'),'No canonical')
  expect_error(results(year=2011,election='municipal',election_kind='re_election',count='preliminary',source='local'),'final sources will not replace')
})

test_that('post-re-election rejects event-year and incompatible selections', {
  expect_error(seats(year=2011,election='municipal',after_re_election=TRUE),'original ordinary')
  expect_error(seats(year=2010,election_kind='all',after_re_election=TRUE),'requires')
  expect_error(seats(year=2010,count='preliminary',after_re_election=TRUE),'final allocations')
  expect_error(seats(year=2010,election='municipal',level='district',after_re_election=TRUE),'whole-area')
})

test_that('component provenance distinguishes identical seat totals from different events', {
  x<-tibble::tibble(election_code='KF',municipality_code='1880',municipal_constituency_code=c('188001','188004'),seats=c(48L,17L))
  a<-.re_component(x[1,],'SE-KF-2010-09-19',2010L)
  b<-.re_component(x[2,],'SE-KF-2011-05-15-188004',2011L)
  z<-dplyr::bind_rows(a,b)
  expect_equal(sum(z$seats),65L)
  expect_identical(z$component_election_year,c(2010L,2011L))
  expect_identical(z$component_geographic_code,c('188001','188004'))
})

re_test_ordinary_mandates <- function(ar,val,niva,...) {
  parties<-c('M','C','FP','KD','S','V','MP','SD')
  rows<-lapply(1:4,function(k){
    z<-.mandat_schema_2026()[rep(NA_integer_,8),]
    z$valtyp<-'KF';z$valtillfalle<-paste0('Val_',ar);z$valar<-as.integer(ar)
    z$rakningstillfalle<-'slutlig';z$valomradeskod<-'1880';z$valomradesnamn<-'Örebro'
    z$geografiniva<-'kommunvalkrets';z$valkretskod<-paste0('18800',k);z$valkretsnamn<-paste('constituency',k)
    z$partiforkortning<-parties;z$partikod<-sprintf('%04d',1:8);z$partibeteckning<-parties
    z$antal_mandat<-c(if(k==4)4L else 3L,1L,1L,1L,7L,1L,1L,1L)
    z$totalt_antal_mandat<-as.integer(sum(z$antal_mandat));z
  }) |> dplyr::bind_rows()
  if(niva=='kommun')rows<-.re_aggregate_seats(rows,'kommun')
  .mandat_public_2026(rows,ar)
}
re_test_actual_2011 <- function(e,file,table,level) {
  z<-re_test_ordinary_mandates(2010L,'KF','kommunvalkrets')
  z<-z[z$valkretskod=='188004',]
  z$antal_mandat_fg<-z$antal_mandat;z$antal_mandat<-c(3L,1L,1L,1L,8L,1L,1L,1L)
  z$geografiniva<-level;.re_metadata(z,e)
}

test_that('Örebro composition replaces 17 seats and preserves the other 48', {
  local_mocked_bindings(.raw_public_api=utils::modifyList(.raw_public_api,list(mandat=re_test_ordinary_mandates)),
    .re_file=function(...)list(path='verified-fixture.skv',sha256='fixture-sha'),.re_2011=re_test_actual_2011)
  event<-seats(year=2011,election='municipal',election_kind='re_election',source='local')
  expect_equal(sum(event$seats),17L)
  x<-seats(year=2010,election='municipal',after_re_election=TRUE,source='local')
  expect_equal(sum(x$seats),65L)
  expect_equal(sum(x$seats[x$component_election_year==2010L]),48L)
  expect_equal(sum(x$seats[x$component_election_year==2011L]),17L)
  expect_true(all(x$election_year==2010L));expect_true(all(x$mandate_period=='KF-2010-2014'))
  expect_equal(sum(x$seats[x$party_abbreviation=='M']),12L)
  expect_equal(sum(x$seats[x$party_abbreviation=='S']),29L)
  expect_setequal(x$component_geographic_code,paste0('18800',1:4))
  full<-seats(year=2010,election='municipal',after_re_election=TRUE,source='local',detail='full')
  expect_identical(x,full[names(x)])
  sv<-mandat(ar=2010,val='KF',efter_omval=TRUE,source='local')
  expect_identical(.public_output(sv,'en'),x)
  expect_equal(sum(mandat(ar=2011,val='KF',valklass='omval',source='local')$antal_mandat),17L)
})

test_that('ordinary defaults, all-event ranges and adjusted ranges remain distinct', {
  local_mocked_bindings(.raw_public_api=utils::modifyList(.raw_public_api,list(mandat=re_test_ordinary_mandates)),
    .re_file=function(...)list(path='verified-fixture.skv',sha256='fixture-sha'),.re_2011=re_test_actual_2011)
  a<-seats(year=2010,election='municipal',level='municipality',source='local')
  expect_equal(sum(a$seats[a$party_abbreviation=='M']),13L)
  expect_identical(a,seats(year=2010,election='municipal',level='municipality',source='local',election_kind='ordinary'))
  all<-seats(from=2010,to=2011,election='municipal',level='municipality',source='local',election_kind='all')
  expect_setequal(all$election_year,c(2010L,2011L));expect_false(anyNA(all$election_event))
  expect_equal(sum(all$seats[all$election_year==2010L]),65L)
  expect_equal(sum(all$seats[all$election_year==2011L]),17L)
  adjusted<-seats(from=2006,to=2010,election='municipal',after_re_election=TRUE,source='local')
  expect_setequal(adjusted$election_year,c(2006L,2010L))
  expect_equal(sum(adjusted$seats[adjusted$election_year==2006L]),65L)
  expect_equal(sum(adjusted$seats[adjusted$election_year==2010L]),65L)
  unchanged<-seats(year=2006,election='municipal',level='municipality',source='local')
  no_re<-adjusted[adjusted$election_year==2006L,names(unchanged)]
  expect_equal(no_re,unchanged)
})

test_that('unverified replacements fail instead of publishing a partial composition', {
  local_mocked_bindings(.raw_public_api=utils::modifyList(.raw_public_api,list(mandat=re_test_ordinary_mandates)),
    .re_file=function(...)stop('Missing verified source'))
  expect_error(seats(year=2010,election='municipal',after_re_election=TRUE,source='local'),'Missing verified source')
})

test_that('successive partial reruns replace the current component without losing unaffected seats', {
  registry<-.re_elections();registry<-registry[registry$scope_code=='188004',]
  second<-registry;second$election_year<-2012L;second$election_date<-'2012-06-01'
  second$election_event<-'SE-KF-2012-06-01-188004'
  second$verified_allocation<-list(c(M=2L,C=1L,FP=1L,KD=1L,S=9L,V=1L,MP=1L,SD=1L))
  registry<-dplyr::bind_rows(registry,second)
  second_raw<-function(e,file,table,level) {
    z<-re_test_actual_2011(e,file,table,level)
    z$antal_mandat_fg<-c(3L,1L,1L,1L,8L,1L,1L,1L)
    z$antal_mandat<-c(2L,1L,1L,1L,9L,1L,1L,1L);z
  }
  local_mocked_bindings(.re_elections=function()registry,
    .raw_public_api=utils::modifyList(.raw_public_api,list(mandat=re_test_ordinary_mandates)),
    .re_file=function(...)list(path='fixture',sha256='fixture-sha'),
    .re_2011=function(e,file,table,level) if(e$election_year==2012L) second_raw(e,file,table,level) else re_test_actual_2011(e,file,table,level),.re_xml=second_raw)
  x<-seats(year=2010,election='municipal',after_re_election=TRUE,source='local')
  expect_equal(sum(x$seats),65L)
  expect_equal(sum(x$seats[x$component_election_year==2010L]),48L)
  expect_equal(sum(x$seats[x$component_election_year==2012L]),17L)
  expect_false(any(x$component_election_year==2011L))
  expect_equal(sum(x$seats[x$party_abbreviation=='M']),11L)
  expect_equal(sum(x$seats[x$party_abbreviation=='S']),30L)
})

test_that('historical collection ballot totals preserve the invalid-category definition', {
  node<-xml2::read_xml('<ONSDAGSDISTRIKT><OGILTIGA TEXT="OG" RÖSTER="1"/></ONSDAGSDISTRIKT>')
  x<-.valresultat_schema()[1,,drop=FALSE];x$giltiga_roster<-110L;x$ovriga_ogiltiga<-1L
  z<-.re_ballot_totals(x,node,2003L)
  expect_identical(z$totalt_antal_roster,111L)
  expect_identical(z$ogiltiga_roster,1L)
  expect_true(is.na(z$blanka_roster));expect_true(is.na(z$ovriga_ogiltiga))
  x$giltiga_roster<-100L;x$blanka_roster<-2L;x$ovriga_ogiltiga<-3L;x$roster_ej_anmalt_deltagande<-1L
  expect_identical(.re_ballot_totals(x,node,2019L)$totalt_antal_roster,106L)
  x$blanka_roster<-NA_integer_
  expect_true(is.na(.re_ballot_totals(x,node,2019L)$totalt_antal_roster))
})

test_that('national components and invalid years retain consistent selector semantics', {
  z<-.re_component(tibble::tibble(election_code='RD',seats=349L),'SE-RD-2010-09-19',2010L)
  expect_identical(z$component_geographic_level,'national')
  expect_identical(z$component_geographic_code,'00')
  expect_identical(.re_codes(c('municipal','KF')),'KF')
  expect_error(seats(year=1e20,election='KF',election_kind='re_election'),'integer')
  expect_error(seats(year=-1,election='KF',election_kind='re_election'),'integer')
})


test_that('count/report dates are not asserted to be legal decision or service dates', {
  e<-election_events(election_kind='re_election')
  expect_true(all(is.na(e$final_result_decision_date)))
  expect_true(is.na(e$final_count_ended_date[e$election_year==2003L]))
  expect_equal(e$final_count_ended_date[e$scope_code=='188004'],as.Date('2011-05-18'))
})

test_that('official 2011 party anchors make original and rerun components joinable', {
  x<-tibble::tibble(partiforkortning=c('M','S','unknown'),partikod=NA_character_,partibeteckning=NA_character_)
  z<-.re_party_metadata_2011(x)
  expect_identical(z$partikod,c('0001','0002',NA_character_))
  expect_identical(z$partibeteckning[1:2],c('Moderata Samlingspartiet','Arbetarepartiet-Socialdemokraterna'))
  x$partikod[1]<-'source-code';expect_identical(.re_party_metadata_2011(x)$partikod[1],'source-code')
})
