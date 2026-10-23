# No live sources or personal records: schema/transport/policy regression fixture.
re_canonical_fixture <- function() {
  skip_if_not_installed('nanoparquet')
  dir <- tempfile('rerun-canonical-');dir.create(dir)
  e <- .re_elections();e <- e[e$scope_code=='188004',]
  expected <- e$verified_allocation[[1]]
  x <- tibble::tibble(election_year=e$election_year,election_code=e$election_code,
    election_event=e$election_event,election_date=e$election_date,election_kind='re_election',
    original_election_event=e$original_election_event,mandate_period=e$mandate_period,
    event_scope_level=e$scope_level,event_scope_code=e$scope_code,event_scope_name=e$scope_name,
    geographic_level='municipal_constituency',count_stage='final',
    party_abbreviation=names(expected),seats=unname(as.integer(expected)),
    source_file='preserved/fixture.skv',previous_vote_share=NA_real_)
  assets <- layouts <- list()
  for(table in c('results','seats')) {
    a<-.re_canonical_asset(e,table);z<-x
    if(table=='results'){z$votes<-z$seats;z$seats<-NULL}
    cols<-names(z);z$.table<-'municipal_constituency'
    p<-file.path(dir,paste0(a,'.parquet'));nanoparquet::write_parquet(z,p)
    assets[[table]]<-data.frame(asset=a,file=basename(p),bytes=file.info(p)$size,sha256=.canonical_sha256(p))
    layouts[[table]]<-data.frame(asset=a,table='municipal_constituency',columns=paste(cols,collapse=','),standard_columns=paste(setdiff(cols,'previous_vote_share'),collapse=','))
  }
  m<-list(data_version='data-v0.4.0',valserie='rkl',valar=2011L,event_kind='re_election',
    schema_version=3L,value_schema_version=1L,storage_schema_version=1L,format='parquet',
    sources=list(),assets=dplyr::bind_rows(assets),tables=dplyr::bind_rows(layouts))
  p<-file.path(dir,'manifest.json');jsonlite::write_json(m,p,auto_unbox=TRUE)
  list(event=e,manifest=m,path=p)
}

test_that('rerun coverage is activated for results/seats only and ordinary approvals are unchanged', {
  reg<-.canonical_release_registry();re<-reg[reg$event_kind=='re_election',]
  expect_identical(re$year,c(2003L,2011L,2015L,2019L))
  expect_true(all(re$auto_eligible));expect_true(all(grepl("data-v0.4.1$",re$base_url)))
  expect_true(all(vapply(re$auto_functions,identical,logical(1),c('results','seats'))))
  expect_equal(sum(reg$event_kind=='ordinary'&reg$auto_eligible),12L)
  expect_false(.canonical_auto_function_allowed(.canonical_release(2011,'rkl','re_election'),'preference_votes'))
})

test_that('public canonical rerun requests need no raw archive and preserve scope and language', {
  f<-re_canonical_fixture()
  withr::local_options(list(swelections.canonical_manifest=c(`rkl:re_election:2011`=f$path),
    swelections.canonical_cache_dir=tempfile(),swelections.data_dir=NULL))
  local_mocked_bindings(.re_file=function(...)stop('must not read raw files'))
  for(fn in list(results,seats)) {
    a<-list(year=2011,election='KF',election_kind='re_election',source='canonical')
    full<-do.call(fn,c(a,list(detail='full')));std<-do.call(fn,a)
    expect_identical(full[names(std)],std)
    expect_true(all(std$event_scope_code=='188004'))
    expect_true(all(std$election_year==2011L))
    sv<-do.call(if(identical(fn,results))valresultat else mandat,
      list(ar=2011,val='KF',valklass='omval',source='canonical'))
    expect_identical(.public_output(sv,'en'),std)
    expect_identical(do.call(fn,utils::modifyList(a,list(source='auto'))),std)
    expect_error(do.call(fn,c(a,list(data_dir='user-archive'))),'raw data_dir')
  }
  expect_equal(sum(seats(2011,'KF',election_kind='re_election',source='canonical')$seats),17L)
  expect_error(results(2011,'KF',election_kind='re_election',source='canonical',count='preliminary'),'final sources will not replace')
  expect_error(results(2011,'KF',election_kind='re_election',source='canonical',level='district'),'unavailable')
  expect_error(results(2011,'RF',election_kind='re_election',source='canonical'),'unavailable')
})

