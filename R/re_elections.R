# Re-elections are polling events; replacements never create a new mandate period.
.re_elections <- function() {
  x <- tibble::tribble(
    ~election_year, ~election_date, ~election_code, ~scope_level, ~scope_code, ~scope_name, ~original_year, ~seats_expected,
    2003L, '2003-03-16', 'KF', 'municipality', '2034', 'Orsa', 2002L, 31L,
    2011L, '2011-05-15', 'RF', 'region', '14', 'V\u00e4stra G\u00f6taland', 2010L, 149L,
    2011L, '2011-05-15', 'KF', 'municipal_constituency', '188004', '\u00d6rebro Nord\u00f6stra', 2010L, 17L,
    2015L, '2015-05-10', 'KF', 'municipality', '1278', 'B\u00e5stad', 2014L, 41L,
    2019L, '2019-04-07', 'KF', 'municipality', '2080', 'Falun', 2018L, 61L
  )
  dates <- c(`2002`='2002-09-15', `2010`='2010-09-19', `2014`='2014-09-14', `2018`='2018-09-09')
  x$election_event <- paste('SE', x$election_code, x$election_date, x$scope_code, sep='-')
  x$election_kind <- 're_election'
  x$original_election_event <- paste('SE', x$election_code, unname(dates[as.character(x$original_year)]), sep='-')
  x$mandate_period <- paste(x$election_code, x$original_year, x$original_year + 4L, sep='-')
  x$electoral_roll_reference_date <- as.character(as.Date(x$election_date) - 30L)
  x$electoral_roll_basis <- 'Event-specific electoral roll; register reference 30 days before polling; corrections remain source-specific'
  x$electoral_area_code <- c("2034","14","1880","1278","2080")
  x$electoral_area_name <- c("Orsa","V\u00e4stra G\u00f6taland","\u00d6rebro","B\u00e5stad","Falun")
  x$comparison_stem <- c(NA_character_,"slutlig2011_vg_jmf2010","slutlig2011_orebro_jmf2010",NA_character_,NA_character_)
  x$geography_file <- c(NA_character_,"rostberattigade_vg.skv",NA_character_,NA_character_,NA_character_)
  x$geography_sha256 <- c(NA_character_,"0efad66b41405c587e74153f84ed4718677d7ccd7097e8a9c9eef8f4b705fdef",NA_character_,NA_character_,NA_character_)
  x$source_url <- c(
    'https://web.archive.org/web/20030426223258id_/http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml',
    'https://historik.val.se/val/om2011/statistik/index.html',
    'https://historik.val.se/val/om2011/statistik/index.html',
    'https://historik.val.se/val/omval2015/statistik/index.html',
    'https://historik.val.se/val/omval2019/statistik/index.html')
  x$protocol_reference <- c('Orsa: archived 20030426223538 protocol index; eight attachments unrecovered',
    '201-11603-2011; final count 2011-05-16--19', '201-2641-2011; final count 2011-05-16--18',
    '201-12469-15; final count 2015-05-11--13', '201-4378-2019; final count 2019-04-08--10')
  # Do not invent decision identifiers/dates that the source inventory did not establish.
  x$annulment_decision_reference <- NA_character_
  x$annulment_decision_date <- as.Date(NA)
  x$final_results_available <- TRUE; x$final_seats_available <- TRUE
  x$canonical_available <- vapply(x$election_year, function(y) {
    e <- .canonical_release(y, "rkl", "re_election")
    isTRUE(e$auto_eligible) && all(c("results", "seats") %in% e$auto_functions)
  }, logical(1))
  x$preliminary_available <- FALSE
  x$verified_allocation <- list(c(M=2L,C=8L,FP=1L,KD=2L,S=12L,V=2L,MP=1L,SPI=2L,SD=1L),
    c(M=38L,C=9L,FP=11L,KD=9L,S=52L,V=9L,MP=12L,SD=9L),
    c(M=3L,C=1L,FP=1L,KD=1L,S=8L,V=1L,MP=1L,SD=1L),
    c(M=8L,C=5L,FP=3L,S=5L,MP=2L,SD=5L,BJP=13L),
    c(M=12L,C=10L,L=2L,KD=3L,S=17L,V=7L,MP=3L,SD=6L,FAP=1L))
  x$final_result_decision_date <- as.Date(NA)
  x$final_count_ended_date <- as.Date(c(NA_character_,"2011-05-19","2011-05-18","2015-05-13","2019-04-10"))
  x$final_sha256 <- c("2ed9f72f36cbbb2b682d42d7a299a388b2c394d9ee4e3b393c46c9cd1fe4775c",
    "d7f0376576a7f4430744c1d64119a4b2e42a1c5fa4301e5bba6b9d5dfb00d61b",
    "5f98b89304b53f7ccd8725aaac05e7d3990ac6269fecc466a657992438e8105a",
    "efd915e8061c6673193e039214ea18dce6ae2fdee04a66b437fb7e4b3037d448",
    "702ced856dd50171b7674d16949ec6eb3746cb59e5210fe866b692065cfad314")
  x$seats_sha256 <- x$final_sha256
  x$seats_sha256[2:3] <- c("0a91bd69152fcee1e330458e34027467daf562cca821fde66106963f3a98c5dd",
    "6b2fb983b5a8a6b50483145916285685f61c1d4126a57119eb4a271c1df17099")
  x
}

