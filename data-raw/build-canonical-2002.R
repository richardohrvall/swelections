# Local, unpublished final 2002 prototype. No election-night/preliminary assets.
# Rscript data-raw/build-canonical-2002.R RAW_ROOT OUTPUT_DIR
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=2L) stop('Specify RAW_ROOT OUTPUT_DIR.')
pkgload::load_all('.',quiet=TRUE)
if(!requireNamespace('nanoparquet',quietly=TRUE)) stop('Install nanoparquet for canonical builds.')
s <- swelections:::.sources_2002('local',args[[1]])
out <- args[[2]]
if(dir.exists(out) && length(list.files(out))) stop('Use an empty output directory.')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
sha <- swelections:::.canonical_sha256
for(file in s$sources$export) swelections:::.xml2002_source(s,file)
assets <- tables <- gaps <- list()
save_asset <- function(parts,asset,role,discriminator='.table') {
  if(is.data.frame(parts)) x <- swelections:::.canonical_names_en(parts) else {
    layouts <- lapply(parts,function(x) names(swelections:::.canonical_names_en(x)))
    tables[[length(tables)+1L]] <<- data.frame(asset=asset,table=names(parts),columns=vapply(layouts,paste,'',collapse=','))
    x <- purrr::list_rbind(lapply(names(parts),function(key) {
      data <- swelections:::.canonical_names_en(parts[[key]])
      data[[discriminator]] <- rep(key,nrow(data)); data
    }))
  }
  x[] <- lapply(x,unname)
  stopifnot(!any(vapply(x,is.list,logical(1))))
  file <- file.path(out,paste0(asset,'.parquet'))
  nanoparquet::write_parquet(x,file,compression='gzip')
  restored <- tibble::as_tibble(nanoparquet::read_parquet(file))
  if(!identical(x,restored)) stop('Parquet round trip differs: ',asset)
  assets[[length(assets)+1L]] <<- data.frame(asset=asset,file=basename(file),role=role,rows=nrow(x),bytes=unname(file.info(file)$size),sha256=sha(file))
  cat('PASS round trip',asset,nrow(x),'\n');flush.console()
}
# Skip only demonstrably missing source coverage; never silently skip parser bugs.
missing_view <- function(value,label) {
  if(!inherits(value,'error')) return(value)
  msg <- conditionMessage(value)
  if(!grepl('Incomplete preserved 2002 municipality/district sources|2002 list person-vote records disagree',msg,fixed=FALSE)) stop(value)
  gaps[[length(gaps)+1L]] <<- list(view=label,reason=msg)
  cat('UNAVAILABLE',label,msg,'\n');flush.console();NULL
}
levels <- list(RD=c('valdistrikt','kommun','kommunvalkrets','lan','riksdagsvalkrets','riket'),
 RF=c('valdistrikt','kommun','kommunvalkrets','regionvalkrets','region','riket'),
 KF=c('valdistrikt','kommun','kommunvalkrets','lan','riket'))
seats <- candidates <- base <- elected <- substitutes <- list()
for(v in names(levels)) {
  cat('BUILD',v,'\n');flush.console()
  parts <- lapply(levels[[v]],function(level) missing_view(tryCatch(swelections:::.valresultat_2002(s,v,level,'slutlig'),error=identity),paste('results',v,level)))
  names(parts) <- levels[[v]];parts <- parts[!vapply(parts,is.null,logical(1))]
  save_asset(parts,paste0('rkl2002-results-slutlig-',tolower(v)),'results')
  seats[[v]] <- swelections:::.mandat_2002(s,swelections:::.mandat_par_2026(v,NULL))
  b <- swelections:::.xml2002_population(s,v)
  base[[v]] <- swelections:::.kandidater_2002(s,v,FALSE,bundle=b)
  candidates[[v]] <- swelections:::.kandidater_2002(s,v,TRUE,bundle=b)
  elected[[v]] <- candidates[[v]] |> dplyr::filter(.data$invald %in% TRUE) |>
    swelections:::.valda_invaldsvalkrets_2026() |> dplyr::select(-dplyr::any_of('antal_valkretsar'))
  substitutes[[v]] <- swelections:::.xml2002_public_parties(swelections:::.kort_kommunnamn_2026(b$relations$ersattare))
  for(level in c('personvalsomrade','valdistrikt')) {
    views <- lapply(c(FALSE,TRUE),function(by_list) missing_view(tryCatch(
      if(level=='personvalsomrade'&&!by_list) b$pref else swelections:::.personroster_2002(s,v,level,by_list,FALSE),
      error=identity),paste('preference_votes',v,level,by_list)))
    names(views) <- c('FALSE','TRUE');views <- views[!vapply(views,is.null,logical(1))]
    if(length(views)) save_asset(views,paste0('rkl2002-preference-votes-',if(level=='valdistrikt')'district-'else'area-',tolower(v)),'preference_votes','.person_view')
  }
}
save_asset(seats,'rkl2002-seats-slutlig','seats')
for(surface in c('candidates','base','elected','substitutes'))
  save_asset(purrr::list_rbind(get(surface)),paste0('rkl2002-',if(surface=='base')'candidate-base'else surface),surface)
for(file in s$sources$export) swelections:::.xml2002_source(s,file)
manifest <- list(data_version='data-v0.0.0',schema_version=2L,format='parquet',valserie='rkl',valar=2002L,
 release_status='unpublished_local_validation_build',auto_eligible=FALSE,
 built_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
 build_commit=trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE)),
 build_tree_dirty=length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L,
 supplement=jsonlite::read_json(system.file('extdata','rd-2002-party-supplement-provenance.json',package='swelections')),
 complementary_results=lapply(get0("rd-complement-2002", s$cache, inherits=FALSE), function(x) x$provenance),
 sources=s$sources,assets=purrr::list_rbind(assets),tables=purrr::list_rbind(tables),unavailable_views=gaps,
 source_selection=list(final='Valmyndigheten original-election XML is primary; verified SCB/SND complements only three missing RD municipal exports',
  orsa='Original 15 September 2002 XML MD5 3249b5428225a4e6d0c77dbcd1d17340; March 2003 rerun excluded',
  preliminary='Unrecovered collection snapshot; election night remains provenance, never a complete preliminary result',
  identity='XML source-observation keys, not verified people; no name-based linkage',
  names='Typed missing public names; archival names remain source/provenance only',
  candidacies='Complete ballot-candidacy source unrecovered; no candidacies asset fabricated',
  collection_placement='Final RD/RF collection nodes occur under KOMMUN; KF under KRETS_KOMMUN. Both retained once; never used as preliminary inputs',
  other_party_detail='Official four-party RD supplement: national reported sums and 107 constituency values applied; nine undisclosed cells remain NA inside residual other votes. Counties require complete disclosure; municipality/district detail is not allocated',
  other_party_known_zeros='An explicit RD constituency zero corrects existing contained result observations only; no synthetic lower-level zero rows or positive allocations',
  zeros='Explicit observed zeros only; no unsupported missing-candidate zero completion',
  invalid='Combined OG retained; separate blank/other-invalid categories remain unknown'))
jsonlite::write_json(manifest,file.path(out,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
cat('Finished unpublished 2002 prototype:',out,'\n')
