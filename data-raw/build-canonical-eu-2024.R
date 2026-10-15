# R-only unpublished EU 2024 canonical prototype.
# Rscript data-raw/build-canonical-eu-2024.R RAW_ROOT EMPTY_OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop('Specify RAW_ROOT EMPTY_OUTPUT_DIR.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('nanoparquet', quietly = TRUE)) stop('Install optional nanoparquet for builds.')
out <- args[[2]]
if (dir.exists(out) && length(list.files(out, all.files=TRUE, no..=TRUE))) stop('Use an empty output directory.')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
assets <- tables <- list()
save_asset <- function(parts, asset) {
  if (is.data.frame(parts)) x <- swelections:::.canonical_names_en(parts) else {
    tables[[length(tables)+1L]] <<- data.frame(asset=asset, table=names(parts),
      columns=vapply(parts, function(d) paste(names(swelections:::.canonical_names_en(d)), collapse=','), ''))
    x <- purrr::list_rbind(lapply(names(parts), function(n) {
      d <- swelections:::.canonical_names_en(parts[[n]]); d$.table <- rep(n,nrow(d)); d
    }))
  }
  x[] <- lapply(x, unname)
  f <- file.path(out,paste0(asset,'.parquet'))
  nanoparquet::write_parquet(x,f,compression='gzip')
  stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(f))))
  assets[[length(assets)+1L]] <<- data.frame(asset=asset,file=basename(f),rows=nrow(x),
    bytes=unname(file.info(f)$size),sha256=swelections:::.canonical_sha256(f))
  cat('PASS Parquet',asset,nrow(x),'\n');flush.console()
}
files <- c(final=swelections:::.eu2024_file('results','local',args[[1]],'slutlig'),
 preliminary=swelections:::.eu2024_file('results','local',args[[1]],'preliminar'),
 candidacies=swelections:::.eu2024_file('candidacies','local',args[[1]]))
sources <- data.frame(role=names(files),file=basename(files),bytes=unname(file.info(files)$size),
 md5=unname(tools::md5sum(files)),sha256=unname(tools::sha256sum(files)))
sources$url <- c('https://resultat.val.se/resultatfiler/euval2024/s/e/EU-val_2024_slutlig_00_E.zip',
 'https://resultat.val.se/resultatfiler/euval2024/p/e/EU-val_2024_preliminar_00_E.zip',
 'https://data.val.se/filer/euval2024/parti/kandidaturer.zip')
for (stage in c('final','preliminary')) {
 parts <- stats::setNames(lapply(swelections:::.eu2024_levels,function(l)
   results(2024,election='european',level=names(swelections:::.english_argument_values$level)[match(l,swelections:::.english_argument_values$level)],
    count=stage,source='local',data_dir=args[[1]],names='sv',detail='full')),swelections:::.eu2024_levels)
 save_asset(parts,paste0('eu2024-results-',stage))
 save_asset(list(riket=seats(2024,election='european',count=stage,source='local',data_dir=args[[1]],names='sv',detail='full')),paste0('eu2024-seats-',stage))
}
for (fun in c('candidacies','candidates','elected','substitutes'))
 save_asset(do.call(get(fun),list(year=2024,election='european',source='local',data_dir=args[[1]],names='sv',detail='full')),paste0('eu2024-',fun))
save_asset(candidates(2024,election='european',include_results=FALSE,source='local',data_dir=args[[1]],names='sv',detail='full'),'eu2024-candidate-base')
m <- swelections:::.eu2024_raw(files[['final']],'mandatfordelning')
short <- c(personvalsomrade='area',riket='national',lan='county',kommun='municipality',kommunvalkrets='municipal-constituency',valdistrikt='district')
for (level in names(short)) {
 raw <- if (level %in% c('riket','personvalsomrade')) m else swelections:::.eu2024_raw(files[['final']],if(level=='valdistrikt')'rostfordelning' else 'summering')
 b <- swelections:::.eu2024_preference_base(raw,level)
 b$votes <- b$votes[c('.geo','partikod','listnummer','kandidatnummer','antal_personroster','kandidatnamn_lista')]
 names(b$votes)[names(b$votes)=='kandidatnamn_lista'] <- 'kandidatnamn_raw'
 b$lists <- b$lists[c('.geo','partikod','listnummer','antal_listroster')]
 b$qualified <- purrr::list_rbind(lapply(m$valomrade$kvalificeradeForPersonvalLista,function(q)
   tibble::tibble(partikod=q$partikod,kandidatnummer=as.character(q$kandidatnummer))))
 for (n in names(b)) {
   names(b[[n]])[names(b[[n]]) == '.geo'] <- 'kall_enhetskod'
   names(b[[n]])[names(b[[n]]) == 'listnummer'] <- 'listnummer_raw'
 }
 save_asset(b,paste0('eu2024-preference-base-',short[[level]]))
}
stopifnot(identical(unname(tools::sha256sum(files)),sources$sha256))
manifest <- list(data_version='data-v0.0.0',schema_version=2L,format='parquet',valserie='eu',valar=2024L,
 release_status='unpublished_local_validation_build',auto_eligible=FALSE,
 built_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
 build_commit=trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE)),
 build_tree_dirty=length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L,
 sources=sources,assets=purrr::list_rbind(assets),tables=purrr::list_rbind(tables),
 source_selection=list(candidate_population='Approved later June/December official snapshot. Candidate 1203 is preserved only in historical provenance and excluded from final population.',
 historical_candidate=list(id='1203',party='1659',source_status='Valid consent-only row on 9 June; absent in later files; reason unestablished; no identified preference/elected/substitute record',
  archive_url='https://web.archive.org/web/20240610133822id_/https://data.val.se/filer/euval2024/parti/kandidaturer.zip',
  zip_sha256='e408dbdf9b96b1b075b1463d707e11854e415524f1ec88cdf9fbd187ac27b2db',
  csv_sha256='c47cd8e967c4dbc72d3fd7293aea1199c103c005729eb1c3cd64a456768c5375'),
 preliminary='13 June full preliminary snapshot, including collection units; not the earlier 11 June spreadsheet',
 electorate='Collection units have no independent electorate/turnout; SCB demographic breakdown remains validation material',
 seats='Fixed original election relations; 2019 comparison uses post-Brexit allocation'))
jsonlite::write_json(manifest,file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
cat('PASS EU prototype build:',length(assets),'assets\n')