.check_election_kind <- function(x) {
  if (!is.character(x) || length(x)!=1L || is.na(x) || !x %in% c('ordinary','re_election','all'))
    stop('`election_kind` must be ordinary, re_election or all.', call.=FALSE)
  x
}

.re_codes <- function(election) {
  if (is.null(election)) return(c('RD','RF','KF'))
  unique(.english_argument_value(election, 'election'))
}

.re_years <- function(year, year_missing, from, to, available) {
  if ((!is.null(from)||!is.null(to)) && !year_missing)
    stop('`year` and `from`/`to` are alternative selectors.',call.=FALSE)
  if (!is.null(from)||!is.null(to)) {
    lo <- if(is.null(from)) -Inf else .valar_grans(from,'from')
    hi <- if(is.null(to)) Inf else .valar_grans(to,'to')
    if(lo>hi) stop('`from` must not exceed `to`.',call.=FALSE)
    return(sort(available[available>=lo & available<=hi]))
  }
  if(identical(year,'all')) return(sort(available))
  if(!is.numeric(year)||!length(year)||anyNA(year)||any(!is.finite(year))||any(year!=trunc(year))||any(year<1|year>.Machine$integer.max))
    stop('`year` must contain integer event years or all.',call.=FALSE)
  unique(as.integer(year))
}

#' Discover ordinary elections and re-elections
#'
#' List election events, their geographic scope and links to the original
#' election. Discovery requires no result downloads.
#' This function has no `names` argument. Use [valtillfallen()] for Swedish metadata.
#'
#' @details
#' A re-election is a separate polling event within the original continuing
#' mandate period. It is neither a new ordinary election in a longitudinal series
#' nor the start of a new mandate period. Each re-election links to its original
#' election and retains its actual geographic scope.
#'
#' Use [results()] and [seats()] with `election_kind = "re_election"` for event
#' results/allocations. Use [seats()] with `after_re_election = TRUE` and the
#' original ordinary year for a derived composition retaining the original year.
#' Örebro has 17 seats in its 2011 Nordöstra event and 65 in its adjusted 2010
#' composition (48 + 17). Discovery requires no source downloads. Current
#' final result/seat readers use canonical for auto/canonical; local sources
#' require explicit local selection. Canonical availability refers only to these
#' two views, not the five unimplemented candidate-related views. Remote and
#' preliminary re-election support are unavailable. Unknown legal decision dates remain missing.
#' @examples
#' election_events(election_kind = "re_election")
#' election_events(2003, "municipal", "re_election") # Orsa
#' election_events(2011, "regional", "re_election") # Västra Götaland
#' election_events(2011, "municipal", "re_election") # Örebro Nordöstra
#' election_events(2015, "municipal", "re_election") # Båstad
#' election_events(2019, "municipal", "re_election") # Falun
#' @seealso [valtillfallen()], [results()], [seats()]
#' @param year Event year(s), or `"all"`.
#' @param election Election type(s), as in [results()]. `NULL` selects RD/RF/KF.
#' @param election_kind `"ordinary"`, `"re_election"` or `"all"`.
#' @return An English metadata tibble. Availability is distinct from source completeness.
#'   Unknown decision references remain missing. Re-elections share the original mandate period.
#' @export
election_events <- function(year='all', election=NULL, election_kind='all') {
  kind <- .check_election_kind(election_kind); codes <- .re_codes(election)
  re <- .re_elections(); re <- re[re$election_code %in% codes,]
  if(kind=='re_election') out <- re else {
    dates <- c(`2002`='2002-09-15',`2006`='2006-09-17',`2010`='2010-09-19',
      `2014`='2014-09-14',`2018`='2018-09-09',`2022`='2022-09-11',`2026`='2026-09-13')
    ordinary <- purrr::map(codes,function(v) {
      yrs <- .stodd_valar('mandat',v)
      # EU elections have a separate existing dispatcher and do not acquire omval semantics here.
      ds <- if(v=='E') c(`2004`='2004-06-13',`2009`='2009-06-07',`2014`='2014-05-25',`2019`='2019-05-26',`2024`='2024-06-09') else dates
      tibble::tibble(election_event=paste('SE',v,unname(ds[as.character(yrs)]),sep='-'),
        election_year=yrs,election_date=unname(ds[as.character(yrs)]),election_code=v,
        election_kind='ordinary',scope_level='national',scope_code='00',scope_name='Sweden',
        original_election_event=NA_character_,original_year=NA_integer_,
        mandate_period=paste(v,yrs,yrs+if(v=='E')5L else 4L,sep='-'))
    }) |> purrr::list_rbind()
    out <- if(kind=='ordinary') ordinary else dplyr::bind_rows(ordinary,re)
  }
  if(!identical(year,'all')) { yrs <- .re_years(year,FALSE,NULL,NULL,unique(out$election_year));out<-out[out$election_year %in% yrs,] }
  out[order(out$election_date,out$election_code,out$scope_code),]
}

