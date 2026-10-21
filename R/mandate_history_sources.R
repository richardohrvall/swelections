
# Membership source routing is distinct from fixed election-result routing.
.mh_remote_files <- function(year) {
  if (year != 2022L)
    stop("Remote mandate history is supported for 2022 only; select canonical or explicit local sources.", call. = FALSE)
  filenames <- c(history = "ledamoter_med_historik.csv",
    current = "nuvarande_ledamoter.csv", departures = "avgangna_ledamoter.csv",
    vacancies = "tomma_stolar.csv")
  directory <- tempfile("swelections-membership-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  # Fetch a fresh set sequentially on each request; never select user raw archives.
  lapply(stats::setNames(names(filenames), names(filenames)), function(role) {
    url <- paste0("https://resultat.val.se/filer/val2022/info/", filenames[[role]])
    file <- file.path(directory, filenames[[role]])
    .download_file(url, file)
    x <- .mh_read(file, year)
    attr(x, "source_file") <- url
    x
  })
}

.mh_check_remote_current <- function(x, current) {
  at <- .mh_at(x, min(current$source_as_of))
  # Membership CSVs omit numeric party codes; the build resolves them against
  # original allocations. Compare the published abbreviation plus geography,
  # chair, event and candidate ID, with uniqueness checks; never match names.
  key <- function(z) paste(z$election_code, z$electoral_area_code, z$constituency,
    z$party_abbreviation, z$seat_number, z$event_date, sep = "/")
  expected <- key(current); actual <- key(at)
  i <- match(expected, actual)
  same <- !is.na(i) & ((is.na(current$candidate_number) & is.na(at$candidate_number[i])) |
    (!is.na(current$candidate_number) & !is.na(at$candidate_number[i]) &
       current$candidate_number == at$candidate_number[i]))
  if (anyDuplicated(expected) || anyDuplicated(actual) ||
      !setequal(expected, actual) || anyNA(same) || !all(same))
    stop("Remote history and current-member exports disagree; no local fallback or inferred holders are used. Retry after the official snapshots agree.",
         call. = FALSE)
  invisible(NULL)
}

.mh_canonical <- function(year, codes, auto_selected) {
  path <- .canonical_manifest_path(year, "rkl", auto_selected = auto_selected)
  manifest <- .canonical_manifest(path)
  .canonical_require_reader()
  asset <- paste0("rkl", year, "-mandate-history")
  if (!.canonical_view_covered(manifest, "mandate_history"))
    stop("No canonical mandate history in this manifest for ", year, ".", call. = FALSE)
  fetch <- .canonical_fetcher(manifest, path)
  x <- fetch(asset)
  layout <- manifest$tables$columns[manifest$tables$asset == asset &
    manifest$tables$table == "intervals"]
  if (length(layout) != 1L || !identical(names(x), strsplit(layout, ",", fixed = TRUE)[[1L]]) ||
      anyNA(x$election_year) || any(x$election_year != year) ||
      anyNA(x$status) || any(!x$status %in% c("occupied", "vacant")) ||
      anyNA(x$start_date) || anyNA(x$coverage_end) || anyDuplicated(x$interval_id) ||
      !all(vapply(x[c("start_date", "end_date", "event_date", "coverage_end")],
                  inherits, logical(1), "Date")))
    stop("Invalid canonical mandate-history schema or intervals.", call. = FALSE)
  x[x$election_code %in% codes, , drop = FALSE]
}


.mh_history <- function(year, election, data_dir, files, source, names, detail, surface) {
  if (length(year) != 1L || is.na(year) || !year %in% c(2014, 2018, 2022))
    stop("`year` must be 2014, 2018 or 2022.", call. = FALSE)
  source <- match.arg(source, c("auto", "canonical", "remote", "local"))
  language <- match.arg(names, c("en", "sv"))
  detail <- match.arg(detail, c("standard", "full"))
  codes <- .re_codes(election)
  if (any(!codes %in% c("RD", "RF", "KF"))) stop("Membership supports RD/RF/KF only.", call. = FALSE)
  if (!is.list(files)) stop("files must be a named list of local source paths.", call. = FALSE)
  if (length(files) && source != "local")
    stop("Select source = \"local\" explicitly to use files overrides.", call. = FALSE)
  if (source == "canonical" && !is.null(data_dir))
    stop("Canonical history uses manifest/cache options, not data_dir.", call. = FALSE)
  selected <- .select_public_source(source, year, surface, val = codes)
  if (selected %in% c("canonical", "canonical_auto")) {
    out <- .mh_canonical(year, codes, selected == "canonical_auto")
    return(.mh_present(out, language, detail))
  }
  if (selected == "auto") {
    if (year != 2022L) .auto_requires_local("auto", paste0("mandate history ", year))
    selected <- "remote"
  }
  if (selected == "remote") {
    raw <- .mh_remote_files(year)
    # Fixed original allocations are immutable election results; auto selects
    # their approved canonical route, independently of live membership exports.
    original <- .mh_original(year, codes, NULL, "auto")
  } else {
    root <- val_data_dir(data_dir)
    if (is.null(root)) stop("Preserved local membership sources require data_dir.", call. = FALSE)
    if (dir.exists(file.path(root, "rkl"))) root <- file.path(root, "rkl")
    raw <- .mh_files(year, root, files)
    original <- .mh_original(year, codes, root, "local")
  }
  data <- lapply(names(raw), function(k) .mh_normalise(raw[[k]], k, year))
  names(data) <- names(raw)
  data <- lapply(data, function(x) if (is.null(x)) NULL else x[x$election_code %in% codes, ])
  out <- .mh_build(year, original$allocations, original$elected,
    data$history, data$current, data$departures, data$vacancies)
  if (selected == "remote") {
    .mh_check_remote_current(out, data$current)
    # A newer current-member/departure file cannot extend older history.
    out$coverage_end <- min(data$history$source_as_of, data$current$source_as_of)
  }
  .mh_present(out, language, detail)
}
