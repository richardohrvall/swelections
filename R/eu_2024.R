# European Parliament 2024: one national election/mandate constituency.
# Historical consent-only candidate 1203 is provenance, not a final population input.
.eu2024_cache <- new.env(parent = emptyenv())
.eu2024_levels <- c('riket', 'lan', 'kommun', 'kommunvalkrets', 'valdistrikt')
.eu2024_candidate_hashes <- c(
  'ac3398cee53e0b1a480254419d7b4b6839d91aebc6132e65717223ff34a62776',
  '69988c1abdacee975b14729721588de0b08b075444d41d042790196da194b2a6')

.eu2024_file <- function(kind, source, data_dir, count = 'slutlig') {
  root <- val_data_dir(data_dir)
  name <- if (kind == 'candidacies') 'kandidaturer.zip' else
    paste0('EU-val_2024_', count, '_00_E.zip')
  folder <- if (kind == 'candidacies') 'kandidater' else 'valresultat'
  roots <- if (is.null(root)) character() else unique(c(
    file.path(root, 'eu', '2024'), file.path(root, '2024'), root))
  candidates <- unlist(lapply(roots, function(r) file.path(r, folder,
    if (kind == 'candidacies') c('kandidaturer_20241218.zip',
      'kandidaturer_20240618.zip', name) else name)), use.names = FALSE)
  candidates <- as.character(candidates)
  local <- candidates[file.exists(candidates)]
  verify <- function(file) {
    if (kind != 'candidacies') {
      expected <- c(slutlig='6e1b94b06e44a32f78e471f84b6f654b', preliminar='975ab289844c842685258de085d2acbd')[[count]]
      if (unname(tools::md5sum(file)) != expected) stop('Changed EU 2024 result snapshot: ', name, call. = FALSE)
    }
    file
  }
  if (source != 'remote' && length(local)) return(verify(local[[1]]))
  if (source == 'local') stop('Missing EU 2024 source: ', name, call. = FALSE)
  url <- if (kind == 'candidacies')
    'https://data.val.se/filer/euval2024/parti/kandidaturer.zip' else
    paste0('https://resultat.val.se/resultatfiler/euval2024/',
      if (count == 'slutlig') 's' else 'p', '/e/', name)
  if (!exists(url, .eu2024_cache, inherits = FALSE)) {
    file <- tempfile(fileext = '.zip')
    .download_file(url, file)
    assign(url, file, .eu2024_cache)
  }
  verify(get(url, .eu2024_cache, inherits = FALSE))
}

.eu2024_raw <- function(file, type) {
  key <- paste(normalizePath(file, winslash = '/'), file.info(file)$size,
               file.info(file)$mtime, type)
  if (!exists(key, .eu2024_cache, inherits = FALSE)) {
    x <- read_raw_json_zip_2026(file, type)
    if (!identical(x$valtillfalle, 'EU-val_2024') || !identical(x$valtyp, 'E'))
      stop('Expected official EU 2024 JSON.', call. = FALSE)
    # Explicit election-date registry; never inferred from file modification time.
    x$valdatum <- '2024-06-09'
    x$tidigareValdatum <- '2019-05-26'
    assign(key, x, .eu2024_cache)
  }
  get(key, .eu2024_cache, inherits = FALSE)
}

.eu2024_candidacies <- function(file) {
  dir <- tempfile(); dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  csv <- utils::unzip(file, 'kandidaturer.csv', exdir = dir)
  if (length(csv) != 1L || !file.exists(csv)) stop('Missing EU candidacy CSV.', call. = FALSE)
  hash <- .canonical_sha256(csv)
  if (!hash %in% .eu2024_candidate_hashes)
    stop('Unverified EU 2024 final candidate snapshot; the election-day archive is provenance only.', call. = FALSE)
  out <- readr::read_delim(csv, delim = ';',
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE, progress = FALSE) |>
    janitor::clean_names() |>
    parse_kandidaturer_2026(ar = 2024L, namnvalsedlar_kompletta = TRUE)
  if (any(out$valtyp != 'E')) stop('Unexpected candidacy election code.', call. = FALSE)
  out$valtillfalle <- 'EU-val_2024'
  out
}