#' Upptäck ordinarie val och omval
#'
#' Svensk motsvarighet till [election_events()]. Funktionen listar valtillfällen
#' utan att hämta resultat. Omval är egna valtillfällen inom den ursprungliga
#' mandatperioden. Listan hjälper till att välja år och valtyp, men behöver inte
#' anropas före [valresultat()] eller [mandat()].
#'
#' @param ar Valhändelsens år, en vektor av år eller `"alla"`.
#' @param val Valtyp RD, RF eller KF, alternativt E för Europaparlamentsval.
#'   `NULL` väljer RD, RF och KF, precis som i [election_events()].
#' @param valklass `"ordinarie"`, `"omval"` eller `"alla"`.
#'   Motsvarande engelska värden accepteras också.
#' @return En tibble med svenska kolumnnamn och tekniska kategorier. Namn,
#'   valtillfälles-ID, datum, källhänvisningar och sakuppgifter bevaras.
#'   Tillgänglighetsuppgifter är metadata, inte en garanti om alla datavyer.
#' @seealso [election_events()], [valresultat()], [mandat()]
#' @examples
#' valtillfallen(valklass = "omval")
#' valtillfallen(ar = 2011, val = "KF", valklass = "omval")
#' @export
valtillfallen <- function(ar = "alla", val = NULL, valklass = "alla") {
  if (identical(ar, "alla")) ar <- "all"
  x <- election_events(year = ar, election = val,
    election_kind = .swedish_election_kind(valklass))
  x <- .values_present(x, "sv")
  basis <- "Event-specific electoral roll; register reference 30 days before polling; corrections remain source-specific"
  if ("electoral_roll_basis" %in% names(x)) {
    hit <- !is.na(x$electoral_roll_basis) & x$electoral_roll_basis == basis
    x$electoral_roll_basis[hit] <- paste0("Valtillf\u00e4llets egen r\u00f6stl\u00e4ngd; registerdatum 30 dagar f\u00f6re valdagen; ",
      "r\u00e4ttelser \u00e4r k\u00e4llspecifika")
  }
  columns <- c(election_year = "valar", election_date = "valdatum",
    election_code = "valtyp", scope_level = "omfattningsniva",
    scope_code = "omfattningskod", scope_name = "omfattningsnamn",
    original_year = "ursprungligt_valar", seats_expected = "forvantade_mandat",
    election_event = "valtillfalle", election_kind = "valklass",
    original_election_event = "ursprungligt_valtillfalle", mandate_period = "mandatperiod",
    electoral_roll_reference_date = "rostlangd_referensdatum", electoral_roll_basis = "rostlangdsgrund",
    electoral_area_code = "valomradeskod", electoral_area_name = "valomradesnamn",
    comparison_stem = "jamforelsefilbas", geography_file = "geografifil",
    geography_sha256 = "geografi_sha256", source_url = "kalla_url",
    protocol_reference = "protokollreferens", annulment_decision_reference = "upphavandebeslut_referens",
    annulment_decision_date = "upphavandebeslut_datum", final_results_available = "slutresultat_tillgangligt",
    final_seats_available = "slutlig_mandatfordelning_tillganglig", canonical_available = "canonical_tillgangligt",
    preliminary_available = "preliminar_tillgangligt", verified_allocation = "verifierad_mandatfordelning",
    final_result_decision_date = "slutresultat_beslutsdatum", final_count_ended_date = "slutrakning_avslutad_datum",
    final_sha256 = "slutresultat_sha256", seats_sha256 = "mandat_sha256")
  stopifnot(all(names(x) %in% names(columns)))
  names(x) <- unname(columns[names(x)])
  x
}

.re_ordinary_hint <- function(year, election, from, to) {
  if(!is.null(from)||!is.null(to)||!is.numeric(year)) return(invisible(NULL))
  re <- .re_elections(); hit <- re[re$election_year %in% year & re$election_code %in% .re_codes(election),]
  if(nrow(hit)) stop('No ordinary election for ',paste(unique(hit$election_year),collapse=', '),
    '. Re-election available: ',paste(hit$scope_name,collapse=', '),
    '. Use `election_kind = "re_election"`; discover events with `election_events()`.',call.=FALSE)
}

.re_file <- function(event, data_dir, which='final') {
  root <- val_data_dir(data_dir)
  if(is.null(root)) stop('Re-elections require a preserved local source archive in `data_dir`.',call.=FALSE)
  config <- getOption('swelections.re_election_sources',list())[[event$election_event]]
  if(!is.null(config) && !is.null(config[[which]])) candidates <- config[[which]] else {
    yr <- as.character(event$election_year)
    base <- c(file.path(root,'omval',yr),file.path(root,yr),root)
    leaf <- if(!is.na(event$comparison_stem)) paste0(event$comparison_stem,'_',if(which=='seats')'mandat'else'antal','.skv') else
      if(event$election_year==2003L)'slutresultat_2034K.xml'else'slutresultat.zip'
    candidates <- unique(c(file.path(base,leaf),file.path(base,'valres',leaf),file.path(base,'valmyndigheten',leaf)))
  }
  candidates <- candidates[file.exists(candidates)]
  if(!length(candidates)) stop('Missing preserved ',which,' source for ',event$election_event,
    '. Configure `data_dir` or `options(swelections.re_election_sources = ...)`.',call.=FALSE)
  hashes <- unname(tools::sha256sum(candidates))
  if(length(unique(hashes))!=1L) stop('Ambiguous source snapshots for ',event$election_event,call.=FALSE)
  expected <- if(which=="seats") event$seats_sha256 else event$final_sha256
  if(!identical(hashes[[1]],expected)) stop("Source checksum differs from the reviewed snapshot for ",event$election_event,call.=FALSE)
  list(path=candidates[[1]],sha256=hashes[[1]])
}

.re_metadata <- function(x,e) {
  x$valtillfalle <- rep(e$election_event,nrow(x)); x$valar <- rep(e$election_year,nrow(x))
  x$valdatum <- rep(e$election_date,nrow(x));x$valklass <- rep('re_election',nrow(x));x
}

