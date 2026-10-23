
# Append one shared history asset to a reviewed RKL result prototype.
# Rscript data-raw/build-canonical-mandate-history.R YEAR PARENT_MANIFEST RAW_ROOT OUTPUT
build_canonical_mandate_history <- function(year, parent, root, output) {
  if (!year %in% c(2014L,2018L))
    stop("Only 2014 and 2018 history is approved for canonical; 2022 remains remote.")
  pkgload::load_all(".",quiet=TRUE)
  source("data-raw/canonical-build-contract.R",local=TRUE)
  if(dir.exists(output) && length(list.files(output,all.files=TRUE,no..=TRUE)))
    stop("Use an empty output directory.")
  m<-swelections:::.canonical_manifest(parent)
  stopifnot(m$valserie=="rkl",as.integer(m$valar)==year,
    m$schema_version==3L,m$value_schema_version==1L,m$storage_schema_version==1L)
  asset<-paste0("rkl",year,"-mandate-history")
  inherited <- m[c("data_version","build_commit","build_tree_dirty","built_at_utc")]
  m$assets <- m$assets[m$assets$asset != asset, , drop=FALSE]
  m$tables <- m$tables[m$tables$asset != asset, , drop=FALSE]
  if(dir.exists(file.path(root,"rkl")))root<-file.path(root,"rkl")
  raw<-swelections:::.mh_files(year,root,list())
  old<-options(swelections.canonical_manifest=parent,
    swelections.canonical_assets_dir=dirname(parent))
  on.exit(options(old),add=TRUE)
  codes<-c("RD","RF","KF")
  original<-swelections:::.mh_original(year,codes,root,"canonical")
  d<-lapply(names(raw),function(k)swelections:::.mh_normalise(raw[[k]],k,year))
  names(d)<-names(raw)
  internal<-swelections:::.mh_build(year,original$allocations,original$elected,
    d$history,d$current,d$departures,d$vacancies)
  x<-swelections:::.mh_present(internal,"en","full")
  inputs<-purrr::list_rbind(lapply(names(raw),function(k) {
    z<-raw[[k]];if(is.null(z))return(NULL)
    p<-attr(z,"source_file")
    data.frame(role=k,file=paste("rkl",year,"kandidater",basename(p),sep="/"),
      source_snapshot=as.character(attr(z,"source_as_of")),rows=nrow(z),
      bytes=unname(file.info(p)$size),md5=attr(z,"source_md5"),
      sha256=swelections:::.canonical_sha256(p),original_path=p)
  }))
  for(i in seq_len(nrow(inputs)))
    x$source_file[x$source_file%in%inputs$original_path[i]]<-inputs$file[i]
  if(any(grepl("^[A-Za-z]:[/\\\\]|^[/\\\\]{2}",x$source_file)))
    stop("Unmapped machine path in history provenance.")
  inputs$original_path<-NULL
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  for(i in seq_len(nrow(m$assets))) {
    p<-file.path(dirname(parent),m$assets$file[i]);q<-file.path(output,m$assets$file[i])
    stopifnot(swelections:::.canonical_sha256(p)==m$assets$sha256[i],
      file.copy(p,q),swelections:::.canonical_sha256(q)==m$assets$sha256[i])
  }
  p<-file.path(output,paste0(asset,".parquet"))
  nanoparquet::write_parquet(x,p,compression="gzip")
  stopifnot(identical(x,tibble::as_tibble(nanoparquet::read_parquet(p))))
  m$assets<-dplyr::bind_rows(m$assets,data.frame(asset=asset,file=basename(p),
    role="mandate_history",rows=nrow(x),bytes=unname(file.info(p)$size),
    sha256=swelections:::.canonical_sha256(p)))
  m$tables<-dplyr::bind_rows(m$tables,data.frame(asset=asset,table="intervals",
    columns=paste(names(x),collapse=",")))
  first<-swelections:::.mh_at(x,min(x$event_date))
  last<-swelections:::.mh_at(x,min(x$coverage_end))
  m$mandate_history<-list(interval_schema_version=2L,original_year=year,coverage_start=as.character(min(x$event_date)),
    coverage_end=as.character(min(x$coverage_end)),intervals=nrow(x),
    active_chairs=nrow(first),initial_vacancies=sum(first$status=="vacant"),
    final_occupied=sum(last$status=="occupied"),final_vacant=sum(last$status=="vacant"),
    original_result_manifest_sha256=swelections:::.canonical_sha256(parent),inputs=inputs)
  component<-canonical_build_contract(list())
  m <- canonical_build_contract(m)
  m$inherited_build <- inherited
  m$component_builds$mandate_history<-component
  m$build_tree_dirty<-isTRUE(m$build_tree_dirty)||isTRUE(component$build_tree_dirty)
  jsonlite::write_json(m,file.path(output,"manifest.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
  swelections:::.canonical_manifest(file.path(output,"manifest.json"))
  cat("PASS",year,nrow(x),"history intervals; all parent assets unchanged; dirty=",
    m$build_tree_dirty,"\n")
  invisible(file.path(output,"manifest.json"))
}
if(sys.nframe()==0L) {
  args<-commandArgs(TRUE)
  if(length(args)!=4L)stop("Specify YEAR PARENT_MANIFEST RAW_ROOT OUTPUT.")
  build_canonical_mandate_history(as.integer(args[1]),args[2],args[3],args[4])
}
