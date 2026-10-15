# Final referendum results share totals/geography, never party semantics.
.referendum2003_levels <- c('riket', 'lan', 'riksdagsvalkrets', 'kommun',
                           'kommunvalkrets', 'valdistrikt')
.referendum2003_standard <- c(
  'valtillfalle', 'valar', 'valdatum', 'valtyp', 'rakningstillfalle',
  'folkomrostningsfraga', 'geografiniva', .standard_geography,
  'valdistriktstyp', 'rostningsalternativkod', 'rostningsalternativnamn',
  'blankt_alternativ', 'antal_roster', 'andel_roster', 'giltiga_roster',
  'blanka_roster', 'ogiltiga_roster', 'totalt_antal_roster',
  'antal_rostberattigade', 'antal_rostberattigade_svenska_i_sverige',
  'antal_rostberattigade_svenska_utomlands', 'antal_rostberattigade_utlandska',
  'valdel', 'raknat',
  'antal_valdistrikt_raknade_omrade', 'antal_valdistrikt_som_ska_raknas_omrade'
)

.referendum2003_integer <- function(node, field, required = TRUE) {
  value <- xml2::xml_attr(node, field)
  if (is.na(value) && !required) return(NA_integer_)
  if (is.na(value) || !grepl('^[0-9]+$', value) ||
      as.double(value) > .Machine$integer.max)
    stop('Invalid referendum count: ', field, call. = FALSE)
  as.integer(value)
}

.referendum2003_file <- function(source, root, filename) {
  local <- file.path(root, filename)
  if (source == 'local') {
    if (!file.exists(local)) stop('Missing 2003 referendum source: ', local, call. = FALSE)
    manifest <- file.path(root, 'source-manifest.json')
    if (file.exists(manifest)) {
      entries <- jsonlite::read_json(manifest, simplifyVector = TRUE)
      entry <- entries[entries$file == filename, , drop = FALSE]
      if (nrow(entry) != 1L || file.info(local)$size != entry$size ||
          unname(tools::md5sum(local)) != entry$md5 ||
          .canonical_sha256(local) != entry$sha256)
        stop('Changed or unregistered referendum source: ', filename, call. = FALSE)
    }
    return(local)
  }
  name <- if (filename == 'final.xml') 'slutresultat_00F.xml' else
    paste0('slutresultat_', tools::file_path_sans_ext(basename(filename)), 'F.xml')
  file <- tempfile(fileext = '.xml')
  .download_file(paste0('https://historik.val.se/val/emu2003/resultat/slutresultat/', name), file)
  file
}

.referendum2003_document <- function(file, municipality = NULL) {
  x <- xml2::read_xml(file)
  if (xml2::xml_attr(x, 'VALTYP') != 'Folkomr\u00f6stning' ||
      xml2::xml_attr(x, 'RAPPORTERING') != 'SLUTLIG SAMMANR\u00c4KNING RESULTAT' ||
      xml2::xml_attr(x, 'TILLF\u00c4LLE') !=
        'Folkomr\u00f6stning 14 september 2003 om inf\u00f6rande av euron')
    stop('Expected the final 14 September 2003 referendum source.', call. = FALSE)
  registry <- xml2::xml_attr(xml2::xml_find_all(x, './PARTI'), 'F\u00d6RKORTNING')
  if (!setequal(registry, c('JA', 'NEJ', 'BLANK', 'OG')) || anyDuplicated(registry))
    stop('Unexpected referendum voting-option registry.', call. = FALSE)
  if (!is.null(municipality) &&
      !identical(xml2::xml_attr(xml2::xml_find_all(x, './KOMMUN'), 'KOD'), municipality))
    stop('Referendum municipality file does not match its requested code.', call. = FALSE)
  x
}