.re_party_register <- function(doc,val,area) {
  p <- xml2::xml_find_all(doc,'./PARTI'); aliases <- xml2::xml_attr(p,'F\u00d6RKORTNING')
  base <- .xml2014_register(doc,val,area)$data
  rows <- tibble::tibble(valtyp=val,valomradeskod=area,partiforkortning=aliases,
    partibeteckning=xml2::xml_attr(p,'BETECKNING'),partikod=paste0('source-unresolved:',aliases))
  k <- match(rows$partiforkortning,base$partiforkortning)
  rows$partikod[!is.na(k)] <- base$partikod[k[!is.na(k)]]
  .xml2018_reg_index(rows)
}

.re_xml <- function(e,file,table,level) {
  if(e$election_year==2003L) doc <- xml2::read_xml(file,options=c('NONET','NOBLANKS')) else {
    member <- paste0('slutresultat_',e$scope_code,'K.xml')
    con <- unz(file,member,open='rb');on.exit(close(con),add=TRUE)
    doc <- xml2::read_xml(con,options=c('NONET','NOBLANKS'))
  }
  if(!grepl('Omval',.xml2018_attr(doc,'TILLF\u00c4LLE'),fixed=TRUE) ||
     !identical(.xml2018_attr(xml2::xml_find_first(doc,'./KOMMUN'),'KOD'),e$scope_code))
    stop('Wrong re-election source scope: ',e$election_event,call.=FALSE)
  if(e$election_year!=2003L && .xml2018_attr(doc,'VALDAG')!=gsub('-','',e$election_date))
    stop('Wrong re-election polling date.',call.=FALSE)
  if(e$election_year==2003L && !identical(.xml2018_attr(doc,'TILLF\u00c4LLE'),'Omval 16 Mars 2003'))
    stop('Ordinary Orsa 2002 must not be used as the 2003 re-election.',call.=FALSE)
  supported <- if(table=='seats')'kommun'else c('kommun','valdistrikt')
  if(!level %in% supported) stop('Unsupported level for ',e$election_event,': ',level,call.=FALSE)
  reg <- .re_party_register(doc,'KF',e$scope_code)
  nodes <- .xml2018_noder(doc,level,'KF')
  if(table=='seats' && e$election_year==2003L) doc <- .xml2006_appointment_slots(doc,'KF')
  if(table=='seats') nodes <- xml2::xml_find_all(doc,'./KOMMUN')
  out <- purrr::map(nodes,function(n) {
    if(table=='seats') return(.xml2018_mandatrader(n,doc,doc,'KF',level,reg))
    .xml2006_other_parties(n)
    .re_ballot_totals(.xml2018_partirader(n,.xml2018_geo(n,'KF',level,doc),doc,'KF',reg),n,e$election_year)
  }) |> purrr::list_rbind()
  out$partikod[grepl('^source-unresolved:',out$partikod)] <- NA_character_
  out <- .re_metadata(out,e)
  if(table=='seats') out <- .mandat_public_2026(.kort_kommunnamn_2026(out),e$election_year) else {
    out <- .valresultat_public_andelar_2026(out)
    out$valar <- rep(e$election_year,nrow(out))
  }
  out
}

.re_read_skv <- function(file) suppressMessages(readr::read_delim(file,delim=';',
  col_types=readr::cols(.default='c'),locale=readr::locale(encoding='Windows-1252'),
  name_repair='unique',show_col_types=FALSE,progress=FALSE))

