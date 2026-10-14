# Rebuild the affected RD result asset without reprocessing unchanged assets.
# Rscript development/rebuild_complement_2002.R RAW_ROOT REFERENCE_DIR OUTPUT_DIR
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=3L) stop('Specify RAW_ROOT REFERENCE_DIR OUTPUT_DIR.')
pkgload::load_all('.',quiet=TRUE)
s <- swelections:::.sources_2002('local',args[1]); reference <- args[2]; output <- args[3]
if(dir.exists(output)&&length(list.files(output))) stop('Use an empty output directory.')
dir.create(output,recursive=TRUE,showWarnings=FALSE)
m <- jsonlite::read_json(file.path(reference,'manifest.json'),simplifyVector=TRUE)
stopifnot(m$valar==2002L,m$schema_version==2L)
sha <- swelections:::.canonical_sha256
for(i in seq_len(nrow(m$assets))) {
 a <- m$assets[i,]; file <- file.path(reference,a$file)
 stopifnot(file.info(file)$size==a$bytes,sha(file)==a$sha256)
 if(a$asset!='rkl2002-results-slutlig-rd') stopifnot(file.copy(file,output))
}
parts <- lapply(c('valdistrikt','kommun','kommunvalkrets','lan','riksdagsvalkrets','riket'),function(level) {
 x <- swelections:::.valresultat_2002(s,'RD',level,'slutlig');cat('PASS RD raw',level,nrow(x),'\n');flush.console();x
})
names(parts) <- c('valdistrikt','kommun','kommunvalkrets','lan','riksdagsvalkrets','riket')
# Previously available aggregate views must remain exactly identical.
old <- tibble::as_tibble(nanoparquet::read_parquet(file.path(reference,'rkl2002-results-slutlig-rd.parquet')))
for(level in intersect(names(parts),m$tables$table[m$tables$asset=='rkl2002-results-slutlig-rd'])) {
 cols <- strsplit(m$tables$columns[m$tables$asset=='rkl2002-results-slutlig-rd'&m$tables$table==level],',',fixed=TRUE)[[1]]
 stopifnot(identical(swelections:::.canonical_names_en(parts[[level]]),old[old$.table==level,cols]))
}
asset <- 'rkl2002-results-slutlig-rd'
layouts <- lapply(parts,function(x)names(swelections:::.canonical_names_en(x)))
tables <- data.frame(asset=asset,table=names(parts),columns=vapply(layouts,paste,'',collapse=','))
x <- purrr::list_rbind(lapply(names(parts),function(level){z <- swelections:::.canonical_names_en(parts[[level]]);z$.table <- level;z}))
x[] <- lapply(x,unname)
file <- file.path(output,paste0(asset,'.parquet'));nanoparquet::write_parquet(x,file,compression='gzip')
stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(file))))
j <- match(asset,m$assets$asset);m$assets$rows[j] <- nrow(x);m$assets$bytes[j] <- file.info(file)$size;m$assets$sha256[j] <- sha(file)
m$tables <- rbind(tables,m$tables[m$tables$asset!=asset,])
m$unavailable_views <- m$unavailable_views[!startsWith(m$unavailable_views$view,'results RD'), ,drop=FALSE]
m$complementary_results <- lapply(get('rd-complement-2002',s$cache),function(x)x$provenance)
m$source_selection$final <- 'Valmyndigheten XML is primary; three missing RD municipal exports are complemented by independently reconciled SCB/SND votes.'
m$incremental_reference <- list(manifest_sha256=sha(file.path(reference,'manifest.json')),unchanged_assets=12L,
 description='Twelve checksum-verified reference assets copied unchanged; affected RD results rebuilt from raw sources.')
m$build_commit <- trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE))
m$build_tree_dirty <- length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L
m$built_at_utc <- format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC')
jsonlite::write_json(m,file.path(output,'manifest.json'),pretty=TRUE,auto_unbox=TRUE,na='null')
for(f in s$sources$export) swelections:::.xml2002_source(s,f)
cat('PASS affected-asset rebuild, all aggregate views unchanged, twelve assets byte-identical, English Parquet round trip\n')
