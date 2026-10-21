# Re-encode verified canonical inputs without reparsing or replacing raw sources.
# Rscript data-raw/standardize-canonical-values.R INPUT_MANIFEST EMPTY_OUTPUT_DIR
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=2L)stop('Specify INPUT_MANIFEST EMPTY_OUTPUT_DIR.')
pkgload::load_all('.',quiet=TRUE)
source('data-raw/canonical-build-contract.R')
input<-normalizePath(args[1],winslash='/',mustWork=TRUE);out<-args[2]
if(dir.exists(out)&&length(list.files(out,all.files=TRUE,no..=TRUE)))stop('Use an empty output directory.')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
m<-jsonlite::read_json(input,simplifyVector=TRUE)
stopifnot(m$format=='parquet',m$schema_version==2L)
if(m$valserie=='rkl'&&m$valar==2018L&&is.null(m$corrections$ragunda_2018))
 stop('Use the reviewed Ragunda-corrected 2018 prototype, not the old published generation.')
original<-m;tables<-m$tables;entries<-m$assets
for(i in seq_len(nrow(entries))){
 f<-file.path(dirname(input),entries$file[i]);stopifnot(file.info(f)$size==entries$bytes[i],
   swelections:::.canonical_sha256(f)==entries$sha256[i])
 x<-tibble::as_tibble(nanoparquet::read_parquet(f))
 y<-swelections:::.canonical_encode(swelections:::.canonical_names_sv(x))
 stopifnot(nrow(x)==nrow(y))
 rows<-which(tables$asset==entries$asset[i])
 for(j in rows){
  columns<-strsplit(tables$columns[j],',',fixed=TRUE)[[1]]
  prototype<-swelections:::.canonical_encode(swelections:::.canonical_names_sv(x[0,columns,drop=FALSE]))
  tables$columns[j]<-paste(names(prototype),collapse=',')
  tables$table[j]<-swelections:::.canonical_storage_key(tables$table[j])
 }
 y[]<-lapply(y,unname)
 target<-file.path(out,entries$file[i]);nanoparquet::write_parquet(y,target,compression='gzip')
 stopifnot(identical(y,tibble::as_tibble(nanoparquet::read_parquet(target))))
 entries$bytes[i]<-unname(file.info(target)$size);entries$sha256[i]<-swelections:::.canonical_sha256(target)
 if('columns'%in%names(entries))entries$columns[i]<-ncol(y)
 cat('PASS encode / Parquet round trip',entries$asset[i],nrow(y),'rows\n');flush.console()
}
stopifnot(!anyDuplicated(tables[c('asset','table')]))
m$assets<-entries;m$tables<-tables
m$previous_build<-original[intersect(c('data_version','schema_version','built_at_utc','build_commit','build_tree_dirty','build_code_sha256'),names(original))]
m$derived_from<-list(method='verified canonical re-encoding; no election-value recalculation',
 manifest_sha256=swelections:::.canonical_sha256(input),manifest_file=basename(input),assets=original$assets)
m<-canonical_build_contract(m)
jsonlite::write_json(m,file.path(out,'manifest.json'),auto_unbox=TRUE,pretty=TRUE,na='null')
stopifnot(identical(m$auto_eligible,original$auto_eligible))
cat('PASS standardized contract:',m$valserie,m$valar,nrow(entries),'assets; dirty =',m$build_tree_dirty,'\n')