.eu2024_contexts <- function(raw, level) {
  make <- function(node, fields = list()) list(node = node, fields = fields)
  if (level == 'riket' || level == 'personvalsomrade')
    return(list(make(raw$valomrade)))
  if (level == 'valdistrikt') return(lapply(raw$valdistrikt, function(d)
    make(d, list(valdistriktskod = d$valdistriktskod,
      valdistriktsnamn = d$namn, valdistriktstyp = d$valdistriktstyp,
      kommunkod = d$kommunkod, lankod = d$lankod,
      kommunvalkretskod = if (grepl('00$', d$kommunvalkretsKod)) NA_character_ else d$kommunvalkretsKod,
      kommunvalkretsnamn = if (grepl('00$', d$kommunvalkretsKod)) NA_character_ else d$kommunvalkretsNamn))))
  unlist(lapply(raw$helaLandet$lan, function(l) {
    fields <- list(lankod = l$lankod, lannamn = l$namn)
    if (level == 'lan') return(list(make(l, fields)))
    unlist(lapply(l$kommuner, function(m) {
      f <- c(fields, list(kommunkod = m$kommunkod, kommunnamn = m$namn))
      if (level == 'kommun') return(list(make(m, f)))
      lapply(Filter(function(k) !grepl('00$', k$kod), m$kommunValkretsar), function(k)
        make(k, c(f, list(kommunvalkretskod = k$kod, kommunvalkretsnamn = k$namn))))
    }), recursive = FALSE)
  }), recursive = FALSE)
}

.eu2024_result <- function(raw, level) {
  cache_key <- if (!is.null(raw$senasteUppdateringstid)) paste('result', raw$valtillfalle, raw$rakningstillfalle, raw$senasteUppdateringstid, level) else NULL
  if (!is.null(cache_key) && exists(cache_key, .eu2024_cache, inherits=FALSE)) return(get(cache_key, .eu2024_cache))
  if (level == 'valdistrikt') {
    x <- parse_rostfordelning_2026(raw)
    x$geografiniva <- level
    x$raknat <- TRUE
  } else {
    ctx <- .eu2024_contexts(raw, level)
    x <- purrr::list_rbind(lapply(ctx, function(c) {
      one <- raw; one$valomrade <- c$node
      if (is.null(one$valomrade$kod)) one$valomrade$kod <- '00'
      a <- parse_rostfordelning_mandat_2026(one)
      a$geografiniva <- level
      if (!is.null(c$node$senasteRapporteringstid)) a$rapporteringstid <- c$node$senasteRapporteringstid
      a$senaste_uppdateringstid_omrade <- as_chr_na(c$node$senasteUppdateringstid)
      a$antal_valdistrikt_raknade_omrade <- as_int_na(c$node$antalValdistriktRaknade)
      a$antal_valdistrikt_som_ska_raknas_omrade <- as_int_na(c$node$antalValdistriktSomSkaRaknas)
      for (n in names(c$fields)) a[[n]] <- c$fields[[n]]
      a
    }))
  }
  x <- dplyr::bind_rows(.valresultat_schema(), x)
  x$valar <- rep(2024L, nrow(x))
  if (level == 'valdistrikt') {
    technical <- grepl('00$', x$kommunvalkretskod)
    x$kommunvalkretskod[technical] <- NA_character_
    x$kommunvalkretsnamn[technical] <- NA_character_
  }
  x$lannamn <- .valresultat_lannamn_2026(x$lankod)
  x <- .komplettera_kommunnamn_2026(x, x$kommunnamn)
  x <- .valresultat_public_andelar_2026(x)
  x <- x[.valresultat_public_columns_2026(level)]
  if (!is.null(cache_key)) assign(cache_key, x, .eu2024_cache)
  x
}

.eu2024_relations <- function(raw) {
  area <- raw$valomrade
  allocated <- area$mandatfordelning$partiLista
  elected <- area$valda$partiLedamoterLista
  if (!identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), 'slutlig') ||
      !length(allocated) || !length(elected) ||
      !identical(area$antalValdistriktRaknade, area$antalValdistriktSomSkaRaknas))
    stop('EU 2024 final elected relation is unavailable or incomplete.', call. = FALSE)
  codes <- vapply(allocated, function(x) x$partikod, '')
  ecodes <- vapply(elected, function(x) x$partikod, '')
  if (anyDuplicated(codes) || anyDuplicated(ecodes) || !setequal(codes, ecodes))
    stop('EU elected/allocated party keys disagree.', call. = FALSE)
  for (party in elected) {
    seats <- allocated[[match(party$partikod, codes)]]$antalMandat
    ids <- vapply(party$ledamoter, function(x) as_chr_na(x$kandidatnummer), '')
    order <- vapply(party$ledamoter, function(x) as_int_na(x$invalsordning), 0L)
    if (length(ids) != seats || anyNA(ids) || anyDuplicated(ids) ||
        !identical(sort(order), seq_len(seats)))
      stop('EU elected positions disagree with allocation.', call. = FALSE)
  }
  out <- parse_valda_ersattare_2026(raw)
  for (n in names(out)) {
    out[[n]]$valar <- rep(2024L, nrow(out[[n]]))
    out[[n]]$geografiniva <- rep('riket', nrow(out[[n]]))
  }
  out
}