.referendum2003_node <- function(node, context, source_file, root_time) {
  categories <- xml2::xml_find_all(node, './GILTIGA')
  options <- xml2::xml_attr(categories, 'PARTI')
  invalid_node <- xml2::xml_find_all(node, './OGILTIGA')
  if (!setequal(options, c('JA', 'NEJ', 'BLANK')) || anyDuplicated(options) ||
      length(invalid_node) != 1L || xml2::xml_attr(invalid_node, 'TEXT') != 'OG')
    stop('Missing or duplicate referendum ballot categories.', call. = FALSE)
  votes <- vapply(categories, .referendum2003_integer, 1L, field = 'R\u00d6STER')
  valid <- .referendum2003_integer(node, 'R\u00d6STER')
  invalid <- .referendum2003_integer(invalid_node, 'R\u00d6STER')
  if (sum(votes) != valid) stop('Referendum valid-option totals disagree.', call. = FALSE)
  turnout <- xml2::xml_find_all(node, './VALDELTAGANDE')
  wednesday <- xml2::xml_name(node) == 'ONSDAGSDISTRIKT'
  if ((wednesday && length(turnout)) || (!wednesday && length(turnout) != 1L))
    stop('Unexpected referendum electorate structure.', call. = FALSE)
  eligible <- if (wednesday) NA_integer_ else
    .referendum2003_integer(turnout, 'R\u00d6STBER\u00c4TTIGADE')
  cast <- if (wednesday) as.integer(valid + invalid) else
    .referendum2003_integer(turnout, 'SUMMA_R\u00d6STER')
  if (cast != valid + invalid) stop('Referendum ballots cast disagree.', call. = FALSE)
  source_percent <- function(n, field) as.double(sub(',', '.', xml2::xml_attr(n, field), fixed = TRUE))
  tibble::tibble(
    valtillfalle = 'Folkomr\u00f6stning 14 september 2003 om inf\u00f6rande av euron',
    valar = 2003L, valdatum = '2003-09-14', valtyp = 'F', rakningstillfalle = 'slutlig',
    folkomrostningsfraga = 'Anser du att Sverige skall inf\u00f6ra euron som valuta',
    geografiniva = context$level, !!!context$fields,
    rostningsalternativkod = options,
    rostningsalternativnamn = unname(c(JA = 'Ja', NEJ = 'Nej', BLANK = 'Blank')[options]),
    blankt_alternativ = options == 'BLANK', antal_roster = votes,
    andel_roster = if (valid > 0L) votes / valid else NA_real_,
    giltiga_roster = valid, blanka_roster = votes[options == 'BLANK'],
    ogiltiga_roster = invalid, totalt_antal_roster = cast,
    antal_rostberattigade = eligible,
    antal_rostberattigade_svenska_i_sverige = NA_integer_,
    antal_rostberattigade_svenska_utomlands = NA_integer_,
    antal_rostberattigade_utlandska = NA_integer_,
    valdel = if (!is.na(eligible) && eligible > 0L) cast / eligible else NA_real_,
    raknat = TRUE,
    antal_valdistrikt_raknade_omrade = .referendum2003_integer(node, 'KLARA_VALDISTRIKT', FALSE),
    antal_valdistrikt_som_ska_raknas_omrade = .referendum2003_integer(node, 'ALLA_VALDISTRIKT', FALSE),
    kall_enhetskod = xml2::xml_attr(node, 'KOD'), kall_enhetsnamn = xml2::xml_attr(node, 'NAMN'),
    kall_nodtyp = xml2::xml_name(node), kallfil = source_file,
    senaste_uppdateringstid = root_time, rapporteringstid = xml2::xml_attr(node, 'TID_RAPPORT'),
    kall_rostprocent = vapply(categories, source_percent, 1.0, field = 'PROCENT'),
    kall_valdeltagandeprocent = if (wednesday) NA_real_ else source_percent(turnout, 'PROCENT')
  )
}

.referendum2003_raw <- function(source, data_dir, level) {
  root <- val_data_dir(data_dir)
  if (is.null(root)) root <- ''
  if (source == 'local' && !nzchar(root))
    stop('Specify data_dir for the preserved 2003 referendum archive.', call. = FALSE)
  needs_district <- level %in% c('valdistrikt', 'kommunvalkrets')
  national_local <- file.path(root, 'final.xml')
  if (source == 'auto') {
    suitable <- nzchar(root) && file.exists(national_local)
    if (suitable && needs_district) {
      n <- .referendum2003_document(national_local)
      codes <- xml2::xml_attr(xml2::xml_find_all(n, './/KOMMUN'), 'KOD')
      suitable <- all(file.exists(file.path(root, 'final-municipal', paste0(codes, '.xml'))))
    }
    source <- if (suitable) 'local' else 'remote'
  }
  read <- function(filename, municipality = NULL) {
    file <- .referendum2003_file(source, root, filename)
    if (source == 'remote') on.exit(unlink(file), add = TRUE)
    .referendum2003_document(file, municipality)
  }
  national <- read('final.xml')
  name_pair <- function(node, prefix) stats::setNames(
    list(xml2::xml_attr(node, 'KOD'), xml2::xml_attr(node, 'NAMN')),
    paste0(prefix, c('kod', 'namn')))
  context <- function(node) {
    type <- xml2::xml_name(node)
    fields <- list()
    county <- xml2::xml_find_first(node, 'ancestor-or-self::L\u00c4N')
    constituency <- xml2::xml_find_first(node, 'ancestor-or-self::KRETS_RIKSDAG')
    municipality <- xml2::xml_find_first(node, 'ancestor-or-self::KOMMUN')
    if (!inherits(county, 'xml_missing')) fields <- c(fields, name_pair(county, 'lan'))
    if (!inherits(constituency, 'xml_missing')) fields <- c(fields, name_pair(constituency, 'valkrets'))
    if (!inherits(municipality, 'xml_missing')) fields <- c(fields, name_pair(municipality, 'kommun'))
    list(level = level, fields = fields)
  }
  if (!needs_district) {
    tag <- c(riket = 'NATION', lan = 'L\u00c4N', riksdagsvalkrets = 'KRETS_RIKSDAG', kommun = 'KOMMUN')[[level]]
    nodes <- xml2::xml_find_all(national, paste0('.//', tag))
    data <- purrr::list_rbind(lapply(nodes, function(n)
      .referendum2003_node(n, context(n), 'slutresultat_00F.xml', xml2::xml_attr(national, 'TID_RAPPORT'))))
    return(.referendum2003_enrich_electorate(data, source, root, level))
  }
  municipalities <- xml2::xml_find_all(national, './/KOMMUN')
  purrr::list_rbind(lapply(municipalities, function(m) {
    code <- xml2::xml_attr(m, 'KOD')
    doc <- read(paste0('final-municipal/', code, '.xml'), code)
    nodes <- xml2::xml_find_all(doc, if (level == 'valdistrikt') './/VALDISTRIKT|.//ONSDAGSDISTRIKT' else './/KRETS_KOMMUN')
    if (level == 'kommunvalkrets') nodes <- nodes[!grepl('00$', xml2::xml_attr(nodes, 'KOD'))]
    purrr::list_rbind(lapply(nodes, function(n) {
      ctx <- context(m)
      k <- xml2::xml_find_first(n, 'ancestor-or-self::KRETS_KOMMUN')
      if (!grepl('00$', xml2::xml_attr(k, 'KOD'))) ctx$fields <- c(ctx$fields, name_pair(k, 'kommunvalkrets'))
      else ctx$fields <- c(ctx$fields, list(kommunvalkretskod = NA_character_, kommunvalkretsnamn = NA_character_))
      if (level == 'valdistrikt') ctx$fields <- c(ctx$fields, name_pair(n, 'valdistrikts'),
        list(valdistriktstyp = if (xml2::xml_name(n) == 'ONSDAGSDISTRIKT') 'wednesday' else 'ordinary'))
      out <- .referendum2003_node(n, ctx, paste0('slutresultat_', code, 'F.xml'), xml2::xml_attr(doc, 'TID_RAPPORT'))
      out$kall_kommunvalkretskod <- xml2::xml_attr(k, 'KOD')
      out$kall_kommunvalkretsnamn <- xml2::xml_attr(k, 'NAMN')
      out
    }))
  }))
}

