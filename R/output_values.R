# Field-scoped semantic values. Source identifiers and proper names are excluded.
.value_dictionary <- function() {
  level <- .english_argument_values$level
  level <- stats::setNames(names(level), unname(level))
  list(
    count_stage = c(slutlig = "final", preliminar = "preliminary"),
    geographic_level = level,
    district_type = c(valdistrikt = "ordinary", uppsamlingsdistrikt = "collection",
      onsdagsdistrikt = "wednesday"),
    sex = c(Man = "male", Kvinna = "female", M = "male", K = "female",
      man = "male", kvinna = "female"),
    ballot_status = c(Definitiv = "final", Utkast = "draft",
      definitiv = "final", utkast = "draft", S = "S", B = "B"),
    comparison_status = c("Kan j\u00e4mf\u00f6ras" = "comparable",
      "Ej j\u00e4mf\u00f6rbart" = "not_comparable", "J\u00e4mf\u00f6rs mot summerat" = "compared_with_aggregate",
      Summerad = "aggregated", Ny = "new", Modifierad = "modified",
      "ej j\u00e4mf\u00f6rbar: Ny" = "not_comparable_new",
      "ej j\u00e4mf\u00f6rbar: Modifierad" = "not_comparable_modified"),
    election_basis = c(
      "Ledamoten \u00e4r vald p\u00e5 j\u00e4mf\u00f6relsetal" = "comparison_number",
      "Ledamoten \u00e4r vald p\u00e5 personr\u00f6ster" = "preference_votes",
      "Ledamoten \u00e4r vald som listtrogen eftertr\u00e4dare till dubbelvalsavvecklad" = "list_successor_after_dual_election",
      "Ledamoten \u00e4r vald p\u00e5 personr\u00f6ster som eftertr\u00e4dare till dubbelvalsavvecklad" = "preference_vote_successor_after_dual_election",
      "Ers\u00e4ttaren \u00e4r utsedd listtroget" = "list_substitute",
      "Ers\u00e4ttaren \u00e4r vald p\u00e5 personr\u00f6ster" = "preference_vote_substitute"),
    election_kind = c("ordinarie val" = "ordinary", Ordinarie = "ordinary",
      ordinarie = "ordinary", omval = "re_election"),
    voting_option_name = c(Ja = "yes", Nej = "no", Blank = "blank"),
    status = c(besatt = "occupied", vakant = "vacant", okand = "unknown"),
    composition_type = c(efter_omval = "after_re_election"),
    source_kind = c(nuvarande = "current", avgangar = "departures",
      mandatfordelning = "allocation", ursprungligt_val = "original_election", historik = "history"),
    start_date_basis = c(kallrapporterat = "reported", matchat_ursprungligt_vald = "original_elected_match",
      ursprungligen_otillsatt = "original_unfilled_allocation",
      rattat_ursprungligt_vald = "corrected_original_elected",
      ursprunglig_observationsgrans = "original_election_observation_boundary",
      verifierad_vakans_efter_avgang = "departure_without_successor_verified_vacancy_control"),
    reported_end_reason = c(avgang = "departure", avsagelse = "resignation",
      dodsfall = "death", mandatperiodens_slut = "term_end"),
    start_reason = c(ordinarie_val = "ordinary_election", omval = "re_election",
      eftertradare = "succession", vakans = "vacancy", tackningsgrans = "coverage_boundary"),
    end_reason = c(omval = "re_election", avgang = "departure", avsagelse = "resignation",
      dodsfall = "death", eftertradare = "succession", mandatperiodens_slut = "term_end",
      tackningsgrans = "coverage_boundary"),
    interval_coverage = c(kallkedja = "source_chain", enbart_ursprungligt_val = "original_election_only",
      obestyrkt_kontinuitet = "unverified_continuity"),
    component_scope_level = level,
    end_date_basis = c(kallrapporterat = "reported", ersatt_genom_omval = "re_election_replacement",
      ursprunglig_observationsgrans = "original_election_observation_boundary"),
    scope_level = level, event_scope_level = level,
    component_geographic_level = c(level, valkrets = "constituency"))
}