.re_2011 <- function(e,file,table,level) {
  x <- .re_read_skv(file)
  if(table=='seats') {
    if(!level %in% if(e$election_code=='KF')c('kommun','kommunvalkrets')else c('region','regionvalkrets'))
      stop('Unsupported 2011 re-election mandate level.',call.=FALSE)
    cols <- seq(2L,ncol(x),3L)
    rows <- purrr::map(seq_len(nrow(x)),function(i) {
      out <- .mandat_schema_2026()[rep(NA_integer_,length(cols)),]
      out$valtyp <- e$election_code;out$geografiniva <- if(e$election_code=='KF')'kommunvalkrets'else'regionvalkrets'
      out$valomradeskod <- e$electoral_area_code
    out$valomradesnamn <- e$electoral_area_name
      out$valkretskod <- if(e$election_code=='KF')e$scope_code else paste0(e$electoral_area_code,sprintf('%02d',i))
      out$valkretsnamn <- x[[1]][i];out$partiforkortning <- names(x)[cols]
      out$antal_mandat <- as.integer(unlist(x[i,cols]));out$antal_mandat_fg <- as.integer(unlist(x[i,cols+2L]))
      out$diff_antal_mandat <- out$antal_mandat-out$antal_mandat_fg
      out$totalt_antal_mandat <- as.integer(sum(out$antal_mandat));out$antal_fasta_mandat <- NA_integer_
      # These comparison files do not report each party's adjustment-seat component.
      out$rakningstillfalle <- 'slutlig';out
    }) |> purrr::list_rbind()
    if(level=='region') rows <- .re_aggregate_seats(rows,'region')
    if(level=='kommun') rows$geografiniva <- 'kommun'
    return(.re_metadata(.re_party_metadata_2011(rows),e))
  }
  supported <- if(e$election_code=='KF')c('valdistrikt','kommun','kommunvalkrets')else c('valdistrikt','kommun','region','regionvalkrets')
  if(!level %in% supported) stop('Unsupported 2011 re-election result level.',call.=FALSE)
  party_cols <- seq(6L,match('BLANK',names(x))-3L,3L)
  regional_map <- NULL
  if(e$election_code=="RF") {
    ef <- file.path(dirname(file),e$geography_file)
    if(!file.exists(ef)) stop("Missing official 2011 constituency/electorate geography file.",call.=FALSE)
    if(unname(tools::sha256sum(ef))!=e$geography_sha256) stop("Unreviewed 2011 electorate/geography snapshot.",call.=FALSE)
    regional_map <- unique(.re_read_skv(ef)[c("kommun_id","landstingsvalkrets_id","landstingsvalkrets_namn")])
    if(anyDuplicated(regional_map$kommun_id)) stop("Municipality spans multiple RF constituencies; collection geography requires explicit source keys.",call.=FALSE)
  }
  rows <- purrr::map(seq_len(nrow(x)),function(i) {
    out <- .valresultat_schema()[rep(NA_integer_,length(party_cols)),]
    muni <- paste0(sprintf('%02d',as.integer(x[[1]][i])),sprintf('%02d',as.integer(x[[2]][i])))
    collection <- grepl('Onsdag',x[[5]][i],ignore.case=TRUE)
    out$valtyp <- e$election_code;out$geografiniva <- 'valdistrikt';out$rakningstillfalle <- 'slutlig'
    out$kommunkod <- muni;out$kommunnamn <- x[[4]][i];out$lankod <- substr(muni,1,2)
    out$valomradeskod <- e$electoral_area_code
    out$valomradesnamn <- e$electoral_area_name
    out$valdistriktskod <- if(collection)paste0(if(e$election_code=='KF')'K'else'L','-',muni,'-',sprintf('%02d',as.integer(x[[3]][i])))else paste0(muni,sprintf('%04d',as.integer(x[[3]][i])))
    out$valdistriktsnamn <- x[[5]][i];out$valdistriktstyp <- if(collection)'uppsamlingsdistrikt'else'valdistrikt'
    if(e$election_code=="KF"){out$kommunvalkretskod<-e$scope_code;out$kommunvalkretsnamn<-e$scope_name}
    if(!is.null(regional_map)) {
      k<-match(muni,regional_map$kommun_id)
      if(is.na(k))stop("Missing official RF constituency assignment.",call.=FALSE)
      out$valkretskod<-regional_map$landstingsvalkrets_id[k]
      out$valkretsnamn<-regional_map$landstingsvalkrets_namn[k]
    }
    out$partiforkortning <- names(x)[party_cols];out$ovriga_partier <- out$partiforkortning=='\u00d6VR'
    out$partibeteckning <- ifelse(out$ovriga_partier,'\u00d6vriga partier',NA_character_)
    out$antal_roster <- as.integer(unlist(x[i,party_cols]));out$antal_roster_fg <- as.integer(unlist(x[i,party_cols+2L]))
    out$giltiga_roster <- as.integer(x[['Rost Giltiga']][i]);out$totalt_antal_roster <- as.integer(x[['Rostande']][i])
    out$antal_rostberattigade <- as.integer(x[['Rostb']][i]);out$blanka_roster <- as.integer(x[['BLANK']][i])
    out$ovriga_ogiltiga <- as.integer(x[['OG']][i]);out$ogiltiga_roster <- out$totalt_antal_roster-out$giltiga_roster
    if(sum(out$antal_roster)!=out$giltiga_roster[1])stop('2011 party votes do not match valid votes.',call.=FALSE)
    out
  }) |> purrr::list_rbind()
  if(level!='valdistrikt') {
    group <- if(level=='kommun')rows$kommunkod else if(level=='regionvalkrets')rows$valkretskod else rep(e$scope_code,nrow(rows))
    rows <- purrr::map(unique(group),function(g) {
      z<-rows[group==g,];out<-z[!duplicated(z$partiforkortning),]
      out$antal_roster<-vapply(out$partiforkortning,function(p)as.integer(sum(z$antal_roster[z$partiforkortning==p])),integer(1))
      out$antal_roster_fg<-vapply(out$partiforkortning,function(p)as.integer(sum(z$antal_roster_fg[z$partiforkortning==p])),integer(1))
      units<-z[!duplicated(z$valdistriktskod),]
      for(n in c('giltiga_roster','totalt_antal_roster','blanka_roster','ovriga_ogiltiga','ogiltiga_roster'))out[[n]]<-as.integer(sum(units[[n]]))
      ordinary<-units[units$valdistriktstyp=='valdistrikt',]
      out$antal_rostberattigade<-if(anyNA(ordinary$antal_rostberattigade))NA_integer_ else as.integer(sum(ordinary$antal_rostberattigade))
      out$geografiniva<-level;out$valdistriktskod<-out$valdistriktsnamn<-out$valdistriktstyp<-NA_character_
      if(level %in% c('region','regionvalkrets')){out$kommunkod<-out$kommunnamn<-NA_character_}; if(level=="region") {out$valkretskod<-out$valkretsnamn<-NA_character_};out
    }) |> purrr::list_rbind()
  }
  rows$andel_roster <- rows$antal_roster/rows$giltiga_roster
  rows$valdel <- rows$totalt_antal_roster/rows$antal_rostberattigade
  .re_metadata(.re_party_metadata_2011(rows),e)
}

