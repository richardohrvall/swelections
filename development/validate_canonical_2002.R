# Opt-in public API/raw/canonical equivalence; no source writes or network.
# Rscript development/validate_canonical_2002.R RAW_ROOT ASSETS_DIR [SECTION [RD|RF|KF]]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% 2:4) stop('Specify RAW_ROOT ASSETS_DIR [SECTION [ELECTION]].')
section <- if (length(args) >= 3L) args[[3]] else 'all'
elections <- if (length(args) == 4L) args[[4]] else c('RD', 'RF', 'KF')
stopifnot(section %in% c('all', 'results', 'candidates', 'preference_votes'), all(elections %in% c('RD', 'RF', 'KF')))
pkgload::load_all('.', quiet = TRUE)
root <- args[[1]]; directory <- normalizePath(args[[2]], winslash = '/', mustWork = TRUE)
m <- swelections:::.canonical_manifest(file.path(directory, 'manifest.json'))
options(swelections.canonical_manifest = file.path(directory, 'manifest.json'),
  swelections.canonical_assets_dir = directory,
  swelections.canonical_cache_dir = file.path(dirname(directory), paste0('2002-validation-cache-', section, '-', paste(elections, collapse = '-'))))
checks <- 0L
same <- function(a, b, label) {
  if (!identical(a, b)) stop(label, ': ', paste(all.equal(a, b), collapse = '; '))
  checks <<- checks + 1L
}
for (i in seq_len(nrow(m$assets))) {
  a <- m$assets[i, ]; f <- file.path(directory, a$file)
  same(unname(file.info(f)$size), as.double(a$bytes), 'asset size')
  same(swelections:::.canonical_sha256(f), a$sha256, 'asset checksum')
  x <- tibble::as_tibble(nanoparquet::read_parquet(f))
  stopifnot(!anyDuplicated(names(x)), !any(vapply(x, is.list, logical(1))))
  same(swelections:::.canonical_names_en(swelections:::.canonical_names_sv(x)), x, 'English canonical schema round trip')
}
s <- swelections:::.sources_2002('local', root)
for (f in s$sources$export) swelections:::.xml2002_source(s, f)
# Memoisation exists only in this process. Each distinct raw view is still
# independently derived from its registered, checksum-verified source files.
ns <- asNamespace('swelections'); cache <- new.env(parent = emptyenv())
unlockBinding('.sources_2002', ns); assign('.sources_2002', function(...) s, ns); lockBinding('.sources_2002', ns)
readers <- c('.valresultat_2002', '.mandat_2002', '.kandidater_2002', '.valda_2002',
  '.ersattare_2002', '.personroster_2002', '.xml2002_population', '.xml2002_relations')
for (name in readers) local({
  keyname <- name; fun <- get(name, ns)
  memo <- function(...) {
    a <- list(...); a[[1]] <- NULL
    if (any(vapply(a, is.list, logical(1)))) return(fun(...))
    key <- paste(keyname, paste(capture.output(dput(a)), collapse = ''), sep = '|')
    if (exists(key, cache, inherits = FALSE)) return(get(key, cache))
    x <- fun(...); assign(key, x, cache); x
  }
  unlockBinding(name, ns); assign(name, memo, ns); lockBinding(name, ns)
})
check <- function(fun, arguments, label) {
  call <- function(source, detail, names) do.call(fun,
    c(list(year = 2002, source = source, data_dir = if (source == 'local') root else NULL,
      detail = detail, names = names), arguments))
  raw <- call('local', 'full', 'sv'); can <- call('canonical', 'full', 'sv')
  same(can, raw, paste(label, 'raw full: rows/values/types/missingness/order'))
  for (detail in c('standard', 'full')) for (source in c('local', 'canonical')) {
    en <- call(source, detail, 'en'); sv <- call(source, detail, 'sv')
    same(swelections:::.public_output_names(sv, 'en'), en, paste(label, source, detail, 'language'))
    same(sv, can[names(sv)], paste(label, source, detail, 'projection'))
  }
  cat('PASS', label, nrow(raw), 'rows\n'); flush.console(); raw
}
levels <- c(valdistrikt = 'district', kommun = 'municipality', kommunvalkrets = 'municipal_constituency',
  lan = 'county', riksdagsvalkrets = 'parliamentary_constituency', regionvalkrets = 'regional_constituency',
  region = 'region', riket = 'national')
