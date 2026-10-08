# Independent preserved SKV/HTML checks against the unpublished Parquet build.
# Rscript development/validate_official_totals_2014.R RAW_ROOT ASSETS_DIR REPORT
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(3L, 4L)) stop("Specify RAW_ROOT ASSETS_DIR REPORT [ELECTION].")
pkgload::load_all(".", quiet = TRUE)
root <- file.path(args[[1]], "2014", "valresultat")
report <- list(skv = list(), preliminary = list(), differences = list())
save_report <- function() jsonlite::write_json(report, args[[3]], pretty = TRUE,
  auto_unbox = TRUE, na = "null")
read_skv <- function(file) {
  header <- strsplit(readLines(file, n = 1L, encoding = "latin1"), ";", fixed = TRUE)[[1]]
  x <- utils::read.table(file, skip = 1L, header = FALSE, sep = ";", quote = "",
    comment.char = "", fill = TRUE, colClasses = "character", fileEncoding = "latin1")
  x <- x[seq_along(header)]; names(x) <- header; x
}
snapshot <- list.dirs(root, recursive = FALSE)
snapshot <- snapshot[grepl("preliminary-presentation-", basename(snapshot))]
sources <- jsonlite::fromJSON(file.path(snapshot, "source-manifest.json"))$sources
for (v in if (length(args) == 4L) args[[4]] else c("RD", "RF", "KF")) {
  final <- nanoparquet::read_parquet(file.path(args[[2]],
    paste0("rkl2014-results-slutlig-", tolower(v), ".parquet")))
  for (scope in c("kommun", "valdistrikt")) {
  municipal <- final[final$.table == scope, ]
  file <- file.path(root, paste0("2014_", switch(v, RD = "riksdagsval",
    RF = "landstingsval", KF = "kommunval"), "_per_", scope, ".skv"))
  skv <- read_skv(file)
  # First two columns are official county and municipal suffix codes.
  code <- paste0(sprintf("%02d", as.integer(skv[[1]])),
    sprintf("%02d", as.integer(skv[[2]])))
  key <- if (scope == "kommun") "municipality_code" else "district_code"
  if (scope == "valdistrikt") {
    district_number <- as.integer(skv[[if (v == "RD") 4L else 3L]])
    # Uppsala also has ordinary districts numbered 1--3. The official SKV
    # district-type label distinguishes these from collection districts.
    district_label <- skv[[if (v == "RD") 8L else 6L]]
    collection <- grepl("Uppsamlingsdistrikt", district_label, fixed = TRUE)
    code <- ifelse(collection, paste(c(RD = "R", RF = "L", KF = "K")[[v]],
      code, sprintf("%02d", district_number), sep = "-"),
      paste0(code, sprintf("%04d", district_number)))
  }
  stopifnot(length(code) == nrow(skv), !anyNA(code), !anyDuplicated(code))
  totals <- municipal[!duplicated(municipal[[key]]), ]
  comparisons <- 0L
  for (pair in list(c("Rost Giltiga", "valid_votes"), c("Rostande", "total_votes"))) {
    observed <- as.integer(skv[[pair[[1]]]])
    expected <- totals[[pair[[2]]]][match(code, totals[[key]])]
    bad <- which(is.na(expected) | observed != expected)
    if (length(bad)) report$differences[[paste(v, scope, pair[[1]])]] <-
      data.frame(code = code[bad], skv = observed[bad], canonical = expected[bad])
    comparisons <- comparisons + length(observed)
  }
  for (alias in c("M", "C", "FP", "KD", "S", "V", "MP", "SD", "FI")) {
    column <- paste(alias, "tal")
    if (!column %in% names(skv)) next
    party <- municipal[municipal$party_abbreviation == alias & !is.na(municipal$party_abbreviation), ]
    if (anyDuplicated(party[[key]])) stop("Nonunique official party alias.")
    expected <- party$votes[match(code, party[[key]])]
    observed <- as.integer(skv[[column]])
    # An absent zero-vote party is not an artificial canonical party row.
    expected[is.na(expected) & observed == 0L] <- 0L
    bad <- which(!is.na(observed) & (is.na(expected) | observed != expected))
    if (length(bad)) report$differences[[paste(v, scope, alias)]] <-
      data.frame(code = code[bad], skv = observed[bad], canonical = expected[bad])
    comparisons <- comparisons + sum(!is.na(observed))
  }
  report$skv[[paste(v, scope)]] <- list(file = file, md5 = unname(tools::md5sum(file)),
    units = length(code), comparisons = comparisons)
  }
  preliminary <- nanoparquet::read_parquet(file.path(args[[2]],
    paste0("rkl2014-results-preliminar-", tolower(v), ".parquet")))
  selected <- sources[sources$role %in% c("national", "aggregate_validation",
    "constituency_validation") & grepl(paste0("/prelresultat/",
      c(RD = "R", RF = "L", KF = "K")[[v]], "/"), sources$url, fixed = TRUE), ]
  checked <- skipped <- 0L; party_checks <- total_checks <- 0L
  for (i in seq_len(nrow(selected))) {
    url <- selected$url[[i]]
    tail <- sub(".*/prelresultat/[RLK]/", "", url)
    tokens <- strsplit(tail, "/", fixed = TRUE)[[1]]
    table <- switch(tokens[[1]], rike = "riket", kommun = "kommun", lan = if (v == "RF") "region" else "lan",
      landsting = "region", rvalkrets = "riksdagsvalkrets", lvalkrets = "regionvalkrets",
      kvalkrets = "kommunvalkrets", NULL)
    x <- if (is.null(table)) preliminary[FALSE, ] else preliminary[preliminary$.table == table, ]
    if (is.null(table)) { skipped <- skipped + 1L; next }
    if (table %in% c("kommun", "kommunvalkrets")) {
      x <- x[which(x$municipality_code == paste0(tokens[[2]], tokens[[3]])), ]
      if (table == "kommunvalkrets") x <- x[which(x$municipal_constituency_code ==
        paste0(tokens[[2]], tokens[[3]], tokens[[4]])), ]
    } else if (table %in% c("region", "lan")) {
      code <- if (table == "region") x$electoral_area_code else x$county_code
      x <- x[which(code == tokens[[2]]), ]
    } else if (table == "riksdagsvalkrets") x <- x[which(substr(x$constituency_code, 3L, 4L) == tokens[[2]]), ] else
      if (table == "regionvalkrets") x <- x[which(x$constituency_code == paste0(tokens[[2]], tokens[[3]])), ]
    if (!nrow(x)) { skipped <- skipped + 1L; next }
    file <- file.path(snapshot, gsub("\\", "/", selected$file[[i]], fixed = TRUE))
    stopifnot(identical(unname(tools::md5sum(file)), selected$md5[[i]]))
    html <- xml2::read_html(file, options = "NONET")
    rows <- lapply(xml2::xml_find_all(html,
      "//table[contains(@class,'sorteringsbar_tabell')]//tr"), function(r)
      trimws(xml2::xml_text(xml2::xml_find_all(r, "./td"))))
    rows <- rows[lengths(rows) == 8L]
    rows <- rows[vapply(rows, function(r) grepl("^[0-9]+$", r[[3]]), logical(1))]
    for (r in rows) {
      count <- as.integer(r[[3]])
      if (r[[2]] == "Giltiga r\u00f6ster") {
        observed <- sum(x$votes); total_checks <- total_checks + 1L
      } else if (r[[1]] == "VDT") {
        observed <- unique(x$total_votes)
        if (length(observed) != 1L) stop("Nonunique geographic vote total.")
        total_checks <- total_checks + 1L
      } else if (grepl("r\u00f6stber\u00e4ttigade", r[[2]], fixed = TRUE)) next else
        if (r[[1]] %in% c("BLANK", "OG", "\u00d6VR", "\u00d6VRIGA")) next else {
        p <- x[x$party_abbreviation == r[[1]] & !is.na(x$party_abbreviation), ]
        if (!nrow(p) && count != 0L) {
          report$differences[[paste(url, r[[1]])]] <- list(html = count, canonical = NA)
          next
        }
        observed <- sum(p$votes); party_checks <- party_checks + 1L
      }
      if (observed != count) report$differences[[paste(url, r[[1]])]] <-
        list(html = count, canonical = observed)
    }
    checked <- checked + 1L
  }
  report$preliminary[[v]] <- list(pages_checked = checked, pages_not_mapped = skipped,
    party_comparisons = party_checks, valid_total_comparisons = total_checks)
  save_report()
  cat("Independent totals completed", v, "\n"); flush.console()
}
save_report()
cat("Differences:", length(report$differences), "\n")