.value_swedish_dictionary <- function() {
  d <- .value_dictionary()
  invert <- function(x) stats::setNames(names(x)[!duplicated(unname(x))],
                                       unname(x)[!duplicated(unname(x))])
  out <- lapply(d, invert)
  out$sex <- c(male = "man", female = "kvinna")
  out$ballot_status <- c(final = "definitiv", draft = "utkast", S = "S", B = "B")
  out$election_kind <- c(ordinary = "ordinarie", re_election = "omval")
  out$status <- c(occupied = "besatt", vacant = "vakant", unknown = "okand")
  out$source_kind <- c(current = "nuvarande", departures = "avgangar",
    allocation = "mandatfordelning", original_election = "ursprungligt_val", history = "historik")
  out$start_date_basis <- c(reported = "kallrapporterat",
    original_elected_match = "matchat_ursprungligt_vald",
    original_unfilled_allocation = "ursprungligen_otillsatt",
    corrected_original_elected = "rattat_ursprungligt_vald",
    original_election_observation_boundary = "ursprunglig_observationsgrans",
    departure_without_successor_verified_vacancy_control = "verifierad_vakans_efter_avgang")
  out$end_date_basis <- c(reported = "kallrapporterat", re_election_replacement = "ersatt_genom_omval",
    original_election_observation_boundary = "ursprunglig_observationsgrans")
  out$reported_end_reason <- out$end_reason
  out$composition_type <- c(after_re_election = "efter_omval")
  for (f in c("scope_level", "event_scope_level", "component_geographic_level"))
    out[[f]] <- c(out$geographic_level, constituency = "valkrets")
  out
}

.value_recode <- function(x, map, field, strict = TRUE) {
  if (!is.character(x)) {
    if (!all(is.na(x))) stop("Expected character category: ", field, call. = FALSE)
    x <- as.character(x)
  }
  i <- match(x, names(map))
  unknown <- !is.na(x) & nzchar(x) & is.na(i) & !x %in% unname(map)
  if (strict && any(unknown))
    stop("Unknown technical category in ", field, ": ",
      paste(unique(x[unknown]), collapse = ", "), call. = FALSE)
  hit <- !is.na(i)
  x[hit] <- unname(map[i[hit]])
  x
}

# Lossless Boolean + applicability pair: not applicable is not false.
.value_applicability <- function(data, field, app = paste0(field, "_applicable")) {
  x <- data[[field]]
  if (is.logical(x)) {
    value <- x
    applicable <- if (app %in% names(data)) data[[app]] else
      ifelse(is.na(value), NA, TRUE)
  } else {
    if (!is.character(x) && !all(is.na(x)))
      stop("Expected Boolean/source status in ", field, call. = FALSE)
    x <- as.character(x)
    known <- is.na(x) | x %in% c("ja", "nej", "irrelevant", "yes", "no", "not_applicable", "J", "N", "I")
    if (!all(known)) stop("Unknown applicability category in ", field, call. = FALSE)
    value <- rep(NA, length(x))
    value[x %in% c("ja", "yes", "J")] <- TRUE
    value[x %in% c("nej", "no", "N")] <- FALSE
    applicable <- rep(NA, length(x))
    applicable[!is.na(value)] <- TRUE
    applicable[x %in% c("irrelevant", "not_applicable", "I")] <- FALSE
    if (app %in% names(data) && !identical(data[[app]], applicable))
      stop("Conflicting applicability in ", field, call. = FALSE)
  }
  if (!is.logical(applicable) || any(!is.na(value) & !(applicable %in% TRUE)))
    stop("Inconsistent Boolean/applicability pair: ", field, call. = FALSE)
  data[[field]] <- value
  data[[app]] <- applicable
  data
}

