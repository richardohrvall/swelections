# Audited transcription of Valmyndigheten's byte-verified 2002 RD supplement.
# Apply only to result-reader documents, never candidate/mandate input documents.
.xml2002_supplement <- function() {
  path <- system.file('extdata', 'rd-2002-party-supplement.csv', package = 'swelections')
  provenance <- jsonlite::read_json(system.file('extdata', 'rd-2002-party-supplement-provenance.json', package = 'swelections'))
  if (!identical(.canonical_sha256(path), provenance$lookup_sha256))
    stop('Changed 2002 RD supplement lookup.', call. = FALSE)
  x <- utils::read.csv(path, colClasses = c('character', 'character', 'integer'))
  if (nrow(x) != 120L || anyDuplicated(x[c('area_code', 'party_alias')]) ||
      any(x$votes < 0L, na.rm = TRUE)) stop('Invalid 2002 RD supplement lookup.', call. = FALSE)
  x
}

.xml2002_supplement_values <- function(node, niva, lookup = .xml2002_supplement(), constituency = NULL) {
  if (niva == 'riket') return(lookup[lookup$area_code == '00', ])
  if (niva == 'riksdagsvalkrets')
    return(lookup[lookup$area_code == .xml2018_attr(node, 'KOD'), ])
  if (niva %in% c('kommun', 'kommunvalkrets', 'valdistrikt')) {
    if (is.null(constituency) || is.na(constituency)) return(NULL)
    x <- lookup[lookup$area_code == constituency & !is.na(lookup$votes) & lookup$votes == 0L, ]
    observed <- xml2::xml_attr(xml2::xml_find_all(node, './GILTIGA|./GILTIGA/VARAV_\u00d6VRIGA'), 'PARTI')
    x <- x[x$party_alias %in% observed, ]
    return(if (nrow(x)) x else NULL)
  }
  if (niva != 'lan') return(NULL)
  codes <- xml2::xml_attr(xml2::xml_find_all(node, './KRETS_RIKSDAG'), 'KOD')
  if (!length(codes)) stop('Missing constituency coverage for 2002 county supplement.', call. = FALSE)
  x <- lookup[lookup$area_code %in% codes, ]
  parties <- c('0421', 'ND', 'NYD', 'Pop')
  if (nrow(x) != length(codes) * 4L)
    stop('Incomplete constituency coverage for 2002 county supplement.', call. = FALSE)
  data.frame(area_code = .xml2018_attr(node, 'KOD'), party_alias = parties,
    votes = vapply(parties, function(p) {
      counts <- x$votes[x$party_alias == p]
      if (anyNA(counts)) NA_integer_ else as.integer(sum(as.double(counts)))
    }, integer(1)))
}

.xml2002_apply_supplement <- function(node, niva, constituency = NULL) {
  values <- .xml2002_supplement_values(node, niva, constituency = constituency)
  if (is.null(values)) return(invisible(NULL))
  if (!nrow(values) || nrow(values) > 4L) stop('Missing 2002 supplement geography.', call. = FALSE)
  other <- xml2::xml_find_first(node, './GILTIGA[@PARTI="\u00d6VR"]')
  if (inherits(other, 'xml_missing')) stop('Missing 2002 other-party source total.', call. = FALSE)
  aliases <- values$party_alias
  direct <- xml2::xml_find_all(node, './GILTIGA')
  direct <- direct[xml2::xml_attr(direct, 'PARTI') %in% aliases]
  old_direct <- as.integer(xml2::xml_attr(direct, 'R\u00d6STER'))
  if (anyNA(old_direct)) stop('Unknown original direct supplement-party counts.', call. = FALSE)
  total <- .xml2018_int(other, 'R\u00d6STER') + sum(as.double(old_direct))
  details <- xml2::xml_find_all(other, './VARAV_\u00d6VRIGA')
  retained <- details[!xml2::xml_attr(details, 'PARTI') %in% c(aliases, '\u00d6VR')]
  counts <- as.integer(xml2::xml_attr(retained, 'R\u00d6STER'))
  residual <- total - sum(as.double(counts)) - sum(as.double(values$votes), na.rm = TRUE)
  if (is.na(residual) || residual < 0)
    stop('2002 supplement exceeds the official other-party total.', call. = FALSE)
  # Rebuild only the in-memory partition. Undisclosed parties remain inside its
  # numerical residual, with separate NA rows to make incomplete detail explicit.
  xml2::xml_remove(direct)
  remove <- details[xml2::xml_attr(details, 'PARTI') %in% c(aliases, '\u00d6VR')]
  xml2::xml_remove(remove)
  xml2::xml_set_attr(other, 'R\u00d6STER', as.character(total))
  for (i in seq_len(nrow(values))) {
    known <- !is.na(values$votes[[i]])
    child <- xml2::xml_add_child(if (known) other else node,
      if (known) 'VARAV_\u00d6VRIGA' else 'GILTIGA')
    xml2::xml_set_attr(child, 'PARTI', aliases[[i]])
    if (known) xml2::xml_set_attr(child, 'R\u00d6STER', as.character(values$votes[[i]]))
  }
  child <- xml2::xml_add_child(other, 'VARAV_\u00d6VRIGA')
  xml2::xml_set_attr(child, 'PARTI', '\u00d6VR')
  xml2::xml_set_attr(child, 'R\u00d6STER', as.character(as.integer(residual)))
  invisible(NULL)
}
