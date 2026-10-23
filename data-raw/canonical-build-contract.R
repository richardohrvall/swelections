# Shared metadata for the unpublished English value/storage contract.
canonical_build_contract <- function(manifest) {
  # JSON must not retain obsolete Swedish table selectors as synthetic _row keys.
  if (is.data.frame(manifest$tables)) rownames(manifest$tables) <- NULL
  manifest$data_version <- 'data-v0.4.1'
  manifest$schema_version <- 3L
  manifest$value_schema_version <- 1L
  manifest$storage_schema_version <- 1L
  manifest$value_contract <- list(language='en', booleans='logical',
    not_applicable='logical NA with *_applicable FALSE; unknown has *_applicable NA',
    referendum_options='voting_option_name: yes/no/blank; original option identifiers retained',
    source_values='proper names, official identifiers and explicit source fields remain literal',
    aggregate_labels='Other parties; Handwritten votes',
    internal_keys='English .table/.component; .person_view and source IDs unchanged')
  manifest$built_at_utc <- format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ',tz='UTC')
  manifest$build_commit <- trimws(system2('git',c('rev-parse','HEAD'),stdout=TRUE))
  manifest$build_tree_dirty <- length(system2('git',c('status','--porcelain'),stdout=TRUE))>0L
  files <- c(list.files('R',pattern='[.]R$',full.names=TRUE),
    list.files('data-raw',pattern='^(build-canonical|export-canonical|standardize-canonical|canonical-build-contract).*R$',full.names=TRUE))
  manifest$build_code_sha256 <- data.frame(file=files,
    sha256=vapply(files,swelections:::.canonical_sha256,''),stringsAsFactors=FALSE)
  manifest$release_status <- 'unpublished_release_candidate_build'
  manifest
}