.re_aggregate_seats <- function(x,level) {
  out <- x[!duplicated(x$partiforkortning),]
  out$antal_mandat <- vapply(out$partiforkortning,function(p)as.integer(sum(x$antal_mandat[x$partiforkortning==p])),integer(1))
  out$antal_mandat_fg <- vapply(out$partiforkortning,function(p)as.integer(sum(x$antal_mandat_fg[x$partiforkortning==p])),integer(1))
  out$diff_antal_mandat<-out$antal_mandat-out$antal_mandat_fg
  out$geografiniva<-level;out$valkretskod<-out$valkretsnamn<-NA_character_
  out$totalt_antal_mandat<-as.integer(sum(out$antal_mandat));out
}

.re_present <- function(raw,e,table,detail,language,file) {
  if(table=="results") {
    raw <- .komplettera_kommunnamn_2026(raw,raw$kommunnamn)
    if(any(raw$geografiniva=="valdistrikt")) raw$raknat <- rep(TRUE,nrow(raw))
    raw <- .valresultat_public_andelar_2026(raw)
    raw <- raw[.valresultat_public_columns_2026(unique(raw$geografiniva))]
  }
  if(table=="seats" && "valomradessparr_procent" %in% names(raw)) raw <- .mandat_public_2026(raw,e$election_year)
  if(table=="seats" && !"antal_tomma_stolar" %in% names(raw)) raw$antal_tomma_stolar <- rep(NA_integer_,nrow(raw))
  out <- .public_output_names(.public_detail(raw,table,detail,e$election_code),language)
  if(table=="seats") .re_verify_allocation(.public_output_names(.public_detail(raw,table,"standard",e$election_code),"en"),e)
  out <- .re_provenance(out,e,file,language)
  .public_output(if(language == "sv") out else .canonical_names_sv(out), language)
}

.re_provenance <- function(out,e,file,language) {
  values <- list(election_event=e$election_event,election_date=e$election_date,election_kind='re_election',
    original_election_event=e$original_election_event,mandate_period=e$mandate_period,
    event_scope_level=e$scope_level,event_scope_code=e$scope_code,event_scope_name=e$scope_name,
    source_file=file$path,source_sha256=file$sha256,source_url=e$source_url,
    protocol_reference=e$protocol_reference,electoral_roll_reference_date=e$electoral_roll_reference_date)
  sv <- c(election_event='valtillfalle',election_date='valdatum',election_kind='valklass',
    original_election_event='ursprungligt_valtillfalle',mandate_period='mandatperiod',
    event_scope_level='valhandelse_omfattningsniva',event_scope_code='valhandelse_omfattningskod',event_scope_name='valhandelse_omfattningsnamn',
    source_file='kallfil',source_sha256='kalla_sha256',source_url='kalla_url',protocol_reference='protokollreferens',electoral_roll_reference_date='rostlangd_referensdatum')
  for(n in names(values))out[[if(language=='sv')sv[[n]]else n]]<-rep(values[[n]],nrow(out))
  out
}

.re_dispatch <- function(table,year,year_missing,election,count,level,source,data_dir,
                         update,archive,progress,from,to,names,detail,kind) {
  language <- .english_output_language(names);detail<-.check_detail(detail)
  codes<-.re_codes(election);reg<-.re_elections();reg<-reg[reg$election_code %in% codes,]
  ordinary_years<-sort(unique(unlist(lapply(codes,function(v).stodd_valar(if(table=='seats')'mandat'else'valresultat',v)))))
  available<-sort(unique(c(if(kind=='all')ordinary_years,reg$election_year)))
  years<-.re_years(year,year_missing,from,to,available)
  if(!length(years)||any(!years %in% available))stop('No matching election events; use `election_events()`.',call.=FALSE)
  re<-reg[reg$election_year %in% years,]
  pieces<-list()
  if(kind=='all') {
    yy<-years[years %in% ordinary_years]
    if(length(yy))pieces[[1]]<-do.call(if(table=='seats')seats else results,list(year=yy,election=election,count=count,level=level,source=source,data_dir=.re_ordinary_dir(data_dir),update=update,archive=archive,progress=progress,names=names,detail=detail))
    if(length(pieces)) pieces[[1]] <- .re_label_ordinary(pieces[[1]],language)
  }
  if(nrow(re)) {
    src<-match.arg(source,c('auto','local','remote','canonical'))
    if(src == 'remote')stop('Re-election remote source is not available; use preserved local sources.',call.=FALSE)
    if(update||archive)stop('Preserved re-election sources are immutable; update/archive are not supported.',call.=FALSE)
    if(!identical(count,'final'))stop('Re-election preliminary readers are not yet verified; final sources will not replace them.',call.=FALSE)
    if(table=='results'&&length(codes)!=1L)stop('Select one election type for re-election results.',call.=FALSE)
    for(i in seq_len(nrow(re))) {
      e<-re[i,];lev<-if(is.null(level))if(e$scope_level=='region')'region'else if(e$scope_level=='municipal_constituency')'municipal_constituency'else'municipality' else level
      for(l in lev) {
        niva<-.english_argument_value(l,'level')
        selected <- .select_public_source(src, e$election_year, table, data_dir,
          event_kind='re_election', val=e$election_code, niva=niva)
        if (selected %in% c('canonical', 'canonical_auto')) {
          if (selected == 'canonical' && !is.null(data_dir)) stop('Canonical requests do not accept raw data_dir.',call.=FALSE)
          pieces[[length(pieces)+1L]] <- .re_canonical_read(e, table, niva, detail, language,
            auto_selected=identical(selected,'canonical_auto'))
          next
        }
        .auto_requires_local(selected, 're-election results')
        f<-.re_file(e,data_dir,if(table=='seats')'seats'else'final')
        raw<-if(!is.na(e$comparison_stem)).re_2011(e,f$path,table,niva)else .re_xml(e,f$path,table,niva)
        if(table=='seats'&&sum(raw$antal_mandat)!=e$seats_expected)stop('Re-election party allocations do not match verified seats.',call.=FALSE)
        pieces[[length(pieces)+1L]]<-.re_present(raw,e,table,detail,language,f)
      }
    }
  }
  if(!length(pieces))stop('No matching election events.',call.=FALSE)
  dplyr::bind_rows(pieces)
}