# Reuse the vectorised modern list/candidate reader; node identity is explicit.
.eu2024_preference_base <- function(raw, level) {
  cache_key <- if (!is.null(raw$senasteUppdateringstid)) paste('preference',raw$valtillfalle,raw$senasteUppdateringstid,level) else NULL
  if (!is.null(cache_key) && exists(cache_key, .eu2024_cache, inherits=FALSE)) return(get(cache_key, .eu2024_cache))
  contexts <- .eu2024_contexts(raw, level)
  nodes <- lapply(contexts, `[[`, 'node')
  code <- vapply(contexts, function(c) {
    f <- c$fields
    as_chr_na(switch(level, valdistrikt = f$valdistriktskod,
      kommun = f$kommunkod, lan = f$lankod,
      kommunvalkrets = f$kommunvalkretskod, '00'))
  }, '')
  for (i in seq_along(nodes)) {
    nodes[[i]]$valdistriktskod <- code[[i]]
    for (n in c('kommunkod', 'lankod')) nodes[[i]][[n]] <- contexts[[i]]$fields[[n]]
  }
  one <- raw; one$valdistrikt <- nodes
  parsed <- parse_personroster_2026(one)
  parties <- purrr::list_rbind(lapply(seq_along(nodes), function(i) {
    p <- nodes[[i]]$rostfordelning$rosterPaverkaMandat$partiRoster
    tibble::tibble(.geo = code[[i]],
      partikod = vapply(p, function(x) as_chr_na(x$partikod), ''),
      antal_partiroster = vapply(p, function(x) as_int_na(x$antalRoster), 0L))
  }))
  lists <- parsed$listroster |>
    dplyr::rename(.geo = valdistriktskod, antal_listroster = antal_roster_lista)
  votes <- parsed$personroster |>
    dplyr::rename(.geo = valdistriktskod, antal_listroster = antal_roster_lista)
  key <- c('.geo', 'partikod', 'listnummer')
  totals <- votes |>
    dplyr::summarise(.sum = as.integer(sum(.data$antal_personroster)),
                     .by = dplyr::all_of(key))
  check <- dplyr::left_join(lists, totals, by = key, relationship = 'one-to-one')
  if (any(dplyr::coalesce(check$.sum, 0L) != check$antal_roster_med_personrost) ||
      anyDuplicated(votes[c(key, 'kandidatnummer')]))
    stop('EU candidate/list preference totals disagree.', call. = FALSE)
  check_party <- lists |>
    dplyr::summarise(.sum = as.integer(sum(.data$antal_listroster)),
                     .by = c('.geo', 'partikod')) |>
    dplyr::full_join(parties, by = c('.geo', 'partikod'))
  if (anyNA(check_party) || any(check_party$.sum != check_party$antal_partiroster))
    stop('EU list/party totals disagree.', call. = FALSE)
  ctx <- purrr::list_rbind(lapply(seq_along(contexts), function(i)
    tibble::tibble(.geo = code[[i]], !!!contexts[[i]]$fields)))
  out <- list(votes = votes, lists = lists, parties = parties, context = ctx)
  if (!is.null(cache_key)) assign(cache_key, out, .eu2024_cache)
  out
}

.eu2024_preferences <- function(raw, level, kd, by_list, zeros, mandate) {
  base <- .eu2024_preference_base(raw, level)
  qualified <- mandate$valomrade$kvalificeradeForPersonvalLista
  ids <- vapply(qualified, function(x) paste(x$partikod, x$kandidatnummer), '')
  .eu2024_preference_view(base, level, kd, by_list, zeros, ids)
}