.referendum2003_results <- function(year, year_missing, from, to, count, level,
                                    source, data_dir, update, archive, progress, names, detail) {
  language <- .english_output_language(names)
  detail <- .check_detail(detail)
  .resolve_valar(if (identical(year, 'all')) 'alla' else year, from, to,
                 'valresultat', 'F', !year_missing)
  if (!identical(count, 'final'))
    stop('2003 referendum supports final results only; preliminary Wednesday sources remain unrecovered.', call. = FALSE)
  if (is.null(level)) level <- 'national'
  level <- .english_argument_value(level, 'level')
  if (length(level) != 1L || !level %in% .referendum2003_levels)
    stop('Unsupported 2003 referendum geographic level.', call. = FALSE)
  source <- match.arg(source, c('auto', 'local', 'remote', 'canonical'))
  for (flag in list(update, archive, progress))
    if (!is.logical(flag) || length(flag) != 1L || is.na(flag)) stop('Expected scalar logical flags.', call. = FALSE)
  if (update || archive) stop('2003 referendum sources are read-only; preserve snapshots separately.', call. = FALSE)
  data <- if (source == 'canonical') .canonical_referendum2003(level) else
    .referendum2003_raw(source, data_dir, level)
  if (anyDuplicated(data[c('kall_enhetskod', 'rostningsalternativkod')]))
    stop('Duplicate referendum result keys.', call. = FALSE)
  if (detail == 'standard') data <- data[, intersect(.referendum2003_standard, names(data)), drop = FALSE]
  .public_output_names(data, language)
}

.canonical_referendum2003 <- function(level) {
  path <- getOption('swelections.canonical_manifest', NULL)
  if (!is.null(names(path)) && '2003' %in% names(path)) path <- unname(path[['2003']])
  if (!is.character(path) || length(path) != 1L || !file.exists(path))
    stop('2003 canonical data require an explicitly configured local manifest.', call. = FALSE)
  manifest <- .canonical_manifest(path)
  if (!identical(manifest$valserie, 'folkomr') || !identical(as.integer(manifest$valar), 2003L) ||
      !identical(as.integer(manifest$schema_version), 2L) || !identical(manifest$format, 'parquet'))
    stop('Expected final referendum 2003 English Parquet schema version 2.', call. = FALSE)
  asset <- 'referendum2003-results-final'
  entry <- manifest$assets[manifest$assets$asset == asset, , drop = FALSE]
  if (nrow(entry) != 1L) stop('Missing referendum results asset.', call. = FALSE)
  directory <- getOption('swelections.canonical_assets_dir', dirname(path))
  file <- normalizePath(file.path(directory, entry$file), winslash = '/', mustWork = TRUE)
  data <- .canonical_asset(manifest, asset, getOption('swelections.canonical_cache_dir', NULL), paste0('file:///', file))
  .canonical_table(manifest, data, asset, level)
}
