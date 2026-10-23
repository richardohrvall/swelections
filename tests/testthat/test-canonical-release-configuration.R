test_that("the release candidate activates exactly twelve scoped ordinary products", {
  r <- .canonical_release_registry()
  r <- r[r$event_kind == "ordinary", ]
  expected <- c(paste('rkl',c(2002,2006,2010,2014,2018,2022),sep=':'),
    paste('eu',c(2004,2009,2014,2019,2024),sep=':'),'folkomr:2003')
  expect_setequal(paste(r$series,r$year,sep=':'),expected)
  expect_true(all(r$auto_eligible)); expect_true(all(r$event_kind=='ordinary'))
  expect_true(all(r$data_version=='data-v0.4.1'))
  expect_identical(anyDuplicated(r$manifest_file),0L)
  expect_true(all(grepl('^(rkl|eu|referendum)[0-9]{4}-manifest[.]json$',r$manifest_file)))
  expect_true(all(r$base_url=='https://github.com/richardohrvall/swelections/releases/download/data-v0.4.1'))
  expect_identical(.canonical_release(2018L)$manifest_file,'rkl2018-manifest.json')
  expect_false(grepl('data-v0.1.0',.canonical_release(2018L)$base_url,fixed=TRUE))
  for (series in c('rkl','eu','folkomr')) {
    expect_null(.canonical_release(2026L,series))
    for (year in c(2003L,2011L,2015L,2019L))
      if (series == 'rkl') expect_true(.canonical_release(year,series,'re_election')$auto_eligible) else
        expect_null(.canonical_release(year,series,'re_election'))
  }
  expect_false('candidacies'%in%.canonical_release(2002L)$auto_functions)
  expect_false('preference_votes'%in%.canonical_release(2009L,'eu')$auto_functions)
  expect_identical(.canonical_release(2003L,'folkomr')$auto_functions,'results')
})

test_that("production registration resolves all unique manifest URLs without source overrides", {
  root<-tempfile();dir.create(root)
  on.exit(unlink(root,recursive=TRUE),add=TRUE)
  withr::local_options(swelections.canonical_manifest=NULL,swelections.canonical_cache_dir=root)
  registry<-.canonical_release_registry()
  registry<-registry[registry$event_kind=="ordinary",]
  seen<-character()
  local_mocked_bindings(.download_file=function(url,destfile,...) {
    i<-match(url,paste0(registry$base_url,'/',registry$manifest_file))
    expect_false(is.na(i));seen<<-c(seen,url)
    e<-registry[i,]
    m<-list(data_version=e$data_version,schema_version=3L,value_schema_version=1L,
      storage_schema_version=1L,valserie=e$series,valar=e$year,format='parquet',
      event_kind='ordinary',sources=list(),
      assets=data.frame(asset='fixture',file='fixture.parquet',bytes=1L,sha256=strrep('a',64)),
      tables=data.frame(asset='fixture',table='national',columns='election_code'))
    jsonlite::write_json(m,destfile,auto_unbox=TRUE)
  })
  paths<-vapply(seq_len(nrow(registry)),function(i)
    .canonical_manifest_path(registry$year[i],registry$series[i],auto_selected=TRUE),'')
  expect_length(unique(paths),12L);expect_length(seen,12L)
  for (i in seq_len(nrow(registry)))
    expect_identical(.canonical_manifest_path(registry$year[i],registry$series[i],auto_selected=TRUE),paths[i])
  expect_length(seen,12L)
  expect_false(any(endsWith(seen,'/manifest.json')))
})