.re_ordinary_dir <- function(data_dir) {
  if(!is.null(data_dir)&&dir.exists(file.path(data_dir,'rkl')))file.path(data_dir,'rkl')else data_dir
}

.re_verify_allocation <- function(x,e) {
  expected <- e$verified_allocation[[1]]
  actual <- tapply(x$seats,x$party_abbreviation,sum)
  actual <- actual[actual>0L]; expected <- expected[expected>0L]
  if(!setequal(names(actual),names(expected)) || any(actual[names(expected)]!=expected))
    stop('Party-level allocation differs from verified final controls for ',e$election_event,call.=FALSE)
  invisible(TRUE)
}

.re_component <- function(x,event,year) {
  x$component_election_event <- rep(event,nrow(x))
  x$component_election_year <- rep(as.integer(year),nrow(x))
  get <- function(n) if(n %in% names(x)) x[[n]] else rep(NA_character_,nrow(x))
  mc <- get("municipal_constituency_code"); co <- get("constituency_code")
  x$component_geographic_level <- ifelse(!is.na(mc),"municipal_constituency",ifelse(!is.na(co),"constituency",ifelse(x$election_code=="RF","region",ifelse(x$election_code=="RD","national","municipality"))))
  x$component_geographic_code <- mc
  x$component_geographic_code[x$election_code=="RD" & is.na(x$component_geographic_code)] <- "00"
  for(n in c("constituency_code","municipality_code","region_code","electoral_area_code")) {
    ii <- is.na(x$component_geographic_code); x$component_geographic_code[ii] <- get(n)[ii]
  }
  x
}

.re_after_seats <- function(year,year_missing,election,count,level,source,data_dir,
                            update,archive,progress,from,to,names,detail,kind) {
  if(kind!='ordinary')stop('`after_re_election = TRUE` requires `election_kind = "ordinary"`; year refers to the original election.',call.=FALSE)
  if(count!='final')stop('Post-re-election compositions require final allocations.',call.=FALSE)
  language<-.english_output_language(names);detail<-.check_detail(detail);codes<-.re_codes(election)
  available<-sort(unique(unlist(lapply(codes,function(v).stodd_valar('mandat',v)))))
  years<-.re_years(year,year_missing,from,to,available)
  if(!length(years)||any(!years %in% available))stop('No supported original ordinary election selected.',call.=FALSE)
  if(any(!codes %in% c('RD','RF','KF')))stop('Post-re-election compositions currently support RD/RF/KF only.',call.=FALSE)
  reg<-.re_elections();out<-list()
  for(y in years)for(v in codes) {
    lev<-if(is.null(level))switch(v,KF='municipality',RF='region',RD='national')else level
    if(length(lev)!=1L || !lev %in% switch(v,KF='municipality',RF='region',RD='national'))
      stop('Post-re-election composition requires one whole-area mandate level: municipality, region or national.',call.=FALSE)
    args<-list(year=y,election=v,count='final',level=lev,source=source,data_dir=.re_ordinary_dir(data_dir),update=update,archive=archive,progress=progress,names='en',detail=detail)
    original<-do.call(seats,args)
    dates<-election_events(y,v,'ordinary');base_event<-dates$election_event[[1]]
    original<-.re_component(original,base_event,y)
    events<-reg[reg$original_year==y & reg$election_code==v,]
    events<-events[order(events$election_date,events$election_event),]
    # Sequential replacement supports multiple disjoint events and later replacements.
    for(i in seq_len(nrow(events))) {
      e<-events[i,];area<-if(v=='KF')'municipality_code'else'region_code'
      code<-if(e$scope_level=='municipal_constituency')substr(e$scope_code,1,4)else e$scope_code
      affected<-original[[area]]==code;affected[is.na(affected)]<-FALSE
      if(!any(affected))stop('Original allocation component is missing for ',e$election_event,call.=FALSE)
      replacement<-seats(year=e$election_year,election=v,election_kind='re_election',level=lev,
        source=source,data_dir=data_dir,progress=progress,names='en',detail=detail)
      replacement<-replacement[replacement$election_event==e$election_event,]
      .re_verify_allocation(replacement,e)
      replacement<-.re_component(replacement,e$election_event,e$election_year)
      if(e$scope_level=='municipal_constituency') {
        # Obtain legally allocated original constituency seats; never reallocate combined votes.
        if(all(original$component_geographic_level[affected]=="municipal_constituency")) {
          parts <- original[affected,]
        } else {
          if(any(original$component_election_event[affected]!=base_event)) stop("Verified constituency components for the preceding replacement are unavailable.",call.=FALSE)
          aa<-args;aa$level<-"municipal_constituency";parts<-do.call(seats,aa)
          parts<-parts[parts$municipality_code==code,]
          parts<-.re_component(parts,base_event,y)
        }
        if(!nrow(parts)||anyNA(parts$municipal_constituency_code))stop('Missing verified original constituency components.',call.=FALSE)
        old<-parts[parts$municipal_constituency_code==e$scope_code,]
        if(!nrow(old)||sum(old$seats)!=e$seats_expected)stop('Original annulled seat component is incomplete.',call.=FALSE)
        # Published 2011 comparison values independently verify the original party allocation.
        cmp<-seats(year=e$election_year,election=v,election_kind='re_election',level=lev,
          source=source,data_dir=data_dir,names='en',detail='full',progress=FALSE)
        old_by<-tapply(old$seats,old$party_abbreviation,sum)
        if(anyNA(match(cmp$party_abbreviation,names(old_by))) || any(old_by[cmp$party_abbreviation]!=cmp$previous_seats))
          stop('Original constituency allocation disagrees with the official re-election comparison.',call.=FALSE)
        kept<-parts[parts$municipal_constituency_code!=e$scope_code,]
        kept$geographic_level<-'municipality'
        if(sum(kept$seats)+sum(replacement$seats)!=sum(original$seats[affected]))
          stop('Replacement does not preserve the verified council size.',call.=FALSE)
        replacement<-dplyr::bind_rows(kept,replacement)
      }
      original<-dplyr::bind_rows(original[!affected,],replacement)
    }
    original$election_year<-rep(as.integer(y),nrow(original));original$election_event<-rep(base_event,nrow(original))
    original$election_date<-rep(dates$election_date[[1]],nrow(original));original$election_kind<-'ordinary'
    original$composition_type<-'after_re_election';original$composition_id<-paste0(base_event,'-after-re-elections')
    original$mandate_period<-paste(v,y,y+4L,sep='-')
    # Recompute repeated area totals from components, not a seat-allocation algorithm.
    area<-switch(v,KF='municipality_code',RF='region_code',RD='electoral_area_code')
    if(!area%in%names(original))original[[area]]<-'00'
    totals<-tapply(original$seats,original[[area]],sum)
    original$total_seats<-as.integer(totals[original[[area]]])
    out[[length(out)+1L]]<-original
  }
  out<-dplyr::bind_rows(out)
  out <- .values_present(out, language)
  if(language=='sv')out<-.canonical_names_sv(out)
  out
}