for (v in elections) {
  asset <- paste0('rkl2002-results-slutlig-', tolower(v))
  if (section %in% c('all', 'results')) for (level in m$tables$table[m$tables$asset == asset])
    check(results, list(election = v, level = unname(levels[[level]]), count = 'final'), paste(v, 'results', level))
  if (section %in% c('all', 'candidates')) {
  check(seats, list(election = v), paste(v, 'seats'))
  for (fn in c('candidates', 'elected', 'substitutes')) check(get(fn), list(election = v), paste(v, fn))
  check(candidates, list(election = v, include_results = FALSE), paste(v, 'candidate base'))
  observed <- swelections:::.xml2002_population(s, v)$pref
  candidate_rows <- candidates(2002, election = v, source = 'canonical', detail = 'full', names = 'sv')
  position <- match(observed$kandidatnummer, candidate_rows$kandidatnummer)
  stopifnot(!anyNA(position))
  same(candidate_rows$antal_personroster_totalt[position], observed$antal_personroster,
    'candidate enrichment preserves individually observed area counts')
  }
  if (section %in% c('all', 'preference_votes')) for (level in c('area', 'district')) {
    asset <- paste0('rkl2002-preference-votes-', level, '-', tolower(v))
    if (!asset %in% m$assets$asset) next
    for (by in m$tables$table[m$tables$asset == asset]) {
      arguments <- list(election = v, level = if (level == 'area') 'preference_vote_area' else 'district', by_list = by == 'TRUE')
      x <- check(preference_votes, arguments, paste(v, 'preference', level, by))
      z <- do.call(preference_votes, c(list(year = 2002, source = 'canonical', detail = 'full', names = 'sv', include_zeros = TRUE), arguments))
      same(z, x, 'no unsupported synthetic zeros')
      keys <- intersect(c('valtyp', 'kandidatnummer', 'partikod', 'personvalsomradeskod', 'valdistriktskod', 'listnummer'), names(x))
      same(anyDuplicated(x[keys]), 0L, 'unique source-observation key')
    }
  }
  if (section %in% c('all', 'candidates')) {
  x <- elected(2002, election = v, source = 'canonical', detail = 'full')
  same(nrow(x), c(RD = 349L, RF = 1656L, KF = 13271L)[[v]], 'official elected observations')
  stopifnot(all(is.na(x$name)), !anyDuplicated(x$candidate_number))
  appointed <- replacement <- list()
  for (file in swelections:::.xml2002_files(s, v, v == 'KF')) {
    doc <- xml2::read_xml(swelections:::.xml2002_source(s, file), options = 'NONET')
    source_key <- function(nodes) paste0('2002:', v, ':slot:', vapply(
      paste(xml2::xml_attr(doc, 'FILNAMN'), xml2::xml_path(nodes), sep = '|'),
      utils::URLencode, '', reserved = TRUE))
    for (group in xml2::xml_find_all(doc, './/GRUPP_VALDA')) {
      members <- xml2::xml_find_all(group, './VALD[not(@NAMN="Kunde ej utses") and not(@NAMN="Kunde inte utses")]')
      source_replacements <- xml2::xml_find_all(group, './ERSÄTTARE')
      if (length(members)) {
        party <- xml2::xml_attr(xml2::xml_find_first(members, 'ancestor::GILTIGA[1]'), 'PARTI')
        area <- xml2::xml_find_first(members, switch(v,
          RD = 'ancestor::KRETS_RIKSDAG[1]', RF = 'ancestor::KRETS_LANDSTING[1]',
          KF = 'ancestor::KRETS_KOMMUN[1]'))
        appointed[[length(appointed) + 1L]] <- data.frame(id = source_key(members),
          order = as.integer(xml2::xml_attr(members, 'ORDNING')), basis = xml2::xml_attr(members, 'GRUND'),
          party = party, constituency = xml2::xml_attr(area, 'KOD'))
      }
      for (member in members) if (length(source_replacements)) replacement[[length(replacement) + 1L]] <- data.frame(
        member = source_key(member), replacement = source_key(source_replacements),
        order = as.integer(xml2::xml_attr(source_replacements, 'ORDNING')))
    }
  }
  a <- dplyr::bind_rows(appointed); j <- match(a$id, x$candidate_number)
  stopifnot(!anyNA(j))
  same(x$order_of_election[j], a$order, 'independent XML election order')
  same(x$election_basis_id[j], a$basis, 'independent XML election basis')
  known <- a$party %in% c('M', 'C', 'FP', 'KD', 'S', 'V', 'MP')
  same(x$party_abbreviation[j[known]], a$party[known], 'independent XML major-party abbreviations')
  divided <- !endsWith(a$constituency, '00')
  field <- if (v == 'KF') 'elected_municipal_constituency_code' else 'elected_constituency_code'
  same(x[[field]][j[divided]], a$constituency[divided], 'independent XML elected constituency')
  r <- dplyr::bind_rows(replacement)
  y <- get('substitutes', envir = asNamespace('swelections'))(2002, election = v, source = 'canonical', detail = 'full')
  signature <- function(member, replacement, order) paste(member, replacement, order, sep = '|')
  same(sort(signature(y$member_candidate_number, y$substitute_candidate_number, y$substitute_order)),
    sort(signature(r$member, r$replacement, r$order)), 'independent XML expanded substitute relationships')
  }
}
# Seven families assessed; no false ballot population or preliminary coverage.
stopifnot(inherits(try(candidacies(2002, source = 'local', data_dir = root), silent = TRUE), 'try-error'),
  inherits(try(results(2002, election = 'KF', count = 'preliminary', source = 'local', data_dir = root), silent = TRUE), 'try-error'))
for (f in s$sources$export) swelections:::.xml2002_source(s, f)
cat('PASS', checks, 'comparisons; all selected source checksums verified twice\n')