.eu2024_preference_view <- function(base, level, kd, by_list, zeros, ids, year = 2024L) {
  key <- c('.geo', 'partikod', 'listnummer', 'kandidatnummer')
  votes <- base$votes[c(key, 'antal_personroster', 'kandidatnamn_lista')]
  if (zeros) {
    population <- kd |>
      dplyr::filter(!is.na(.data$listnummer)) |>
      dplyr::distinct(.data$partikod, .data$listnummer, .data$kandidatnummer)
    population$listnummer <- paste(population$partikod, population$listnummer, sep = '-')
    grid <- dplyr::inner_join(base$lists[c('.geo', 'partikod', 'listnummer')],
      population, by = c('partikod', 'listnummer'), relationship = 'many-to-many')
    missing <- dplyr::anti_join(grid, votes, by = key)
    missing$antal_personroster <- rep(0L, nrow(missing))
    votes <- dplyr::bind_rows(votes, missing)
  }
  if (!by_list) {
    candidate_key <- c('.geo', 'partikod', 'kandidatnummer')
    first_names <- votes[!duplicated(votes[candidate_key]), c(candidate_key, 'kandidatnamn_lista')]
    votes <- votes |>
      dplyr::summarise(antal_personroster = sum(.data$antal_personroster),
        .by = dplyr::all_of(candidate_key)) |>
      dplyr::left_join(first_names, by = candidate_key, relationship = 'one-to-one')
    votes$antal_personroster <- as.integer(votes$antal_personroster)
  }
  out <- dplyr::left_join(votes, base$parties, by = c('.geo', 'partikod'), relationship = 'many-to-one')
  if (by_list) out <- dplyr::left_join(out,
    base$lists[c('.geo', 'partikod', 'listnummer', 'antal_listroster')],
    by = c('.geo', 'partikod', 'listnummer'), relationship = 'many-to-one')
  names_source <- kd |>
    dplyr::distinct(.data$kandidatnummer, .data$partikod, .keep_all = TRUE) |>
    dplyr::select('kandidatnummer', 'partikod', 'namn', 'partiforkortning', 'partibeteckning')
  out <- dplyr::left_join(out, names_source, by = c('kandidatnummer', 'partikod'), relationship = 'many-to-one')
  # Ineligible source rows retain the official result placeholder, not an invented name.
  out$namn <- dplyr::coalesce(out$kandidatnamn_lista, out$namn)
  out <- dplyr::left_join(out, base$context, by = '.geo', relationship = 'many-to-one')
  out$valtillfalle <- paste0('EU-val_', year); out$valar <- as.integer(year); out$valtyp <- 'E'
  out$geografiniva <- level; out$rakningstillfalle <- 'slutlig'; out$valdatum <- if (year == 2019L) '2019-05-26' else '2024-06-09'
  out$andel_personroster <- .exakt_andel_2026(out$antal_personroster, out$antal_partiroster)
  if (by_list) {
    out$andel_personroster_lista <- .exakt_andel_2026(out$antal_personroster, out$antal_listroster)
    out$listnummer <- sub('^[^-]+-', '', out$listnummer)
  }
  out$kvalificerad_personval <- if (level %in% c('personvalsomrade', 'riket'))
    paste(out$partikod, out$kandidatnummer) %in% ids else rep(NA, nrow(out))
  if (level == 'personvalsomrade') {
    out$personvalsomradeskod <- '00'; out$personvalsomradesnamn <- 'Riket'
  }
  if ('lankod' %in% names(out)) out$lannamn <- .valresultat_lannamn_2026(out$lankod)
  if ('kommunkod' %in% names(out)) out$kommunnamn <- kommunnamn_2026$kommunnamn[match(out$kommunkod, kommunnamn_2026$kommunkod)]
  out$.geo <- NULL; out$kandidatnamn_lista <- NULL
  out
}

.eu2024_candidates <- function(kd, mandate, include_results = TRUE) {
  out <- .kandidater_bas(kd, 2024L)
  if (!include_results) return(out)
  pref <- .eu2024_preferences(mandate, 'personvalsomrade', kd, FALSE, FALSE, mandate)
  totals <- pref[c('kandidatnummer', 'partikod', 'antal_personroster', 'kvalificerad_personval')]
  out <- dplyr::left_join(out, totals, by = c('kandidatnummer', 'partikod'), relationship = 'one-to-one')
  out$antal_personroster_totalt <- dplyr::coalesce(out$antal_personroster, 0L)
  out$antal_personroster <- NULL
  out$kvalificerad_personval <- dplyr::coalesce(out$kvalificerad_personval, FALSE)
  out$antal_personvalsomraden <- as.integer(out$kvalificerad_personval)
  add_valda_to_kandidater_2026(out, .eu2024_relations(mandate)$valda)
}