.re_label_ordinary <- function(x,language) {
  yn<-if(language=='sv')'valar'else'election_year';cn<-if(language=='sv')'valtyp'else'election_code'
  registry<-election_events(election_kind='ordinary')
  k<-match(paste(x[[yn]],x[[cn]]),paste(registry$election_year,registry$election_code))
  if(anyNA(k))stop('Ordinary event metadata missing from registry.',call.=FALSE)
  columns<-c(election_event='valtillfalle',election_date='valdatum',election_kind='valklass',mandate_period='mandatperiod')
  for(n in names(columns))x[[if(language=='sv')columns[[n]]else n]]<-registry[[n]][k]
  .public_output(if(language == "sv") x else .canonical_names_sv(x), language)
}

.swedish_election_kind <- function(x) {
  values<-c(ordinarie='ordinary',omval='re_election',alla='all',ordinary='ordinary',re_election='re_election',all='all')
  if(!is.character(x)||length(x)!=1L||is.na(x)||!x %in% names(values))stop('Unknown election kind / valklass.',call.=FALSE)
  unname(values[x])
}

.re_ballot_totals <- function(x,node,year) {
  if(year==2003L) {
    # The 2002-family XML reports OG as combined invalid, not other-invalid.
    og<-xml2::xml_find_first(node,'./OGILTIGA[@TEXT="OG"]')
    x$ogiltiga_roster<-rep(.xml2018_int(og,'R\u00d6STER'),nrow(x))
    x$ovriga_ogiltiga[]<-NA_integer_
    x$ovriga_ogiltiga_fg[]<-NA_integer_
    x$diff_ovriga_ogiltiga[]<-NA_integer_
  } else {
    invalid<-x$blanka_roster+x$ovriga_ogiltiga
    if(year>=2018L)invalid<-invalid+x$roster_ej_anmalt_deltagande
    known<-!is.na(invalid)
    if(any(known&!is.na(x$ogiltiga_roster)&invalid!=x$ogiltiga_roster,na.rm=TRUE))
      stop('Invalid-ballot components disagree with source totals.',call.=FALSE)
    x$ogiltiga_roster[known]<-invalid[known]
  }
  expected<-x$giltiga_roster+x$ogiltiga_roster
  if(any(!is.na(expected)&!is.na(x$totalt_antal_roster)&expected!=x$totalt_antal_roster,na.rm=TRUE))
    stop('Source ballot accounting disagrees with valid plus invalid votes.',call.=FALSE)
  missing<-is.na(x$totalt_antal_roster)
  x$totalt_antal_roster[missing]<-expected[missing]
  x
}

.re_party_metadata_2011 <- function(x) {
  file<-system.file('extdata','re-election-party-identifiers-2011.csv',package='swelections')
  lookup<-readr::read_csv(file,col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
  k<-match(x$partiforkortning,lookup$party_abbreviation)
  for(pair in list(c('partikod','party_code'),c('partibeteckning','party_designation'))) {
    fill<-is.na(x[[pair[1]]])&!is.na(k)
    x[[pair[1]]][fill]<-lookup[[pair[2]]][k[fill]]
  }
  x
}
