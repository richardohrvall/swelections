
.mhs_fixture <- function(year = 2022L) {
  start <- if(year == 2018L) "2018-09-09" else "2022-09-11"
  stamp <- if(year == 2018L) "2022-10-31" else "2026-10-15"
  dates <- if(year == 2018L)c("2020-01-01","2021-01-01","2019-01-01")else
    c("2024-01-01","2025-01-01","2023-01-01")
  a <- tibble::tibble(election_code="KF",electoral_area_code="0114",constituency="",
    party_code="0001",party_abbreviation="M",seats=3L)
  e <- a[c(1,1),setdiff(names(a),"seats")]
  e$seat_number<-c(1L,3L);e$candidate_number<-c("101","104");e$name<-c("A","D")
  row <- function(id,seat,begin,end) tibble::tibble(election_code="KF",
    electoral_area_code="0114",constituency="",party_code="0001",party_abbreviation="M",
    seat_number=as.integer(seat),candidate_number=id,name=id,start_date=as.Date(begin),
    end_date=as.Date(end),successor_number=NA_character_,event_date=as.Date(start),
    election_kind="ordinary",source_file="fixture",source_md5="fixture",
    source_as_of=as.Date(stamp),source_row=1L,source_kind="history")
  h<-dplyr::bind_rows(row("101",1,NA,dates[1]),row("102",1,dates[1],dates[2]),
    row("103",1,dates[2],NA),row("104",3,start,dates[3]))
  u<-dplyr::bind_rows(row("103",1,dates[2],NA),row(NA_character_,2,NA,NA),
    row(NA_character_,3,dates[3],NA))
  v<-a[1,setdiff(names(a),"seats")];v$vacancy_count<-2L
  list(a=a,e=e,h=h,u=u,v=v,year=year)
}
.mhs_manifest <- function(z, root) {
  dir.create(root,recursive=TRUE,showWarnings=FALSE)
  x<-.mh_present(.mh_build(z$year,z$a,z$e,z$h,z$u,NULL,z$v),"en","full")
  asset<-paste0("rkl",z$year,"-mandate-history")
  p<-file.path(root,paste0(asset,".parquet"));nanoparquet::write_parquet(x,p)
  m<-list(data_version="data-v0.4.0",schema_version=3L,value_schema_version=1L,
    storage_schema_version=1L,valserie="rkl",valar=z$year,format="parquet",sources=list(),
    assets=data.frame(asset=asset,file=basename(p),bytes=file.info(p)$size,sha256=.canonical_sha256(p)),
    tables=data.frame(asset=asset,table="intervals",columns=paste(names(x),collapse=",")))
  jsonlite::write_json(m,file.path(root,"manifest.json"),auto_unbox=TRUE)
  list(path=file.path(root,"manifest.json"),data=x)
}
.mhs_remote_fixture <- function(root, history_date="2026-10-15") {
  dir.create(root,recursive=TRUE)
  z<-.mhs_fixture()
  encode<-function(x) {
    data.frame(Valtyp=rep("KF",nrow(x)),Valtillfälle=rep("Val_20220911",nrow(x)),
      Länskod=rep("01",nrow(x)),Kommunkod=rep("14",nrow(x)),Valkretskod=rep("",nrow(x)),
      Partiförkortning=rep("M",nrow(x)),
      "Mandat (stol)"=x$seat_number,"Kandidatnummer ledamot"=x$candidate_number,
      Förnamn=x$name,Efternamn=rep("",nrow(x)),Invalsdatum=as.character(x$start_date),
      Avgångsdatum=as.character(x$end_date),check.names=FALSE)
  }
  data<-list(history=encode(dplyr::bind_rows(z$h,z$u[2,])),current=encode(z$u),
    departures=encode(z$h[0,]),vacancies=encode(z$u[1,]))
  data$vacancies$"Antal tomma stolar"<-"2"
  filenames<-c(history="ledamoter_med_historik.csv",current="nuvarande_ledamoter.csv",
    departures="avgangna_ledamoter.csv",vacancies="tomma_stolar.csv")
  for(k in names(data)) {
    p<-file.path(root,filenames[[k]])
    writeLines(paste0(";Valmyndigheten ",if(k=="history")history_date else "2026-10-15"),p)
    suppressWarnings(utils::write.table(data[[k]],p,sep=";",row.names=FALSE,
      col.names=TRUE,append=TRUE,na="",fileEncoding="UTF-8"))
  }
  z
}

test_that("history auto permissions cover only the two frozen periods and all three functions", {
  functions<-c("mandate_history","members_at","vacant_seats_at")
  for(y in c(2014L,2018L,2022L)) for(f in functions)
    expect_identical(.canonical_auto_function_allowed(.canonical_release(y),f),y!=2022L)
})