.eu2024_read <- function(table, args) {
  if (table == 'candidacies') return(.eu2024_candidacies(
    .eu2024_file('candidacies', args$source, args$data_dir)))
  if (table == 'candidates' && identical(args$resultat, FALSE)) return(.kandidater_bas(
    .eu2024_candidacies(.eu2024_file('candidacies', args$source, args$data_dir)), 2024L))
  count <- if (is.null(args$rakning)) 'slutlig' else args$rakning
  level <- args$niva
  file <- .eu2024_file('results', args$source, args$data_dir, count)
  if (table == 'results') {
    if (is.null(level)) level <- 'riket'
    if (length(level) != 1L || !level %in% .eu2024_levels) stop('Unsupported EU result level.', call. = FALSE)
    kind <- if (level == 'valdistrikt') 'rostfordelning' else if (level == 'riket') 'mandatfordelning' else 'summering'
    return(.eu2024_result(.eu2024_raw(file, kind), level))
  }
  m <- .eu2024_raw(file, 'mandatfordelning')
  if (table == 'seats') {
    if (!is.null(level) && !identical(level, 'riket')) stop('EU seats are national only.', call. = FALSE)
    out <- parse_mandat_2026(m); out$geografiniva <- 'riket'; out$valar <- 2024L
    if (count == 'slutlig') {
      .eu2024_relations(m)
      p <- m$valomrade$valda$partiLedamoterLista
      out$antal_tomma_stolar <- out$antal_mandat -
        vapply(p, function(x) length(x$ledamoter), 0L)[match(out$partikod, vapply(p, function(x) x$partikod, ''))]
    } else out$antal_tomma_stolar <- NA_integer_
    return(.mandat_public_2026(out, 2024L))
  }
  if (table == 'substitutes') return(.eu2024_relations(m)$ersattare)
  kd <- .eu2024_candidacies(.eu2024_file('candidacies', args$source, args$data_dir))
  if (table == 'candidacies') return(kd)
  if (table == 'substitutes') return(.eu2024_relations(m)$ersattare)
  if (table %in% c('candidates', 'elected')) {
    out <- .eu2024_candidates(kd, m, !identical(args$resultat, FALSE))
    if (table == 'elected') {
      out <- .valda_invaldsvalkrets_2026(out)
      out <- out[out$invald %in% TRUE, setdiff(names(out), 'antal_valkretsar')]
    }
    return(out)
  }
  if (!level %in% c(.eu2024_levels, 'personvalsomrade')) stop('Unsupported EU preference-vote level.', call. = FALSE)
  raw <- if (level %in% c('riket', 'personvalsomrade')) m else
    .eu2024_raw(file, if (level == 'valdistrikt') 'rostfordelning' else 'summering')
  .eu2024_preferences(raw, level, kd, args$per_lista, args$komplettera_nollor, m)
}

.eu2024_dispatch <- function(args, year, year_missing, table) {
  years <- .resolve_valar(if (identical(year, 'all')) 'alla' else if (year_missing &&
    is.null(args$fran) && is.null(args$till)) 2024L else year,
    args$fran, args$till, c(results='valresultat', seats='mandat',
      candidacies='kandidaturer', candidates='kandidater', elected='valda',
      substitutes='ersattare', preference_votes='personroster')[[table]], 'E', !year_missing)
  args$source <- match.arg(args$source, c('auto', 'local', 'remote', 'canonical'))
  for (flag in c('update', 'archive', 'progress', 'resultat'))
    if (!is.null(args[[flag]])) .check_flag(args[[flag]], flag)
  if (isTRUE(args$update) || isTRUE(args$archive)) stop('EU snapshots are read-only; preserve updates separately.', call. = FALSE)
  if (!is.null(args$rakning) && (length(args$rakning) != 1L || !args$rakning %in% c('slutlig', 'preliminar'))) stop('Unknown EU count stage.', call. = FALSE)
  return(purrr::list_rbind(lapply(years, function(y) {
    if (args$source == 'canonical') return(if (y == 2019L) .eu2019_canonical(table, args) else .eu2024_canonical(table, args))
    if (y == 2019L) .eu2019_read(table, args) else .eu2024_read(table, args)
  })))
}
