# Membership is a separate layer: none of these readers changes election results.
.mh_election_date <- function(year) {
  dates <- c(`2002`="2002-09-15", `2010`="2010-09-19", `2014`="2014-09-14",
    `2018`="2018-09-09", `2022`="2022-09-11")
  if (!as.character(year) %in% names(dates)) stop("Unknown original election date.", call. = FALSE)
  as.Date(unname(dates[as.character(year)]))
}

# A replacement affects a geographic component, never implicitly its parent area.
.mh_component_hit <- function(x, event) {
  hit <- x$election_code == event$election_code[[1L]] &
    x$electoral_area_code == event$electoral_area_code[[1L]]
  level <- event$scope_level[[1L]]
  if (level %in% c("municipal_constituency", "regional_constituency", "parliamentary_constituency")) {
    if (any(hit & (is.na(x$constituency) | !nzchar(x$constituency))))
      stop("Missing constituency for partial replacement scope.", call. = FALSE)
    hit <- hit & x$constituency == event$scope_code[[1L]]
  } else if (!level %in% c("municipality", "region"))
    stop("Unsupported mandate replacement scope.", call. = FALSE)
  hit[is.na(hit)] <- FALSE
  hit
}

.mh_date <- function(x) {
  out <- suppressWarnings(as.Date(substr(x, 1L, 10L), format = "%Y-%m-%d"))
  if (any(!is.na(x) & is.na(out))) stop("Invalid mandate-history date.", call. = FALSE)
  out
}

