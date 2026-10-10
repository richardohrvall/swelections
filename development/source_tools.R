# Independent development I/O; no package normalisers.
audit_bytes <- function(path) readBin(path, "raw", file.info(path)$size)
audit_hash <- function(path, algorithm = "sha256") digest::digest(file = path, algo = algorithm)
audit_json <- function(path) jsonlite::read_json(path, simplifyVector = FALSE)
audit_write <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(value, path, pretty = TRUE, auto_unbox = TRUE, null = "null", na = "null")
}
audit_zip <- function(path, member) {
  catalog <- utils::unzip(path, list = TRUE)
  size <- catalog$Length[catalog$Name == member]; stopifnot(length(size) == 1L)
  con <- unz(path, member, open = "rb"); on.exit(close(con)); readBin(con, "raw", size)
}
audit_xml <- function(path, member) xml2::read_xml(audit_zip(path, member), options = "NONET")
audit_number <- function(x) {
  x <- gsub("[[:space:]\u00a0]", "", x)
  if (length(x) != 1L || is.na(x) || !grepl("^[0-9]+$", x)) return(NA_integer_)
  as.integer(x)
}
audit_rows <- function(doc) lapply(xml2::xml_find_all(doc,
  "//table[contains(@class,'sorteringsbar_tabell')]//tr"),
  function(row) trimws(xml2::xml_text(xml2::xml_find_all(row, "./td"))))
audit_counter <- function() setNames(numeric(), character())
audit_add <- function(x, key, value) {
  if (!length(value) || is.na(value)) return(x)
  if (is.environment(x)) {
    x[[key]] <- if (exists(key, x, inherits = FALSE)) x[[key]] + value else value
    return(x)
  }
  if (!key %in% names(x)) x[[key]] <- 0
  x[[key]] <- x[[key]] + value; x
}
audit_sum <- function(x, y) { for (key in names(y)) x <- audit_add(x, key, y[[key]]); x }
audit_get <- function(x, key) if (key %in% names(x)) x[[key]] else 0
audit_tuple <- function(values) as.character(jsonlite::toJSON(unname(values), auto_unbox = TRUE, null = "null"))
audit_multiset <- function(rows) sort(vapply(rows, audit_tuple, ""), method = "radix")
audit_pin <- function(path, bytes, md5, sha256) stopifnot(file.info(path)$size == bytes,
  audit_hash(path, "md5") == md5, audit_hash(path) == sha256)
audit_json_equal <- function(x, y) {
  normalise <- function(x) {
    if (is.list(x)) {
      if (!is.null(names(x))) x <- x[order(names(x), method = "radix")]
      x <- lapply(x, normalise)
    }
    x
  }
  isTRUE(all.equal(normalise(x), normalise(y), tolerance = 0))
}