test_that("canonical history and both snapshots share one asset without local files", {
  skip_if_not_installed("nanoparquet")
  root<-tempfile();on.exit(unlink(root,recursive=TRUE),add=TRUE)
  f<-.mhs_manifest(.mhs_fixture(2018L),root)
  withr::local_options(swelections.canonical_manifest=f$path,
    swelections.canonical_cache_dir=file.path(root,"cache"),swelections.data_dir=NULL,
    valresultat.data_dir=NULL)
  local_mocked_bindings(.mh_files=function(...)stop("local forbidden"),
    .mh_remote_files=function(...)stop("remote forbidden"),.mh_original=function(...)stop("rebuild forbidden"))
  expect_identical(mandate_history(2018,detail="full"),f$data)
  expect_identical(mandate_history(2018,source="canonical",detail="full"),f$data)
  m<-members_at("2020-01-01",year=2018)
  v<-vacant_seats_at("2020-01-01",year=2018)
  expect_equal(m$candidate_number,"102");expect_equal(nrow(v),2L)
  expect_true(all(m$status=="occupied"));expect_true(all(v$status=="vacant"))
  expect_equal(nrow(m)+nrow(v),3L)
  expect_equal(nrow(ledamoter_vid("2020-01-01",ar=2018)),1L)
  expect_true(all(tomma_stolar_vid("2020-01-01",ar=2018)$status=="vakant"))
  expect_identical(mandathistorik(2018,names="en",detaljniva="full"),f$data)
  expect_error(members_at("2022-11-01",year=2018),"outside verified")
})

test_that("each snapshot has its own central permission", {
  registry<-.canonical_release_registry()
  i<-which(registry$year==2018 & registry$series=="rkl")
  registry$auto_functions[[i]]<-"mandate_history"
  local_mocked_bindings(.canonical_release_registry=function()registry,
    .canonical_manifest_path=function(...)stop("manifest forbidden"))
  expect_error(members_at("2020-01-01",year=2018),"No approved canonical")
  expect_error(vacant_seats_at("2020-01-01",year=2018),"No approved canonical")
})

test_that("2022 auto is fresh remote even with local files and a full private history manifest", {
  skip_if_not_installed("nanoparquet")
  root<-tempfile();on.exit(unlink(root,recursive=TRUE),add=TRUE)
  z<-.mhs_remote_fixture(file.path(root,"official"))
  f<-.mhs_manifest(z,file.path(root,"private"))
  withr::local_options(swelections.canonical_manifest=f$path,
    swelections.data_dir=root,valresultat.data_dir=root)
  calls<-character()
  local_mocked_bindings(.download_file=function(url,destfile,...) {
    calls<<-c(calls,url);expect_true(startsWith(url,"https://resultat.val.se/filer/val2022/info/"))
    stopifnot(file.copy(file.path(root,"official",basename(url)),destfile))
  },.mh_files=function(...)stop("local forbidden"),.mh_original=function(year,codes,root,source) {
    expect_identical(source,"auto");expect_null(root);list(allocations=z$a,elected=z$e)
  })
  x<-mandate_history(2022,detail="full")
  expect_length(calls,4L);expect_equal(nrow(x),6L)
  expect_true(all(grepl("^https://",stats::na.omit(x$source_file))))
  expect_true(all(x$coverage_end==as.Date("2026-10-15")))
  expect_equal(members_at("2024-01-01",year=2022)$candidate_number,"102")
  expect_equal(nrow(vacant_seats_at("2024-01-01",year=2022)),2L)
  expect_length(calls,12L) # Each query acquires a fresh complete set.
  expect_error(members_at("2026-10-16",year=2022),"outside verified")
  expect_error(vacant_seats_at("2026-10-16",year=2022),"outside verified")
  expect_identical(mandate_history(2022,source="remote",detail="full"),x)
})

test_that("remote coverage cannot exceed either the history or member snapshot", {
  root<-tempfile();on.exit(unlink(root,recursive=TRUE),add=TRUE)
  z<-.mhs_remote_fixture(root,history_date="2026-10-14")
  local_mocked_bindings(.download_file=function(url,destfile,...) {
    stopifnot(file.copy(file.path(root,basename(url)),destfile))
  },.mh_original=function(...)list(allocations=z$a,elected=z$e))
  x<-mandate_history(2022,source="remote")
  expect_true(all(x$coverage_end==as.Date("2026-10-14")))
  expect_error(members_at("2026-10-15",year=2022,source="remote"),"outside verified")
})

test_that("remote source failures never fall back to local files", {
  local_mocked_bindings(.download_file=function(...)stop("official unavailable"),
    .mh_files=function(...)stop("local forbidden"))
  expect_error(mandate_history(2022),"official unavailable")
  expect_error(mandate_history(2018,source="remote"),"supported for 2022 only")
  expect_error(mandate_history(2022,files=list(history="some-file")),"explicitly")
})

test_that("explicit local history retains the existing construction path", {
  z<-.mhs_fixture(2018L)
  rows<-list(history=z$h,current=z$u,departures=NULL,vacancies=z$v)
  local_mocked_bindings(.mh_files=function(...)rows,.mh_normalise=function(x,...)x,
    .mh_original=function(year,codes,root,source) {
      expect_identical(source,"local");list(allocations=z$a,elected=z$e)
    },.mh_remote_files=function(...)stop("remote forbidden"))
  root<-tempdir()
  expect_equal(nrow(mandate_history(2018,source="local",data_dir=root)),6L)
})


test_that("conflicting remote holder snapshots fail rather than inventing an interval", {
  z<-.mhs_fixture()
  x<-.mh_build(2022,z$a,z$e,z$h,z$u,NULL,z$v)
  current<-z$u;current$candidate_number[1]<-"999"
  expect_error(.mh_check_remote_current(x,current),"disagree")
})