.mh_read <- function(file, year) {
  if (is.null(file)) return(NULL)
  if (!file.exists(file)) stop("Missing mandate-history source: ", file, call. = FALSE)
  first <- readLines(file, n = 1L, warn = FALSE)
  stamp <- regmatches(first, regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", first))
  if (!length(stamp) || !nzchar(stamp)) stop("Missing source snapshot date: ", file, call. = FALSE)
  # Read the file, not I(rawToChar(response)): CR-only exports can lose the last row.
  x <- readr::read_delim(file, delim = ";", skip = 1L,
    locale = readr::locale(encoding = if (year == 2022L) "UTF-8" else "ISO-8859-1"),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE, progress = FALSE, name_repair = "check_unique")
  attr(x, "source_file") <- normalizePath(file, winslash = "/")
  attr(x, "source_md5") <- unname(tools::md5sum(file))
  attr(x, "source_as_of") <- as.Date(stamp)
  x
}

.mh_files <- function(year, root, files) {
  folder <- file.path(root, year, "kandidater")
  patterns <- c(history = "^ledamoter_med_historik.*[.](csv|skv)$",
    current = "^nuvarande_ledamoter.*[.](csv|skv)$",
    departures = "^avgangna_ledamoter.*[.](csv|skv)$",
    vacancies = "^(tommastolar|tomma_stolar).*[.](csv|skv)$")
  if (!is.list(files) || (length(files) && (is.null(names(files)) ||
      anyNA(names(files)) || any(!nzchar(names(files))) || anyDuplicated(names(files)))) ||
      length(setdiff(names(files), names(patterns))))
    stop("`files` must be a named list of history/current/departures/vacancies paths.", call. = FALSE)
  out <- lapply(names(patterns), function(k) {
    if (!is.null(files[[k]])) return(.mh_read(files[[k]], year))
    paths <- list.files(folder, patterns[[k]], full.names = TRUE)
    if (!length(paths)) return(NULL)
    data <- lapply(paths, .mh_read, year = year)
    dates <- vapply(data, function(x) as.numeric(attr(x, "source_as_of")), numeric(1))
    latest <- which(dates == max(dates))
    if (length(latest) > 1L && length(unique(vapply(data[latest],
        function(x) attr(x, "source_md5"), character(1)))) > 1L)
      stop("Conflicting equally dated mandate-history snapshots; select `files` explicitly.", call. = FALSE)
    data[[latest[[1L]]]]
  })
  stats::setNames(out, names(patterns))
}

.mh_col <- function(x, candidates) {
  n <- intersect(candidates, names(x))
  if (length(n)) x[[n[[1L]]]] else rep(NA_character_, nrow(x))
}

.mh_normalise <- function(x, kind, year) {
  if (is.null(x)) return(NULL)
  col <- function(...) .mh_col(x, c(...))
  type <- col("Valtyp")
  type <- dplyr::recode(type, R = "RD", L = "RF", K = "KF", .default = type)
  county <- col("L\u00e4nskod", "L\u00e4nsnummer")
  mun <- col("Kommunkod", "Kommunnummer")
  const <- col("Valkretskod", "Valkretsnummer")
  county <- stringr::str_pad(county, 2L, pad = "0")
  mun <- stringr::str_pad(mun, 2L, pad = "0")
  const <- stringr::str_pad(const, 2L, pad = "0")
  area <- ifelse(type == "RD", "00", ifelse(type == "RF", county, paste0(county, mun)))
  const <- ifelse(is.na(const) | const == "00", "", ifelse(type == "RD", const,
    paste0(area, const)))
  event <- col("Valtillf\u00e4lle")
  rerun <- grepl("omval", event, ignore.case = TRUE)
  dates <- stats::setNames(as.character(.mh_election_date(year)), as.character(year))
  event_date <- rep(unname(dates[as.character(year)]), nrow(x))
  events <- .re_elections()
  labels <- tolower(gsub("[^A-Za-z0-9]", "", event))
  allowed <- c(paste0("val", year), paste0("val", gsub("-", "", dates[as.character(year)])))
  for (j in which(events$original_year == year)) allowed <- c(allowed,
    paste0("omval", events$election_year[[j]]),
    paste0("omval", gsub("-", "", events$election_date[[j]])))
  if (anyNA(labels) || any(!labels %in% allowed))
    stop("Membership source belongs to a different or unknown election period.", call. = FALSE)
  for (i in which(events$original_year == year)) {
    hit <- rep(FALSE, nrow(x))
    rows <- which(rerun & labels %in% c(paste0("omval", events$election_year[[i]]),
      paste0("omval", gsub("-", "", events$election_date[[i]]))))
    hit[rows] <- .mh_component_hit(data.frame(election_code = type[rows],
      electoral_area_code = area[rows], constituency = const[rows]), events[i, ])
    event_date[hit] <- as.character(events$election_date[[i]])
  }
  if (any(rerun & event_date == dates[as.character(year)]))
    stop("Unrecognised re-election in membership source.", call. = FALSE)
  first <- col("Ledamot f\u00f6rnamn", "F\u00f6rnamn", "Avg\u00e5ngen ledamot f\u00f6rnamn")
  last <- col("Ledamot efternamn", "Efternamn", "Avg\u00e5ngen ledamot efternamn")
  name <- ifelse(is.na(first) & is.na(last), NA_character_,
    trimws(paste(ifelse(is.na(first), "", first), ifelse(is.na(last), "", last))))
  candidate <- col("Kandidatnummer ledamot", "Kandnr", "Avg\u00e5ngen ledamot kandidatnummer")
  out <- tibble::tibble(election_code = type, electoral_area_code = area,
    constituency = const, party_code = col("Partikod", "Partinummer"),
    party_abbreviation = col("Partif\u00f6rkortning"),
    party_designation = col("Partibeteckning", "Partibetecking"),
    seat_number = suppressWarnings(as.integer(col("Mandat (invalsordning)", "Mandat (stol)"))),
    candidate_number = candidate, name = name,
    start_date = .mh_date(col("Invalsdatum", "Tilltr\u00e4desdatum", "Tilltr\u00e4desdatum/valdag")),
    end_date = .mh_date(col("Avg\u00e5ngsdatum")),
    successor_number = col("Eftertr\u00e4dare kandidatnr", "Eftertr\u00e4dare kandidatnummer"),
    event_date = as.Date(event_date), election_kind = ifelse(rerun, "re_election", "ordinary"),
    source_file = attr(x, "source_file"), source_md5 = attr(x, "source_md5"),
    source_as_of = attr(x, "source_as_of"), source_row = seq_len(nrow(x)),
    source_kind = kind)
  if (kind == "vacancies") out$vacancy_count <- as.integer(col("Antal tomma stolar"))
  out
}

.mh_geo <- function(x) {
  if (!"municipal_constituency_code" %in% names(x)) x$municipal_constituency_code <- NA_character_
  co <- dplyr::coalesce(x$municipal_constituency_code, x$constituency_code, "")
  rd <- x$election_code == "RD"
  co[rd] <- substring(co[rd], pmax(1L, nchar(co[rd]) - 1L))
  co[x$election_code != "RD" & grepl("00$", co)] <- ""
  co
}

.mh_original <- function(year, codes, root, source) {
  s <- seats(year = year, election = codes, source = source,
    data_dir = if (source == "local") root else NULL, detail = "full", progress = FALSE)
  if (source == "local" && year %in% c(2014L, 2018L)) {
    raw <- if (year == 2014L) .xml2014_relations(
      .sources_2014("local", root), codes)$valda else
        .xml2018_valda_ersattare(codes, "local", root, FALSE, FALSE, FALSE)$valda
    e <- tibble::tibble(election_code = raw$valtyp,
      elected_electoral_area_code = raw$valomradeskod,
      elected_constituency_code = raw$valkretskod,
      party_code = raw$partikod, party_abbreviation = raw$partiforkortning,
      candidate_number = raw$kandidatnummer, order_of_election = raw$invalsordning,
      name = raw$namn)
  } else e <- elected(year = year, election = codes, source = source,
    data_dir = if (source == "local") root else NULL, detail = "full", progress = FALSE)
  if ("elected_municipal_constituency_code" %in% names(e))
    e$elected_constituency_code <- dplyr::coalesce(
      e$elected_municipal_constituency_code, e$elected_constituency_code)
  sub <- s[s$geographic_level %in% c("parliamentary_constituency", "regional_constituency", "municipal_constituency"), ]
  whole <- s[(s$election_code == "RF" & s$geographic_level == "region") |
    (s$election_code == "KF" & s$geographic_level == "municipality"), ]
  whole <- dplyr::anti_join(whole, sub, by = c("election_code", "electoral_area_code"))
  s <- dplyr::bind_rows(sub, whole)
  s$constituency <- .mh_geo(s)
  e$constituency <- dplyr::coalesce(e$elected_constituency_code, "")
  rd <- e$election_code == "RD"
  e$constituency[rd] <- substring(e$constituency[rd], pmax(1L, nchar(e$constituency[rd]) - 1L))
  list(allocations = dplyr::transmute(s, election_code = .data$election_code,
    electoral_area_code = .data$electoral_area_code, constituency = .data$constituency,
    party_code = .data$party_code, party_abbreviation = .data$party_abbreviation,
    seats = as.integer(.data$seats)),
    elected = dplyr::transmute(e, election_code = .data$election_code,
      electoral_area_code = .data$elected_electoral_area_code,
      constituency = .data$constituency, party_code = .data$party_code,
      party_abbreviation = .data$party_abbreviation,
      seat_number = as.integer(.data$order_of_election),
      candidate_number = .data$candidate_number, name = .data$name))
}

.mh_scope <- function(x) paste(x$election_code, x$electoral_area_code,
  x$constituency, dplyr::coalesce(x$party_code, x$party_abbreviation), sep = ":")
.mh_key <- function(x) paste(.mh_scope(x), x$seat_number, sep = ":")

# This core takes independent allocation/elected/source tables, enabling tests
# of chains and vacancies without network requests or raw archive dependencies.
.mh_build <- function(year, allocations, original, history, current, departures, vacancies) {
  date <- .mh_election_date(year)
  a <- allocations[allocations$seats > 0L, ]
  party_reference <- a
  if (!is.null(history)) party_reference <- dplyr::bind_rows(party_reference,
    history[!is.na(history$party_code), intersect(names(a), names(history)), drop = FALSE])
  fill_party <- function(x) {
    if (is.null(x)) return(NULL)
    for (i in which(is.na(x$party_code))) {
      hit <- party_reference$election_code == x$election_code[[i]] &
        party_reference$electoral_area_code == x$electoral_area_code[[i]] &
        party_reference$party_abbreviation == x$party_abbreviation[[i]]
      codes <- unique(stats::na.omit(party_reference$party_code[which(hit)]))
      if (length(codes) != 1L && !is.na(x$candidate_number[[i]])) {
        ref <- dplyr::bind_rows(original, history)
        hit <- ref$election_code == x$election_code[[i]] &
          ref$electoral_area_code == x$electoral_area_code[[i]] &
          ref$candidate_number == x$candidate_number[[i]]
        codes <- unique(stats::na.omit(ref$party_code[which(hit)]))
      }
      if (length(codes) != 1L) stop("Party cannot be linked to original allocation.", call. = FALSE)
      x$party_code[[i]] <- codes[[1L]]
    }
    x
  }
  original <- fill_party(original); history <- fill_party(history)
  current <- fill_party(current); departures <- fill_party(departures)
  vacancies <- fill_party(vacancies)
  if (anyNA(a$seats) || any(a$seats < 0L) || anyDuplicated(.mh_scope(a)))
    stop("Invalid or duplicate original mandate allocations.", call. = FALSE)
  slots <- a[rep(seq_len(nrow(a)), a$seats), , drop = FALSE]
  slots$seat_number <- sequence(a$seats)
  slots$key <- .mh_key(slots)
  original$key <- .mh_key(original)
  if (anyDuplicated(original$key) || any(!original$key %in% slots$key))
    stop("Original elected records disagree with allocated chairs.", call. = FALSE)
  if (is.null(current)) stop("A current-member snapshot is required.", call. = FALSE)
  observed <- if (is.null(history)) current else history
  if (!is.null(departures) && is.null(history)) {
    # 2014 has separate current/departure tables; successor edges assign chairs.
    observed <- dplyr::bind_rows(departures, current)
    seeds <- original
    seeds$event_date <- date
    # Current records carry source chair numbers, also for original-result
    # corrections not reflected in the older fixed XML snapshot.
    seeds <- dplyr::bind_rows(seeds, current)
    lookup_key <- function(x, id) paste(.mh_scope(x), x$event_date, id, sep = "/")
    forward <- split(seq_len(nrow(observed)), lookup_key(observed, observed$candidate_number))
    backward <- split(seq_len(nrow(observed)), lookup_key(observed, observed$successor_number))
    for (i in seq_len(nrow(seeds))) {
      seed <- seeds[i, ]
      queue <- seeds$candidate_number[[i]]
      seen <- character()
      while (length(queue)) {
        id <- queue[[1L]]; queue <- queue[-1L]
        if (is.na(id) || id %in% seen) next
        seen <- c(seen, id)
        key <- lookup_key(seed, id)
        hit <- forward[[key]]
        if (!length(hit)) next
        if (any(!is.na(observed$seat_number[hit]) & observed$seat_number[hit] != seeds$seat_number[[i]]))
          stop("Ambiguous successor-to-chair linkage.", call. = FALSE)
        observed$seat_number[hit] <- seeds$seat_number[[i]]
        next_ids <- unique(stats::na.omit(observed$successor_number[hit]))
        if (length(next_ids) > 1L) stop("Ambiguous successor chain.", call. = FALSE)
        previous <- backward[[key]]
        queue <- c(queue, next_ids, observed$candidate_number[previous])
      }
    }
    for (i in which(is.na(observed$seat_number))) {
      possible <- slots[.mh_scope(slots) == .mh_scope(observed[i, ]), ]
      if (nrow(possible) == 1L) observed$seat_number[[i]] <- possible$seat_number[[1L]]
    }
    if (anyNA(observed$seat_number))
      stop("Some 2014 membership records cannot be linked to an allocated chair: ",
        paste(utils::head(observed$candidate_number[is.na(observed$seat_number)], 8L), collapse = ", "), call. = FALSE)
  }
  observed$key <- .mh_key(observed)
  observed$interval_coverage <- "source_chain"
  if (!"reported_end_reason" %in% names(observed)) observed$reported_end_reason <- NA_character_
  observed$reported_start_date <- observed$start_date
  observed$reported_end_date <- observed$end_date
  observed$start_date_basis <- "reported"
  observed$correction_date <- as.Date(NA)
  observed$correction_reference <- NA_character_
  # Approved correction of the original result, never a December vacancy.
  ragunda <- year == 2018L & observed$election_code == "KF" &
    observed$electoral_area_code == "2303" & observed$party_abbreviation == "SD" &
    observed$seat_number == 3L & observed$candidate_number %in% "534885" &
    (is.na(observed$start_date) | observed$start_date == date)
  observed$start_date_basis[ragunda & is.na(observed$reported_start_date)] <- "corrected_original_elected"
  observed$start_date[ragunda] <- date
  observed$correction_date[ragunda] <- as.Date("2018-12-12")
  observed$correction_reference[ragunda] <- "Valprovningsnamnden 877-2018"
  for (i in which(is.na(observed$start_date))) {
    hit <- which(original$key == observed$key[[i]] &
      original$candidate_number == observed$candidate_number[[i]])
    if (length(hit) == 1L && observed$election_kind[[i]] == "ordinary") {
      observed$start_date[[i]] <- date
      observed$start_date_basis[[i]] <- "original_elected_match"
    } else if (is.na(observed$candidate_number[[i]]) &&
        observed$key[[i]] %in% setdiff(slots$key, original$key)) {
      observed$start_date[[i]] <- observed$event_date[[i]]
      observed$start_date_basis[[i]] <- "original_unfilled_allocation"
    } else stop("Unresolved membership start; no verified original-election match.", call. = FALSE)
  }
  observed$status <- ifelse(is.na(observed$candidate_number), "vacant", "occupied")
  observed$end_date_basis <- ifelse(is.na(observed$end_date), NA_character_, "reported")
  events <- .re_elections()
  # A rerun ends the old component even when surviving original members were
  # omitted from the later term export instead of recorded as departures.
  for (j in which(events$original_year == year)) {
    candidates <- original[.mh_component_hit(original, events[j, ]), ]
    for (i in seq_len(nrow(candidates))) {
      r <- candidates[i, ]
      if (any(observed$key == r$key & observed$candidate_number %in% r$candidate_number &
          observed$election_kind == "ordinary")) next
      z <- observed[NA_integer_, , drop = FALSE]
      for (col in intersect(names(r), names(z))) z[[col]] <- r[[col]]
      z$start_date <- date; z$end_date <- as.Date(events$election_date[[j]])
      z$event_date <- date; z$election_kind <- "ordinary"; z$status <- "occupied"
      z$interval_coverage <- "original_election_only"
      z$start_date_basis <- "original_elected_match"
      z$end_date_basis <- "re_election_replacement"
      z$source_kind <- "original_election"
      z$source_file <- "original final election result"
      z$source_as_of <- min(current$source_as_of)
      observed <- dplyr::bind_rows(observed, z)
    }
  }
  # The 2014 departure export contains terminal departures but no vacancy rows.
  # Create a vacancy only when no subsequent holder exists and an independent
  # vacancy snapshot is available to verify the resulting chair counts.
  if (is.null(history) && !is.null(vacancies)) {
    closes_component <- rep(FALSE, nrow(observed))
    for (j in which(events$original_year == year))
      closes_component <- closes_component | (.mh_component_hit(observed, events[j, ]) &
        observed$event_date < as.Date(events$election_date[[j]]) &
        observed$end_date %in% as.Date(events$election_date[[j]]))
    terminal <- which(!is.na(observed$end_date) & is.na(observed$successor_number) &
      !closes_component)
    additions <- list()
    for (i in terminal) {
      next_row <- observed$key == observed$key[[i]] &
        observed$event_date == observed$event_date[[i]] &
        observed$start_date >= observed$end_date[[i]]
      next_row[[i]] <- FALSE
      if (any(next_row)) next
      z <- observed[i, ]; z$candidate_number <- NA_character_; z$name <- NA_character_
      z$start_date <- z$end_date; z$end_date <- as.Date(NA)
      z$reported_start_date <- as.Date(NA)
      z$reported_end_date <- as.Date(NA)
      z$start_date_basis <- "departure_without_successor_verified_vacancy_control"
      z$end_date_basis <- NA_character_; z$status <- "vacant"
      additions[[length(additions) + 1L]] <- z
    }
    observed <- dplyr::bind_rows(observed, dplyr::bind_rows(additions))
  }
  # Later vacancies may be absent from history, but explicit in current members.
  empty <- current[is.na(current$candidate_number), , drop = FALSE]
  for (i in seq_len(nrow(empty))) {
    k <- .mh_key(empty[i, ])
    if (!any(observed$key == k & observed$event_date == empty$event_date[[i]] &
        observed$status == "vacant")) {
      z <- empty[i, ]; z$key <- k; z$reported_start_date <- z$start_date
      if (is.na(z$start_date)) {
        if (!k %in% setdiff(slots$key, original$key)) stop("Undated vacancy without allocation evidence.", call. = FALSE)
        z$start_date <- date; z$start_date_basis <- "original_unfilled_allocation"
      } else z$start_date_basis <- "reported"
      z$status <- "vacant"; z$end_date_basis <- NA_character_
      z$correction_date <- as.Date(NA); z$correction_reference <- NA_character_
      observed <- dplyr::bind_rows(observed, z)
    }
  }
  # Allocate initial vacancies even if there is no person/history row at all.
  missing <- setdiff(slots$key, observed$key)
  for (k in missing) {
    if (k %in% original$key) stop("Original occupied chair missing from membership sources: ", k, call. = FALSE)
    z <- observed[NA_integer_, , drop = FALSE]
    s <- slots[slots$key == k, ]
    for (col in intersect(names(s), names(z))) z[[col]] <- s[[col]]
    z$key <- k; z$status <- "vacant"; z$start_date <- date
    z$event_date <- date; z$election_kind <- "ordinary"
    z$start_date_basis <- "original_unfilled_allocation"
    z$source_kind <- "allocation"; z$source_as_of <- min(current$source_as_of)
    observed <- dplyr::bind_rows(observed, z)
  }
  # Re-elections replace their original chairs; do not append them to the active universe.
  for (i in which(events$original_year == year)) {
    cut <- as.Date(events$election_date[[i]])
    hit <- .mh_component_hit(observed, events[i, ]) & observed$event_date < cut
    hit <- hit & (is.na(observed$end_date) | observed$end_date > cut)
    observed$end_date[hit] <- cut
    observed$end_date_basis[hit] <- "re_election_replacement"
  }
  observed$interval_coverage[is.na(observed$interval_coverage)] <- "source_chain"
  uncertain <- which(observed$interval_coverage == "original_election_only")
  additions <- list()
  for (i in uncertain) {
    if (observed$end_date[[i]] <= date + 1L) next
    z <- observed[i, ]
    z$start_date <- date + 1L
    z$candidate_number <- NA_character_; z$name <- NA_character_
    z$status <- "unknown"; z$interval_coverage <- "unverified_continuity"
    z$start_date_basis <- "original_election_observation_boundary"
    observed$end_date[[i]] <- date + 1L
    observed$end_date_basis[[i]] <- "original_election_observation_boundary"
    additions[[length(additions) + 1L]] <- z
  }
  observed <- dplyr::bind_rows(observed, dplyr::bind_rows(additions))
  observed$chair_id <- paste(year, observed$event_date, observed$key, sep = ":")
  observed <- observed[order(observed$chair_id, observed$start_date, observed$end_date), ]
  groups <- split(seq_len(nrow(observed)), observed$chair_id)
  for (ii in groups) {
    x <- observed[ii, ]
    if (x$start_date[[1L]] != x$event_date[[1L]])
      stop("Chair history does not cover its verified election-event start.", call. = FALSE)
    if (any(!is.na(x$end_date) & x$end_date < x$start_date)) stop("Reversed membership interval.", call. = FALSE)
    if (nrow(x) > 1L && any(is.na(utils::head(x$end_date, -1L)) |
        utils::head(x$end_date, -1L) != utils::tail(x$start_date, -1L)))
      stop("Gap or overlap in membership intervals; sources require reconciliation.", call. = FALSE)
  }
  # A source snapshot is a coverage boundary, not an invented departure date.
  observed$coverage_end <- min(current$source_as_of)
  boundaries <- c(date, min(current$source_as_of))
  for (i in which(events$original_year == year)) {
    if (!any(.mh_component_hit(a, events[i, ]))) next
    cut <- as.Date(events$election_date[[i]])
    boundaries <- c(boundaries, cut - 1L, cut)
    rerun <- observed[.mh_component_hit(observed, events[i, ]) &
      observed$election_kind == "re_election", ]
    at <- .mh_at(rerun, cut)
    expected <- events$verified_allocation[[i]]
    actual <- table(at$party_abbreviation)
    if (!setequal(names(actual), names(expected)) ||
        any(as.integer(actual[names(expected)]) != as.integer(expected)))
      stop("Re-election chair population disagrees with verified allocation.", call. = FALSE)
  }
  for (day in as.numeric(boundaries)) {
    at <- .mh_at(observed, as.Date(day, origin = "1970-01-01"))
    if (nrow(at) != sum(a$seats) || anyDuplicated(at$chair_id))
      stop("Active chair population differs from the original allocated total.", call. = FALSE)
  }
  if (!is.null(vacancies)) {
    at <- .mh_at(observed, min(current$source_as_of))
    vac <- at[at$status == "vacant", ]
    x <- table(paste(vac$election_code, vac$electoral_area_code, vac$party_code))
    y <- stats::setNames(vacancies$vacancy_count,
      paste(vacancies$election_code, vacancies$electoral_area_code, vacancies$party_code))
    keys <- union(names(x), names(y)); xx <- as.integer(x[keys]); yy <- as.integer(y[keys])
    xx[is.na(xx)] <- 0L; yy[is.na(yy)] <- 0L
    if (any(xx != yy)) stop("Vacancy intervals disagree with the vacancy control snapshot: ",
      paste(paste0(keys[xx != yy], " (intervals=", xx[xx != yy], ", control=", yy[xx != yy], ")"), collapse = "; "), call. = FALSE)
  }
  observed$start_reason <- ifelse(observed$status == "vacant", "vacancy",
    ifelse(observed$start_date == observed$event_date,
      ifelse(observed$election_kind == "re_election", "re_election", "ordinary_election"), "succession"))
  observed$start_reason[observed$status == "unknown"] <- "coverage_boundary"
  observed$end_reason <- ifelse(is.na(observed$end_date), NA_character_, "departure")
  observed$end_reason[observed$interval_coverage == "original_election_only"] <- "coverage_boundary"
  # Never infer voluntary resignation, death or term end from a date alone.
  if ("reported_end_reason" %in% names(observed)) {
    r <- observed$reported_end_reason
    if (any(!is.na(r) & !r %in% c("departure", "resignation", "death", "term_end")))
      stop("Unsupported source-reported end reason.", call. = FALSE)
    hit <- !is.na(r) & !is.na(observed$end_date)
    observed$end_reason[hit] <- r[hit]
  }
  for (ii in groups) {
    for (j in seq_along(ii)) {
      i <- ii[[j]]
      if (observed$status[[i]] == "vacant" && !is.na(observed$end_date[[i]]))
        observed$end_reason[[i]] <- "succession"
      if (j > 1L && observed$status[[i]] == "occupied")
        observed$start_reason[[i]] <- "succession"
    }
  }
  for (j in which(events$original_year == year)) {
    hit <- .mh_component_hit(observed, events[j, ]) & observed$event_date < as.Date(events$election_date[[j]]) &
      observed$end_date %in% as.Date(events$election_date[[j]])
    observed$end_reason[hit] <- "re_election"
  }
  observed$component_scope_level <- ifelse(nzchar(observed$constituency),
    ifelse(observed$election_code == "KF", "municipal_constituency",
      ifelse(observed$election_code == "RF", "regional_constituency", "parliamentary_constituency")),
    ifelse(observed$election_code == "KF", "municipality", ifelse(observed$election_code == "RF", "region", "national")))
  observed$component_scope_code <- ifelse(nzchar(observed$constituency), observed$constituency, observed$electoral_area_code)
  observed$component_start_date <- observed$event_date
  observed$component_end_date <- as.Date(NA)
  for (j in which(events$original_year == year)) {
    cut <- as.Date(events$election_date[[j]])
    hit <- .mh_component_hit(observed, events[j, ]) & observed$event_date < cut &
      (is.na(observed$component_end_date) | observed$component_end_date > cut)
    observed$component_end_date[hit] <- cut
  }
  observed$component_id <- paste(year, observed$event_date, observed$election_code,
    observed$component_scope_level, observed$component_scope_code, sep = ":")
  observed$election_year <- as.integer(year)
  observed$original_candidate_number <- original$candidate_number[match(observed$key, original$key)]
  observed$municipality_code <- ifelse(observed$election_code == "KF", observed$electoral_area_code, NA_character_)
  observed$region_code <- ifelse(observed$election_code == "RF", observed$electoral_area_code, NA_character_)
  observed$municipal_constituency_code <- ifelse(observed$election_code == "KF" & nzchar(observed$constituency), observed$constituency, NA_character_)
  observed$constituency_code <- ifelse(observed$election_code != "KF" & nzchar(observed$constituency), observed$constituency, NA_character_)
  observed$interval_id <- paste(observed$chair_id, observed$start_date,
    ifelse(is.na(observed$candidate_number), observed$status, observed$candidate_number), seq_len(nrow(observed)), sep = ":")
  observed
}

.mh_at <- function(x, date) x[x$start_date <= date &
  (is.na(x$end_date) | date < x$end_date), , drop = FALSE]

.mh_present <- function(x, language, detail) {
  standard <- c("election_year", "event_date", "election_kind", "chair_id", "interval_id",
    "election_code", "municipality_code", "region_code", "constituency_code",
    "municipal_constituency_code", "party_code", "party_abbreviation", "seat_number",
    "candidate_number", "name", "status", "start_date", "end_date", "start_date_basis",
    "end_date_basis", "correction_date", "correction_reference", "coverage_end")
  standard <- c(standard, "component_id", "component_scope_level", "component_scope_code",
    "start_reason", "end_reason", "interval_coverage", "component_start_date", "component_end_date")
  extra <- c("reported_start_date", "source_file", "source_md5", "source_as_of", "source_row", "source_kind",
    "original_candidate_number", "reported_end_date", "reported_end_reason")
  x <- x[, c(standard, if (detail == "full") extra), drop = FALSE]
  for (k in names(x)) if (inherits(x[[k]], "Date"))
    x[[k]] <- structure(as.integer(x[[k]]), class = "Date")
  x <- .values_present(x, language)
  if (language == "sv") {
    swedish <- c("valar", "valdatum", "valklass", "mandat_id", "intervall_id", "valtyp",
      "kommunkod", "regionkod", "valkretskod", "kommunvalkretskod", "partikod",
      "partiforkortning", "mandatnummer", "kandidatnummer", "namn", "status",
      "startdatum", "slutdatum", "startdatumgrund", "slutdatumgrund", "rattelsedatum",
      "rattelsereferens", "tackning_till", "kallrapporterat_startdatum", "kallfil",
      "kall_md5", "kalldatum", "kallrad", "kalltyp", "ursprungligt_kandidatnummer", "kallrapporterat_slutdatum", "kallrapporterad_slutorsak")
    map <- stats::setNames(swedish, c(setdiff(standard, c("component_id",
      "component_scope_level", "component_scope_code", "start_reason", "end_reason", "interval_coverage",
      "component_start_date", "component_end_date")), extra))
    map <- c(map, component_id = "mandatkomponent_id", component_scope_level = "komponent_omfattningsniva",
      component_scope_code = "komponent_omfattningskod", start_reason = "startorsak",
      end_reason = "slutorsak", interval_coverage = "intervalltackning",
      component_start_date = "komponent_startdatum", component_end_date = "komponent_slutdatum")
    names(x) <- unname(map[names(x)])
  }
  x
}

#' Electoral chair histories and dated membership snapshots
#'
#' Reads canonical histories for 2014--2018 and 2018--2022, and current official
#' remote history for 2022--2026. The chair population is allocated mandates, including
#' initially unfilled mandates. Successive holders and verified vacancies use
#' half-open intervals `[start_date, end_date)`. An outgoing holder is excluded
#' on the successor's start date. Zero-length source intervals are retained in
#' history and never appear in a snapshot.
#'
#' Dates follow Valmyndigheten's convention: original elected members start on
#' election day; successor dates are administrative appointment dates. These
#' functions do not describe attendance or temporary substitute service.
#' Ragunda's corrected original 2018 result starts on election day, with the
#' 12 December correction recorded separately. Re-elections replace original
#' components from their own event date within the continuing period.
#'
#' Components retain `component_id`, geographic `component_scope_level`/
#' `component_scope_code` and `component_start_date`/`component_end_date`. Partial
#' replacements close only the affected constituency; other components continue.
#' `start_reason` and `end_reason` are separate from date provenance: ordinary_election,
#' re_election, succession, vacancy, departure or coverage_boundary as applicable.
#' Resignation, death and term_end require explicit source evidence; a departure
#' date alone does not establish any of these causes. An open end is not a
#' fabricated term end.
#'
#' For Båstad's original 2014 cohort, the surviving exports verify election-day
#' holders but not their continuity until the 2015 re-election. History retains
#' election-day observations and allocated chairs with status unknown and
#' interval_coverage unverified_continuity from the next day until replacement.
#' This is a knowledge boundary, not an inferred departure. Both dated functions
#' fail when their selected population includes such an interval, rather than
#' silently omitting chairs or asserting vacancies.
#'
#' Histories with the older canonical schema require a separately validated
#' rebuild before this reader can use them. No frozen published asset is modified.
#' The published 2014 and 2018 histories include Båstad 2015 and Falun 2019
#' within their original periods. The general component model also supports
#' Orsa 2003 and the 2011 re-election scopes, but no public 2002 or 2010 history
#' product is provided. Model support does not extend public data coverage.
#'
#' Source dates, hashes and row references are available with `detail = "full"`.
#' Coverage is bounded by the inspected source dates. Remote coverage is bounded by
#' both history and current-member dates. Later dates fail rather than extrapolate.
#' Missing starts require a verified original-holder/allocation match; unresolved
#' chains or contradictory controls fail explicitly, rather than inventing status.
#' Candidate numbers identify source candidates within an election occasion,
#' not longitudinal physical-person identities.
#'
#' @param year Original ordinary election year: 2014, 2018 or 2022.
#' @param election RD/RF/KF or their English names; `NULL` selects all three.
#' @param data_dir Preserved archive root for explicit local source selection.
#' @param files Named list selecting exact `history`, `current`, `departures`
#'   and `vacancies` files. Otherwise the latest dated preserved file for each
#'   role is selected. Overrides require explicit local source selection.
#' @param source One of auto, canonical, remote or local. Auto selects
#'   approved canonical history for 2014/2018, and remote history for 2022; never local.
#'   Remote fetches four current Valmyndigheten CSV exports sequentially on each
#'   request. The fixed original allocation/elected baseline uses its normal
#'   approved result source (canonical for 2022), not a membership population.
#'   Canonical history requires no raw archive. Remote source inconsistencies
#'   fail explicitly; no local archive is used to repair a failed request.
#'   2022 history is not canonical in this release. A later frozen generation
#'   requires separate approval after reporting has stabilised; no date-triggered
#'   automatic switch is made.
#' @param names Column and technical-category language, `"en"` or `"sv"`.
#'   Proper names and literal source identifiers are unchanged.
#' @param detail `"standard"` or `"full"`; standard is a projection of full.
#' @return A tibble of chair-holder/vacancy intervals, or rows active at `date`.
#' @export
mandate_history <- function(year = 2018, election = NULL, data_dir = NULL,
    files = list(), source = c("auto", "canonical", "remote", "local"), names = c("en", "sv"),
    detail = c("standard", "full")) {
  .mh_history(year, election, data_dir, files, source, names, detail, "mandate_history")
}

.mh_snapshot <- function(date, year, election, data_dir, files, source, names, detail, status) {
  if (length(date) != 1L || is.na(date)) stop("Supply one snapshot date.", call. = FALSE)
  date <- .mh_date(as.character(date))
  if (is.null(year)) {
    years <- c(2014L, 2018L, 2022L)
    starts <- as.Date(c("2014-09-14", "2018-09-09", "2022-09-11"))
    if (date < starts[[1L]]) stop("Date precedes supported membership periods.", call. = FALSE)
    year <- max(years[starts <= date])
  }
  x <- .mh_history(year, election, data_dir, files, source, "en", "full",
    if (status == "occupied") "members_at" else "vacant_seats_at")
  if (date < min(x$event_date) || date > min(x$coverage_end))
    stop("Snapshot date is outside verified source coverage.", call. = FALSE)
  x <- .mh_at(x, date)
  if (anyDuplicated(x$chair_id)) stop("Multiple holders for one chair at snapshot date.", call. = FALSE)
  if (any(x$status == "unknown"))
    stop("Snapshot includes unverified holder continuity; inspect mandate_history() interval_coverage.", call. = FALSE)
  x <- x[x$status == status, ]
  .mh_present(x, match.arg(names, c("en", "sv")), match.arg(detail, c("standard", "full")))
}

#' @rdname mandate_history
#' @param date One date (`Date` or ISO text). `year = NULL` selects the latest
#'   supported original election on or before that date, under the source date convention.
#' @export
members_at <- function(date, year = NULL, election = NULL, data_dir = NULL,
    files = list(), source = "auto", names = "en", detail = "standard") {
  .mh_snapshot(date, year, election, data_dir, files, source, names, detail, "occupied")
}

#' @rdname mandate_history
#' @export
vacant_seats_at <- function(date, year = NULL, election = NULL, data_dir = NULL,
    files = list(), source = "auto", names = "en", detail = "standard") {
  .mh_snapshot(date, year, election, data_dir, files, source, names, detail, "vacant")
}

#' Mandathistorik och mandatens innehavare vid ett datum
#' @param ar Ursprungligt ordinarie valår, 2014, 2018 eller 2022; `NULL` i
#'   datumfrågor väljer det senaste stödda valet på eller före datumet.
#' @param val Valtyp RD, RF eller KF; `NULL` väljer alla tre.
#' @param datum Ett datum som `Date` eller text på formen ÅÅÅÅ-MM-DD.
#' @param detaljniva `"standard"` eller `"full"`.
#' @inheritParams mandate_history
#' @details Samma tilldelade mandat ligger till grund för både ledamöter och
#'   tomma stolar. Intervallen inkluderar startdatum men inte slutdatum.
#'   Ursprungliga och senare vakanser ingår. Datum följer källans administrativa
#'   konvention, inte faktisk närvaro eller tillfällig ersättartjänstgöring.
#'   Se [mandate_history()] för källval, täckningsgränser och proveniens.
#' @return En tibble med mandatintervall eller verifierade innehavare/vakanser.
#' @export
mandathistorik <- function(ar = 2018, val = NULL, data_dir = NULL, files = list(),
    source = "auto", names = "sv", detaljniva = "standard") {
  mandate_history(ar, val, data_dir, files, source, names, detaljniva)
}

#' @rdname mandathistorik
#' @export
ledamoter_vid <- function(datum, ar = NULL, val = NULL, data_dir = NULL,
    files = list(), source = "auto", names = "sv", detaljniva = "standard") {
  members_at(datum, ar, val, data_dir, files, source, names, detaljniva)
}

#' @rdname mandathistorik
#' @export
tomma_stolar_vid <- function(datum, ar = NULL, val = NULL, data_dir = NULL,
    files = list(), source = "auto", names = "sv", detaljniva = "standard") {
  vacant_seats_at(datum, ar, val, data_dir, files, source, names, detaljniva)
}
