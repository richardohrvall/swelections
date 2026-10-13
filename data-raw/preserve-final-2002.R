# R-only preservation of the final 2002 XML exports. Never acquire preliminary
# sources here, overwrite a preserved object, or use the Orsa rerun.
# Rscript data-raw/preserve-final-2002.R RAW_ROOT [RD,RF,KF]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) stop('Specify RAW_ROOT and optional comma-separated election codes.')
pkgload::load_all('.', quiet = TRUE)
values <- if (length(args) == 2L) strsplit(args[[2]], ',', fixed = TRUE)[[1]] else c('RD','RF','KF')
stopifnot(all(values %in% c('RD','RF','KF')))
root <- file.path(args[[1]], '2002')
snapshot <- file.path(root, 'implementation-sources-20261012')
dir.create(file.path(snapshot,'objects'), recursive=TRUE, showWarnings=FALSE)
mp <- file.path(snapshot,'source-manifest.json')
records <- if (file.exists(mp)) jsonlite::read_json(mp) else list()
sha <- swelections:::.canonical_sha256
if (!requireNamespace('curl', quietly=TRUE)) stop('Install curl for the archive acquisition tool; it is not a package runtime dependency.')
last_effective_url <- NULL
archive_download <- function(url, destfile, mode='wb', quiet=TRUE) {
  h <- curl::new_handle(timeout=180,connecttimeout=12,followlocation=TRUE,
    failonerror=TRUE,useragent='swelections historical final-source preservation')
  response <- curl::curl_fetch_disk(url,destfile,handle=h)
  if(response$status_code!=200L) stop('HTTP ',response$status_code,': ',url)
  last_effective_url <<- response$url
  0L
}
get <- function(url, prefix, validate = NULL) {
  old <- records[[url]]
  if (!is.null(old) && old$status %in% c(400L,401L,403L,404L,410L))
    stop('Previously failed archive replay: ', url, ': ', old$error)
  if (!is.null(old) && old$status == 200L && length(old$file)) {
    stopifnot(file.exists(old$file), file.info(old$file)$size == old$bytes,
      unname(tools::md5sum(old$file)) == old$md5, sha(old$file) == old$sha256)
    if (!is.null(validate)) validate(old$file)
    return(old$file)
  }
  # The URL hash only names the local object; content hashes verify its bytes.
  keyfile <- tempfile(); writeLines(url,keyfile); key <- substr(sha(keyfile),1L,12L); unlink(keyfile)
  suffix <- if (endsWith(url,'.xml')) '.xml' else '.json'
  target <- file.path(snapshot,'objects',paste0(prefix,'-',key,suffix))
  if (file.exists(target)) stop('Unregistered existing object: ',target)
  stage <- tempfile(tmpdir=snapshot,fileext=suffix)
  on.exit(unlink(stage), add = TRUE)
  downloaded <- tryCatch(swelections:::.download_file(url,stage,timeout=180L,
    attempts=3L,.download=archive_download),error=identity)
  if (inherits(downloaded,'error')) {
    message <- conditionMessage(downloaded)
    code <- if (grepl('returned error: 404',message,fixed=TRUE)) 404L else 0L
    records[[url]] <<- list(url=url,status=code,error=message,
      retrieved_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'))
    jsonlite::write_json(records,mp,pretty=TRUE,auto_unbox=TRUE)
    stop(downloaded)
  }
  if (!is.null(validate)) validate(stage)
  stopifnot(file.rename(stage,target))
  records[[url]] <<- list(url=url,effective_url=last_effective_url,status=200L,
    retrieved_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
    bytes=unname(file.info(target)$size),file=target,md5=unname(tools::md5sum(target)),sha256=sha(target))
  jsonlite::write_json(records,mp,pretty=TRUE,auto_unbox=TRUE)
  Sys.sleep(2)
  target
}
# Prefer pre-rerun captures, then the earliest indexed remaining final exports.
query <- function(last) paste0('https://web.archive.org/cdx/search/cdx?url=www.val.se%2Fval%2Fval_02%2Fsenaste%2F&matchType=prefix&filter=original%3A.*slutresultat.*&output=json&filter=statuscode%3A200&from=20020915&to=',last,'&collapse=urlkey&limit=1500')
indexes <- lapply(c('20030315','20081231'), function(last) {
  x <- jsonlite::fromJSON(get(query(last),'official-final-index'))
  if (!is.matrix(x) || nrow(x)<2L || nrow(x)>=1501L) stop('Missing/truncated final source index.')
  x[-1,,drop=FALSE]
})
x <- rbind(indexes[[1]],indexes[[2]])
x <- x[!duplicated(basename(x[,3])),,drop=FALSE]
letter <- c(RD='R',RF='L',KF='K')
recover_exact <- function(file, validate) {
  exact <- paste0('https://web.archive.org/cdx/search/cdx?url=',
    utils::URLencode(paste0('www.val.se/val/val_02/senaste/',file), reserved=TRUE),
    '&output=json&filter=statuscode%3A200&collapse=timestamp%3A4&limit=20')
  alternatives <- tryCatch(jsonlite::fromJSON(get(exact,'final-capture-index')), error=identity)
  result <- simpleError(paste('No recoverable exact final export:',file))
  if (!inherits(alternatives,'error') && is.matrix(alternatives) && nrow(alternatives)>1L) {
    alternatives <- alternatives[-1,,drop=FALSE]
    for (j in seq_len(min(5L,nrow(alternatives)))) {
      alt <- paste0('https://web.archive.org/web/',alternatives[j,2],'id_/',alternatives[j,3])
      result <- tryCatch(get(alt,'final',validate), error=identity)
      if (!inherits(result,'error')) break
    }
  }
  result
}
pattern <- paste0('^slutresultat_(00|[0-9]{4})[',paste(letter[values],collapse=''),'][.]xml$')
x <- x[grepl(pattern,basename(x[,3])),,drop=FALSE]
x <- x[order(basename(x[,3])),,drop=FALSE]
failed <- list()
for(i in seq_len(nrow(x))) {
  file <- basename(x[i,3])
  if (file=='slutresultat_2034K.xml') next
  url <- paste0('https://web.archive.org/web/',x[i,2],'id_/',x[i,3])
  validate <- function(path) {
    doc <- xml2::read_xml(path,options='NONET')
    stopifnot(xml2::xml_attr(doc,'FILNAMN')==file,
      xml2::xml_attr(doc,'TILLFÄLLE')=='Allmänna val 15 September 2002',
      xml2::xml_attr(doc,'RAPPORTERING')=='SLUTLIG SAMMANRÄKNING RESULTAT')
  }
  result <- tryCatch(get(url,'final',validate), error = identity)
  if (inherits(result, 'error')) {
    cat('Unavailable indexed replay', file, conditionMessage(result), '\n'); flush.console()
    # An indexed capture can fail at replay. Try only this exact final export,
    # bounded to a few alternative years; never search preliminary sources.
    result <- recover_exact(file, validate)
    if (inherits(result,'error')) failed[[length(failed)+1L]] <- list(export=file,url=url,error=conditionMessage(result))
  }
  if(i%%10L==0L) {cat('Preserved',i,'/',nrow(x),'\n');flush.console()}
}
# Prefix indexing can omit individual exports. The national source establishes
# the expected municipality population; check only those exact missing files.
for (v in values) {
  national_url <- names(records)[endsWith(names(records),paste0('slutresultat_00',letter[[v]],'.xml'))]
  if (!length(national_url)) next
  doc <- xml2::read_xml(records[[national_url[[1]]]]$file,options='NONET')
  codes <- xml2::xml_attr(xml2::xml_find_all(doc,'./NATION/LÄN/KRETS_RIKSDAG/KOMMUN'),'KOD')
  missing <- setdiff(paste0('slutresultat_',codes,letter[[v]],'.xml'),basename(x[,3]))
  for (file in missing) {
    validate <- function(path) {
      d <- xml2::read_xml(path,options='NONET')
      stopifnot(xml2::xml_attr(d,'FILNAMN')==file,
        xml2::xml_attr(d,'TILLFÄLLE')=='Allmänna val 15 September 2002',
        xml2::xml_attr(d,'RAPPORTERING')=='SLUTLIG SAMMANRÄKNING RESULTAT')
    }
    result <- recover_exact(file,validate)
    if (inherits(result,'error')) failed[[length(failed)+1L]] <- list(export=file,error=conditionMessage(result))
  }
}
# Original Orsa is separately pinned; later captures never substitute for it.
original_manifest <- file.path(root,'orsa-review-20261012/source-manifest.json')
if (file.exists(original_manifest)) {
  original <- jsonlite::read_json(original_manifest)
  orsa <- original[[names(original)[grepl('20030126151028id_',names(original))]]]
} else {
  pinned_url <- paste0('https://web.archive.org/web/20030126151028id_/',
    'http://www.val.se:80/val/val_02/senaste/slutresultat_2034K.xml')
  get(pinned_url,'original-orsa',function(path)
    stopifnot(unname(tools::md5sum(path))=='3249b5428225a4e6d0c77dbcd1d17340'))
  orsa <- records[[pinned_url]]
}
stopifnot(unname(tools::md5sum(orsa$file))=='3249b5428225a4e6d0c77dbcd1d17340')
all <- c(records[names(records) != orsa$url],list(orsa))
entries <- lapply(all,function(r) {
  if(r$status!=200L || !length(r$file) || !endsWith(r$file,'.xml')) return(NULL)
  doc <- xml2::read_xml(r$file,options='NONET')
  file <- xml2::xml_attr(doc,'FILNAMN')
  data.frame(export=file,file=substring(normalizePath(r$file,winslash='/'),nchar(normalizePath(root,winslash='/'))+2L),
    url=r$url,original_url=sub('^https://web.archive.org/web/[0-9]+id_/','',r$url),
    capture=sub('.*web/([0-9]+)id_/.*','\\1',r$url),retrieved_at_utc=r$retrieved_at_utc,
    bytes=r$bytes,md5=r$md5,sha256=r$sha256,report_time=xml2::xml_attr(doc,'TID_RAPPORT'))
})
selection <- dplyr::bind_rows(entries)
stopifnot(!anyDuplicated(selection$export))
jsonlite::write_json(list(valar=2002L,election_date='2002-09-15',
  source_selection='Original final election XML; pinned ordinary Orsa, never the rerun; later capture does not change the source election occasion',
  sources=selection,unrecovered_exports=failed),file.path(root,'final-source-selection.json'),pretty=TRUE,auto_unbox=TRUE)
for(v in values) {
  found <- sum(grepl(paste0('^slutresultat_[0-9]{4}',letter[[v]],'[.]xml$'),selection$export))
  cat(v,'municipal coverage',found,'/',if(v=='RF') 289 else 290,'\n')
}