test_that('prospective activation uses the central function and manifest view gates', {
  f<-re_canonical_fixture();reg<-.canonical_release_registry()
  reg$auto_eligible[reg$event_kind=='re_election']<-TRUE
  withr::local_options(list(swelections.canonical_manifest=c(`rkl:re_election:2011`=f$path),swelections.canonical_cache_dir=tempfile()))
  local_mocked_bindings(.canonical_release_registry=function()reg,
    .re_file=function(...)stop('must not read raw files'))
  a<-list(year=2011,election='KF',election_kind='re_election')
  expect_identical(do.call(results,a),do.call(results,c(a,list(source='canonical'))))
  expect_identical(do.call(seats,a),do.call(seats,c(a,list(source='canonical'))))
  expect_identical(do.call(results,c(a,list(data_dir='unused-user-archive'))),do.call(results,c(a,list(source='canonical'))))
  expect_identical(.select_public_source('auto',2011,'preference_votes',event_kind='re_election',val='KF'),'auto')
  expect_identical(.select_public_source('auto',2011,'results',event_kind='re_election',val='KF',niva='valdistrikt'),'auto')
})

test_that('rerun assets cannot silently bypass byte or event checks', {
  f<-re_canonical_fixture()
  withr::local_options(list(swelections.canonical_manifest=c(`rkl:re_election:2011`=f$path),swelections.canonical_cache_dir=tempfile()))
  asset<-.re_canonical_asset(f$event,'results');p<-file.path(dirname(f$path),paste0(asset,'.parquet'))
  z<-tibble::as_tibble(nanoparquet::read_parquet(p));z$event_scope_code[]<-'188001'
  nanoparquet::write_parquet(z,p)
  expect_error(results(2011,'KF',election_kind='re_election',source='canonical'),'SHA256|size')
  i<-f$manifest$assets$asset==asset
  f$manifest$assets$sha256[i]<-.canonical_sha256(p);f$manifest$assets$bytes[i]<-file.info(p)$size
  jsonlite::write_json(f$manifest,f$path,auto_unbox=TRUE)
  expect_error(results(2011,'KF',election_kind='re_election',source='canonical'),'verified event')
})

test_that('canonical rerun layouts preserve source vector names without changing vote values', {
  f<-re_canonical_fixture()
  a<-.re_canonical_asset(f$event,'results')
  labels<-names(f$event$verified_allocation[[1]])
  f$manifest$column_names_attributes<-setNames(list(list(municipal_constituency=list(votes=labels))),a)
  jsonlite::write_json(f$manifest,f$path,auto_unbox=TRUE)
  withr::local_options(list(swelections.canonical_manifest=c(`rkl:re_election:2011`=f$path),swelections.canonical_cache_dir=tempfile()))
  x<-results(2011,'KF',election_kind='re_election',source='canonical')
  expect_identical(names(x$votes),labels)
  expect_identical(unname(x$votes),unname(as.integer(f$event$verified_allocation[[1]])))
  expect_identical(names(valresultat(2011,'KF',valklass='omval',source='canonical')$antal_roster),labels)
})

test_that('canonical asset transport resolves the event-kind namespace', {
  f<-re_canonical_fixture();reg<-.canonical_release_registry()
  reg$base_url[reg$event_kind=='re_election']<-'https://example.invalid/re-election'
  withr::local_options(list(swelections.canonical_assets_dir=tempfile(),swelections.canonical_base_url=NULL))
  local_mocked_bindings(.canonical_release_registry=function()reg,
    .canonical_asset=function(manifest,asset,cache_dir,url)url)
  fetch<-.canonical_fetcher(f$manifest,f$path)
  a<-.re_canonical_asset(f$event,'results')
  expect_identical(fetch(a),paste0('https://example.invalid/re-election/',a,'.parquet'))
})

test_that('a full prototype cannot grant explicit canonical permissions for rerun candidate views', {
  f<-re_canonical_fixture()
  # A deliberately misleading manifest advertises all seven functions.
  f$manifest$auto_functions<-c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
  jsonlite::write_json(f$manifest,f$path,auto_unbox=TRUE)
  withr::local_options(swelections.canonical_manifest=c(`rkl:re_election:2011`=f$path))
  for(view in c('candidacies','candidates','elected','substitutes','preference_votes')) {
    expect_error(.select_public_source('canonical',2011L,view,event_kind='re_election',val='KF'),
      'prototype manifest cannot grant permission')
    expect_identical(.select_public_source('auto',2011L,view,event_kind='re_election',val='KF'),'auto')
    expect_false(.canonical_view_covered(f$manifest,view,'KF'))
    expect_identical(.select_public_source('local',2011L,view,event_kind='re_election',val='KF'),'local')
  }
})
