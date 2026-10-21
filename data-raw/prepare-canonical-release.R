# Source paths are provenance labels, never canonical retrieval locations.
.release_absolute_paths <- function(x) {
  if (is.data.frame(x)) return(c(.release_absolute_paths(rownames(x)), unlist(lapply(x,.release_absolute_paths),use.names=FALSE)))
  if (is.list(x)) return(unlist(lapply(x, .release_absolute_paths), use.names=FALSE))
  if (!is.character(x)) return(character())
  y <- gsub(intToUtf8(92L), '/', x, fixed=TRUE)
  x[!is.na(y) & (grepl('^[A-Za-z]:/', y) | startsWith(y, '//') | grepl('^/(home|Users|tmp|var|mnt)/', y) |
    grepl('^file:', y, ignore.case=TRUE))]
}
.release_portable_provenance <- function(x, project_root) {
  if (is.data.frame(x)) { x[] <- lapply(x, .release_portable_provenance, project_root); rownames(x) <- .release_portable_provenance(rownames(x), project_root); return(x) }
  if (is.list(x)) return(lapply(x, .release_portable_provenance, project_root))
  if (!is.character(x)) return(x)
  roots <- unique(c('C:/git/swelections', 'C:/git/valresultat', project_root))
  for (root in roots) for (prefix in c(paste0(root,'/.local-data/'), paste0(root,'/'))) {
    y <- gsub(intToUtf8(92L), '/', x, fixed=TRUE)
    hit <- !is.na(y) & startsWith(y,prefix)
    x[hit] <- substring(y[hit],nchar(prefix)+1L)
  }
  y <- gsub(intToUtf8(92L), '/', x, fixed=TRUE)
  hit <- !is.na(y) & grepl('^[A-Za-z]:/Users/[^/]+/AppData/Local/Temp/swelections-canonical-2022-[^/]+/official-corrections/',y)
  x[hit] <- paste0('rkl/2022/official-corrections/',basename(y[hit]))
  hit <- !is.na(y) & grepl('^[A-Za-z]:/Users/[^/]+/AppData/Local/Temp/swelections-canonical-2022-[^/]+$',y)
  x[hit] <- 'rkl/2022/preparation-stage'
  x
}