.value_aggregate_labels <- function(data, language) {
  if (!"party_designation" %in% names(data)) return(data)
  x <- data$party_designation
  # These are documented aggregate labels, never substring/name matching.
  other <- x %in% c("\u00d6vriga partier", "Other parties")
  if ("other_parties" %in% names(data)) other <- other & data$other_parties %in% TRUE
  if ("party_code" %in% names(data) && !"other_parties" %in% names(data))
    other <- other & data$party_code %in% c("9999", "\u00d6VR", "OVR")
  handwritten <- x %in% c("Handskrivna r\u00f6ster", "Handwritten votes")
  if ("other_parties" %in% names(data)) handwritten <- handwritten & data$other_parties %in% TRUE
  else if ("party_code" %in% names(data)) handwritten <- handwritten & data$party_code %in% "9997"
  x[other] <- if (language == "en") "Other parties" else "\u00d6vriga partier"
  x[handwritten] <- if (language == "en") "Handwritten votes" else "Handskrivna r\u00f6ster"
  data$party_designation <- x
  data
}

.values_en <- function(data) {
  d <- .value_dictionary()
  for (f in intersect(names(d), names(data))) data[[f]] <- .value_recode(data[[f]], d[[f]], f)
  for (f in intersect(c("consent", "candidate_declaration"), names(data)))
    data <- .value_applicability(data, f)
  # Keep added applicability columns last in both storage and public output.
  applicable <- intersect(c("consent_applicable", "candidate_declaration_applicable"), names(data))
  if (length(applicable)) data <- data[, c(setdiff(names(data), applicable), applicable), drop = FALSE]
  .value_aggregate_labels(data, "en")
}

.values_present <- function(data, language) {
  data <- .values_en(data)
  if (language == "en") return(data)
  d <- .value_swedish_dictionary()
  for (f in intersect(names(d), names(data)))
    data[[f]] <- .value_recode(data[[f]], d[[f]], f)
  .value_aggregate_labels(data, "sv")
}

.public_output <- function(data, language) {
  # Nested raw requests must retain the exact source-oriented internal contract.
  if (isTRUE(getOption("swelections.internal_raw_request", FALSE)))
    return(.public_output_names(data, language))
  if (language == "en") data <- .public_output_names(data, "en") else {
    translated <- unname(.public_name_base_en[names(data)])
    hit <- !is.na(translated)
    names(data)[hit] <- translated[hit]
  }
  data <- .values_present(data, language)

  if (language == "sv") {
    inverse <- stats::setNames(names(.public_name_base_en), .public_name_base_en)
    translated <- unname(inverse[names(data)])
    hit <- !is.na(translated)
    names(data)[hit] <- translated[hit]
  }
  data
}

.canonical_encode <- function(data) {
  data <- .values_en(.canonical_names_en(data))
  for (f in intersect(c(".component", ".table"), names(data)))
    data[[f]] <- .canonical_storage_key(data[[f]])
  data
}

.canonical_storage_key <- function(x) {
  map <- c(.value_dictionary()$geographic_level,
    geo = "geography", parti = "party", lista = "list", roster = "votes",
    listroster = "list_votes", omraden = "areas", officiella = "official",
    population_kandidat = "candidate_population", population_lista = "list_population",
    population_alla = "all_population")
  .value_recode(x, map, "storage key", strict = FALSE)
}
# A public multi-year union may mix normalized canonical and raw source flags.
# Harmonize these properties before vctrs combines their types. Nested raw
# algorithms retain their source-oriented contract until final presentation.
.public_bind_years <- function(data) {
  if (length(data) > 1L && !isTRUE(getOption("swelections.internal_raw_request", FALSE))) {
    applicable <- c(samtycke = "samtycke_tillampligt", forklaring = "forklaring_tillamplig")
    data <- lapply(data, function(x) {
      for (field in intersect(names(applicable), names(x)))
        x <- .value_applicability(x, field, applicable[[field]])
      x
    })
  }
  purrr::list_rbind(data)
}
