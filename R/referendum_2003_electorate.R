# Three disjoint electorate groups, published by SCB for counties and Sweden.
.referendum2003_electorate_fields <- c(
  'antal_rostberattigade_svenska_i_sverige',
  'antal_rostberattigade_svenska_utomlands',
  'antal_rostberattigade_utlandska'
)
.referendum2003_electorate_url <- paste0(
  'https://www.scb.se/hitta-statistik/statistik-efter-amne/demokrati/',
  'allmanna-val/folkomrostningar-valresultat/pong/tabell-och-diagram/',
  'ovriga-folkomrostningar/rostberattigade-vid-folkomrostningen-om-euron-2003/'
)
.referendum2003_electorate_table <- function(doc) {
  tables <- xml2::xml_find_all(doc, '//table')
  selected <- tables[vapply(tables, function(t) {
    text <- gsub('[[:space:]\u00a0-]', '', xml2::xml_text(t))
    grepl('Utlandssvenskar', text, fixed = TRUE) && grepl('Utl', text, fixed = TRUE)
  }, logical(1))]
  if (length(selected) != 1L) stop('Missing or ambiguous SCB electorate table.', call. = FALSE)
  header <- xml2::xml_find_all(selected, './/tr')
  headers <- lapply(header, function(tr)
    gsub('[[:space:]\u00a0-]', '', xml2::xml_text(xml2::xml_find_all(tr, './th|./td'))))
  expected <- c('Svenskamedborgare', 'Utlandssvenskar', 'Utl\u00e4ndskamedborgare')
  if (!any(vapply(headers, function(h) length(h) == 6L && identical(h[3:5], expected), logical(1))))
    stop('Unexpected SCB electorate column definitions/order.', call. = FALSE)
  rows <- lapply(xml2::xml_find_all(selected, './/tr'), function(tr)
    trimws(xml2::xml_text(xml2::xml_find_all(tr, './td'))))
  rows <- Filter(function(z) length(z) == 6L &&
    grepl('^[0-9]+$' , gsub('[[:space:]\u00a0]', '', z[2])), rows)
  if (length(rows) != 22L) stop('Incomplete SCB county/national electorate coverage.', call. = FALSE)
  number <- function(value) {
    value <- gsub('[[:space:]\u00a0]', '', value)
    if (!grepl('^[0-9]+$', value) || as.double(value) > .Machine$integer.max)
      stop('Invalid SCB electorate count.', call. = FALSE)
    as.integer(value)
  }
  out <- purrr::list_rbind(lapply(rows, function(z) tibble::tibble(
    source_area_name = z[1], first_time = number(z[2]),
    domestic = number(z[3]), abroad = number(z[4]), foreign = number(z[5]), total = number(z[6])
  )))
  if (anyDuplicated(out$source_area_name) || sum(out$source_area_name == 'HELA RIKET') != 1L ||
      any(out$domestic + out$abroad + out$foreign != out$total))
    stop('SCB electorate groups do not reconcile.', call. = FALSE)
  national <- out[out$source_area_name == 'HELA RIKET', ]
  county <- out[out$source_area_name != 'HELA RIKET', ]
  fields <- c('domestic', 'abroad', 'foreign', 'total')
  if (any(colSums(county[fields]) != unlist(national[fields])))
    stop('SCB county electorate sums do not match Sweden.', call. = FALSE)
  out
}
.referendum2003_enrich_electorate <- function(data, source, root, level) {
  if (!level %in% c('riket', 'lan')) return(data)
  file <- file.path(root, 'scb-electorate-composition.html')
  if (source == 'local') {
    # A raw archive without this independent supplement retains typed missingness.
    if (!file.exists(file)) return(data)
    provenance <- paste0(file, '.provenance.json')
    if (!file.exists(provenance)) stop('SCB electorate provenance is missing.', call. = FALSE)
    p <- jsonlite::read_json(provenance, simplifyVector = TRUE)
    if (!identical(p$url, .referendum2003_electorate_url) || file.info(file)$size != p$size ||
        unname(tools::md5sum(file)) != p$md5 || .canonical_sha256(file) != p$sha256)
      stop('SCB electorate source size/checksum or URL changed.', call. = FALSE)
  } else {
    file <- tempfile(fileext = '.html')
    on.exit(unlink(file), add = TRUE)
    .download_file(.referendum2003_electorate_url, file)
  }
  table <- .referendum2003_electorate_table(xml2::read_html(file))
  key <- if (level == 'riket') rep('HELA RIKET', nrow(data)) else toupper(data$lannamn)
  index <- match(key, table$source_area_name)
  if (anyNA(index) || any(table$total[index] != data$antal_rostberattigade) ||
      (level == 'lan' && !setequal(unique(key), table$source_area_name[table$source_area_name != 'HELA RIKET'])))
    stop('SCB electorate does not match Valmyndigheten areas/totals.', call. = FALSE)
  for (i in seq_along(.referendum2003_electorate_fields))
    data[[.referendum2003_electorate_fields[i]]] <- table[[c('domestic', 'abroad', 'foreign')[i]]][index]
  data
}