# Prepare the reviewed flat GitHub release; never rebuild or edit election data.
# Rscript data-raw/prepare-canonical-release.R MANIFESTS.csv EMPTY_OUTPUT_DIR [--allow-dirty]
# CSV columns: manifest (one preserved build manifest for each of the 12 products).
prepare_canonical_release <- function(manifests, output, allow_dirty = FALSE) {
  pkgload::load_all('.', quiet = TRUE)
  registry <- swelections:::.canonical_release_registry()
  expected <- c(rkl2002=14L,rkl2006=15L,rkl2010=24L,rkl2014=25L,rkl2018=21L,
    rkl2022=24L,folkomr2003=1L,eu2004=14L,eu2009=8L,eu2014=14L,eu2019=15L,eu2024=15L)
  if (length(manifests) != length(expected) || anyDuplicated(manifests))
    stop('Supply exactly twelve distinct input manifests.')
  if (dir.exists(output) && length(list.files(output, all.files=TRUE, no..=TRUE)))
    stop('Use an empty output directory.')
  specs <- lapply(manifests, function(path) {
    m <- swelections:::.canonical_manifest(path)
    key <- paste0(m$valserie, m$valar)
    if (!key %in% names(expected)) stop('Unapproved release product: ', key)
    e <- swelections:::.canonical_release(as.integer(m$valar), m$valserie)
    if (!isTRUE(e$auto_eligible) || m$data_version != e$data_version ||
        m$schema_version != 3L || m$value_schema_version != 1L ||
        m$storage_schema_version != 1L || !is.logical(m$build_tree_dirty) ||
        length(m$build_tree_dirty) != 1L || is.na(m$build_tree_dirty))
      stop('Unapproved or incompatible manifest: ', path)
    if (!allow_dirty && m$build_tree_dirty)
      stop('Clean canonical builds required; --allow-dirty is for local review staging only.')
    if (key == 'eu2009') {
      # The six source-conflicted preference bases are deliberately not delivered.
      keep <- !grepl('^eu2009-preference-base-', m$assets$asset)
      m$assets <- m$assets[keep, , drop=FALSE]
      m$tables <- m$tables[m$tables$asset %in% m$assets$asset, , drop=FALSE]
    }
    if (nrow(m$assets) != expected[[key]] ||
        !all(m$assets$file == paste0(m$assets$asset, '.parquet')))
      stop('Unexpected asset scope/names for ', key)
    list(key=key, source=path, manifest=m, entry=e)
  })
  keys <- vapply(specs, `[[`, '', 'key')
  if (!setequal(keys, names(expected)) || anyDuplicated(keys))
    stop('The twelve approved products must each occur exactly once.')
  names <- unlist(lapply(specs, function(s)c(s$entry$manifest_file,s$manifest$assets$file)),use.names=FALSE)
  if (length(names)!=202L || anyDuplicated(names) ||
      any(!grepl('^[a-z0-9][a-z0-9_.-]*[.](json|parquet)$', names)))
    stop('Release filenames must be globally unique safe basenames: 190 Parquet + 12 JSON.')
  dir.create(output, recursive=TRUE, showWarnings=FALSE)
  upload <- file.path(output,'upload');dir.create(upload)
  inventory <- list()
  add <- function(kind, product, file, base) {
    inventory[[length(inventory)+1L]] <<- data.frame(kind=kind,product=product,
      file=basename(file),bytes=unname(file.info(file)$size),
      sha256=swelections:::.canonical_sha256(file),url=paste0(base,'/',basename(file)))
  }
  for (s in specs) {
    m <- s$manifest; e <- s$entry
    for (i in seq_len(nrow(m$assets))) {
      a <- m$assets[i,]; input <- file.path(dirname(s$source),a$file)
      if (!file.exists(input) || file.info(input)$size != a$bytes ||
          swelections:::.canonical_sha256(input) != a$sha256)
        stop('Source asset checksum/size mismatch: ', input)
      target <- file.path(upload,a$file)
      if (!file.copy(input,target) || swelections:::.canonical_sha256(target) != a$sha256)
        stop('Cannot stage asset: ', target)
      add('parquet',s$key,target,e$base_url)
    }
    # Preserve original build provenance, including truthful dirty status.
    m$auto_eligible <- TRUE
    m$auto_functions <- e$auto_functions
    m$event_kind <- e$event_kind
    m$release_status <- 'release_candidate_unpublished'
    m$distribution <- list(manifest_file=e$manifest_file,base_url=e$base_url,
      source_manifest_sha256=swelections:::.canonical_sha256(s$source),
      scope=if(s$key=='eu2009') 'Six public functions; all preference-vote bases excluded' else
        'Reviewed public functions and declared geographic/count-stage views')
    # Only non-operational provenance is made portable; assets/tables stay exact.
    m <- .release_portable_provenance(m, getwd())
    m$distribution$source_path_basis <- 'Portable provenance labels; not local runtime requirements'
    m$distribution$source_identity_basis <- 'Source SHA256 and original official URLs'
    if (length(.release_absolute_paths(m)))
      stop('Unmapped absolute local path in distribution metadata: ',
        paste(.release_absolute_paths(m), collapse=', '))
    target <- file.path(upload,e$manifest_file)
    jsonlite::write_json(m,target,pretty=TRUE,auto_unbox=TRUE,na='null')
    swelections:::.canonical_manifest(target)
    add('manifest',s$key,target,e$base_url)
    cat('PASS staged',s$key,nrow(m$assets),'unchanged Parquet assets; dirty=',m$build_tree_dirty,'\n')
  }
  inventory <- do.call(rbind,inventory)
  utils::write.csv(inventory,file.path(output,'upload-inventory.csv'),row.names=FALSE)
  jsonlite::write_json(list(prepared_at_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
    publication_performed=FALSE,canonical_rebuild_performed=FALSE,
    clean_inputs=all(!vapply(specs,function(s)s$manifest$build_tree_dirty,FALSE)),
    parquet_assets=sum(inventory$kind=='parquet'),manifests=sum(inventory$kind=='manifest')),
    file.path(output,'preparation.json'),pretty=TRUE,auto_unbox=TRUE)
  invisible(inventory)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly=TRUE)
  if (!length(args)%in%c(2L,3L) || (length(args)==3L && args[3]!='--allow-dirty'))
    stop('Specify MANIFESTS.csv EMPTY_OUTPUT_DIR [--allow-dirty].')
  inputs <- utils::read.csv(args[1],stringsAsFactors=FALSE)
  if (!'manifest'%in%names(inputs)) stop('CSV requires a manifest column.')
  prepare_canonical_release(inputs$manifest,args[2],length(args)==3L)
}
