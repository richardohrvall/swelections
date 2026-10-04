# Broader preference-vote views use the official, non-overlapping preference
# vote areas. District figures are deliberately not used: in historical data
# district and area totals need not have the same reporting semantics.
.known_integer_sum <- function(x) {
  if (!length(x) || anyNA(x)) return(NA_integer_)
  as.integer(sum(as.double(x)))
}

.aggregate_preference_area <- function(data, level) {
  required_election <- if (level == "kommun") "KF" else "RF"
  if (any(data$valtyp != required_election)) {
    stop("The requested broader preference-vote level is only available for ",
         required_election, ".", call. = FALSE)
  }
  area_key <- c("valar", "valtyp", "valomradeskod", "personvalsomradeskod",
                "partikod", "kandidatnummer")
  if (anyNA(data[c("valomradeskod", "personvalsomradeskod")]) ||
      anyDuplicated(data[area_key])) {
    stop("Preference-vote areas must have known geography and unique candidate keys.",
         call. = FALSE)
  }
  base <- c("valar", "valtyp", "valomradeskod", "partikod")
  area <- c(base, "personvalsomradeskod")
  party_area <- data |>
    dplyr::select(dplyr::all_of(c(area, "antal_partiroster"))) |>
    dplyr::distinct()
  conflicting <- party_area |>
    dplyr::count(dplyr::across(dplyr::all_of(area))) |>
    dplyr::filter(.data$n != 1L)
  if (nrow(conflicting)) {
    stop("Conflicting party-vote totals within a preference-vote area.",
         call. = FALSE)
  }
  party_totals <- party_area |>
    dplyr::summarise(
      antal_partiroster = .known_integer_sum(.data$antal_partiroster),
      areas_with_party = dplyr::n_distinct(.data$personvalsomradeskod),
      .by = dplyr::all_of(base))
  parent_areas <- party_area |>
    dplyr::summarise(
      areas_in_parent = dplyr::n_distinct(.data$personvalsomradeskod),
      .by = dplyr::all_of(c("valar", "valtyp", "valomradeskod")))
  party_totals <- dplyr::left_join(
    party_totals, parent_areas,
    by = c("valar", "valtyp", "valomradeskod"), relationship = "many-to-one")
  party_totals$party_area_complete <-
    party_totals$areas_with_party == party_totals$areas_in_parent
  party_totals$antal_partiroster[!party_totals$party_area_complete] <- NA_integer_
  party_totals <- dplyr::select(
    party_totals, dplyr::all_of(c(base, "antal_partiroster", "party_area_complete")))

  by_list <- "listnummer" %in% names(data)
  key <- c(base, "kandidatnummer", if (by_list) "listnummer")
  candidate_totals <- data |>
    dplyr::summarise(antal_personroster = .known_integer_sum(.data$antal_personroster),
                     .by = dplyr::all_of(key))
  metadata <- data |>
    dplyr::select(dplyr::any_of(c(
      key, "valtillfalle", "namn", "partiforkortning", "partibeteckning",
      "valomradesnamn", "rakningstillfalle", "valdatum", "test"
    ))) |>
    dplyr::distinct(dplyr::across(dplyr::all_of(key)), .keep_all = TRUE)
  out <- dplyr::left_join(metadata, candidate_totals, by = key,
                          relationship = "one-to-one") |>
    dplyr::left_join(party_totals, by = base, relationship = "many-to-one")
  out$antal_personroster[!out$party_area_complete] <- NA_integer_
  out$party_area_complete <- NULL
  out$andel_personroster <- as.double(ifelse(
    !is.na(out$antal_personroster) & !is.na(out$antal_partiroster) &
      out$antal_partiroster > 0L,
    out$antal_personroster / out$antal_partiroster, NA_real_
  ))
  if (by_list) {
    list_area <- data |>
      dplyr::select(dplyr::all_of(c(area, "listnummer", "antal_listroster"))) |>
      dplyr::distinct()
    if (nrow(list_area |> dplyr::count(dplyr::across(dplyr::all_of(c(area, "listnummer")))) |>
             dplyr::filter(.data$n != 1L))) {
      stop("Conflicting list-vote totals within a preference-vote area.",
           call. = FALSE)
    }
    list_totals <- list_area |>
      dplyr::summarise(antal_listroster = .known_integer_sum(.data$antal_listroster),
                       .by = dplyr::all_of(c(base, "listnummer")))
    out <- dplyr::left_join(out, list_totals, by = c(base, "listnummer"),
                            relationship = "many-to-one")
    out$andel_personroster_lista <- ifelse(
      !is.na(out$antal_personroster) & !is.na(out$antal_listroster) &
        out$antal_listroster > 0L,
      out$antal_personroster / out$antal_listroster, NA_real_
    )
  }
  out$geografiniva <- rep(level, nrow(out))
  # Qualification is decided in a preference-vote area; it has no single
  # meaning after several such areas are combined.
  out |> dplyr::relocate(dplyr::any_of(c("valtillfalle", "valar", "valtyp",
                                        "geografiniva")))
}
