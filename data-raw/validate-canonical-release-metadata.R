
# Independent release-metadata regression and original/copy integrity checks.
# Rscript data-raw/validate-canonical-release-metadata.R ORIGINAL_STAGE PORTABLE_STAGE INPUTS.csv
validate_canonical_release_metadata <- function(original, portable, inputs) {
  scan_paths <- function(x) {
    if (is.list(x)) return(unlist(lapply(x,scan_paths),use.names=FALSE))
    if (!is.character(x)) return(character())
    y <- gsub(intToUtf8(92L),"/",x,fixed=TRUE)
    x[!is.na(y) & (grepl("^[A-Za-z]:/",y) | startsWith(y,"//") | grepl("^/(home|Users|tmp|var|mnt)/",y) |
      grepl("^file:",y,ignore.case=TRUE))]
  }
  stopifnot(length(scan_paths(c("C:/a","D:\\a","//server/a","/home/a","file:///a")))==5L,
    length(scan_paths(c("https://historik.val.se:443/a","rkl/2010/a")))==0L)
  a <- read.csv(file.path(original,"upload-inventory.csv"))
  b <- read.csv(file.path(portable,"upload-inventory.csv"))
  old_assets <- a[a$kind=="parquet",];new_assets <- b[b$kind=="parquet",]
  i <- match(old_assets$file,new_assets$file)
  comparable <- new_assets[i,];rownames(comparable)<-NULL;rownames(old_assets)<-NULL
  expected_new <- setdiff(c("rkl2014-mandate-history.parquet",
    "rkl2018-mandate-history.parquet"),old_assets$file)
  stopifnot(!anyNA(i),identical(old_assets,comparable),
    setequal(setdiff(new_assets$file,old_assets$file),expected_new),
    nrow(b)==202L,sum(b$kind=="manifest")==12L,nrow(new_assets)==190L)
  paths <- read.csv(inputs)$manifest
  hash <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)
  read <- function(p) jsonlite::read_json(p,simplifyVector=FALSE)
  changes <- list()
  for (p in paths) {
    m <- read(p)
    key <- paste0(m$valserie,m$valar)
    f <- b$file[b$product==key & b$kind=="manifest"]
    old <- read(file.path(original,"upload",f))
    new <- read(file.path(portable,"upload",f))
    stopifnot(length(scan_paths(new))==0L,
      identical(new$distribution$source_manifest_sha256,hash(p)),
      identical(new$build_tree_dirty, m$build_tree_dirty))
    approved_assets <- vapply(old$assets,function(z)z$asset,"")
    retained <- Filter(function(z)z$asset%in%approved_assets,new$assets)
    retained_tables <- Filter(function(z)z$asset%in%approved_assets,new$tables)
    stopifnot(identical(old$assets,retained),identical(old$tables,retained_tables))
    new$assets<-retained;new$tables<-retained_tables
    if(key%in%c("rkl2014","rkl2018")) {
      old$mandate_history<-new$mandate_history<-NULL
      old$component_builds<-new$component_builds<-NULL
      old$auto_functions<-new$auto_functions<-NULL
      old$distribution$source_manifest_sha256<-new$distribution$source_manifest_sha256<-NULL
    }
    old$distribution$source_path_basis <- new$distribution$source_path_basis <- NULL
    old$distribution$source_identity_basis <- new$distribution$source_identity_basis <- NULL
    ov <- unlist(old,use.names=TRUE); nv <- unlist(new,use.names=TRUE)
    stopifnot(identical(names(ov),names(nv)))
    differences <- which(ov!=nv & !is.na(ov) & !is.na(nv))
    stopifnot(length(scan_paths(unname(ov[differences])))==length(differences))
    orig <- read(p)
    copied <- read(file.path(portable,"upload",f))
    before <- unlist(orig$sources,use.names=FALSE)
    after <- unlist(copied$sources,use.names=FALSE)
    stopifnot(length(before)==length(after))
    changed <- which(before!=after & !is.na(before) & !is.na(after))
    if(length(changed)) changes[[key]] <- data.frame(product=key,original=before[changed],
      portable=after[changed],stringsAsFactors=FALSE)
    for (s in c("sha256","md5","url")) {
      pick <- function(x) {
        if(!is.list(x)) return(NULL)
        c(x[[s]],unlist(lapply(x, function(v) if(is.list(v)) pick(v) else NULL),use.names=FALSE))
      }
      stopifnot(identical(pick(orig$sources),pick(copied$sources)))
    }
  }
  if(length(changes)) write.csv(do.call(rbind,changes),
    file.path(portable,"provenance-path-changes.csv"),row.names=FALSE)
  cat("PASS: twelve portable manifests; all 188 original Parquet entries unchanged; only the two declared history additions.\n")
  cat("PASS: original manifest SHA256, source hashes and official URLs preserved; build status matches the input manifests.\n")
  invisible(b)
}
if(sys.nframe()==0L) {
  args <- commandArgs(TRUE)
  stopifnot(length(args)==3L)
  validate_canonical_release_metadata(args[1],args[2],args[3])
}
