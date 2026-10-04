# Public column names are translated only after a complete Swedish result has
# been constructed and validated. Values, types, keys and row order are untouched.
.public_name_base_en <- c(
  valtillfalle = "election_event",
  valar = "election_year",
  valklass = "election_kind",
  valtyp = "election_code",
  rakningstillfalle = "count_stage",
  valdatum = "election_date",
  test = "is_test",
  geografiniva = "geographic_level",
  valdistriktskod = "district_code",
  valdistriktsnamn = "district_name",
  valdistriktstyp = "district_type",
  kommunkod = "municipality_code",
  kommunnamn = "municipality_name",
  kommunnamn_officiellt = "official_municipality_name",
  lankod = "county_code",
  lannamn = "county_name",
  regionkod = "region_code",
  regionnamn = "region_name",
  valomradeskod = "electoral_area_code",
  valomradesnamn = "electoral_area_name",
  valkretskod = "constituency_code",
  valkretsnamn = "constituency_name",
  kandidatur_valomradeskod = "candidacy_electoral_area_code",
  kandidatur_valomradesnamn = "candidacy_electoral_area_name",
  kandidatur_valkretskod = "candidacy_constituency_code",
  kandidatur_valkretsnamn = "candidacy_constituency_name",
  kandidatur_kommunvalkretskod = "candidacy_municipal_constituency_code",
  kandidatur_kommunvalkretsnamn = "candidacy_municipal_constituency_name",
  kall_valkretskod = "source_constituency_code",
  kall_valomradeskod = "source_electoral_area_code",
  kall_valomradesnamn = "source_electoral_area_name",
  kall_valkretsnamn = "source_constituency_name",
  kall_kandidatur_valkretskod = "source_candidacy_constituency_code",
  kall_kandidatur_valkretsnamn = "source_candidacy_constituency_name",
  kall_invald_valkretskod = "source_elected_constituency_code",
  kall_invald_valkretsnamn = "source_elected_constituency_name",
  kommunvalkretskod = "municipal_constituency_code",
  kommunvalkretsnamn = "municipal_constituency_name",
  personvalsomradeskod = "preference_vote_area_code",
  personvalsomradesnamn = "preference_vote_area_name",
  raknat = "counted",
  rapporteringstid = "reporting_time",
  senaste_uppdateringstid = "source_last_update_time",
  senaste_uppdateringstid_omrade = "area_last_update_time",
  antal_uppdateringar = "update_count",
  antal_valdistrikt_raknade = "overall_districts_counted",
  antal_valdistrikt_som_ska_raknas = "overall_districts_to_count",
  antal_valdistrikt_raknade_omrade = "area_districts_counted",
  antal_valdistrikt_som_ska_raknas_omrade = "area_districts_to_count",
  antal_rostberattigade_raknade = "eligible_voters_in_counted_districts",
  partibeteckning = "party_designation",
  partiforkortning = "party_abbreviation",
  partikod = "party_code",
  partifarg = "party_color",
  fargkod = "color_code",
  ordningsnummer = "party_order",
  ovriga_partier = "other_parties",
  over_sparr = "above_threshold",
  valomradessparr = "electoral_area_threshold",
  valkretssparr = "constituency_threshold",
  antal_roster = "votes",
  andel_roster = "vote_share",
  totalt_antal_roster = "total_votes",
  antal_rostberattigade = "eligible_voters",
  valdel = "turnout",
  giltiga_roster = "valid_votes",
  ogiltiga_roster = "invalid_votes",
  andel_ogiltiga = "invalid_vote_share",
  roster_ej_anmalt_deltagande = "votes_no_participation_notice",
  andel_ej_anmalt_deltagande = "vote_share_no_participation_notice",
  blanka_roster = "blank_votes",
  andel_blanka = "blank_vote_share",
  ovriga_ogiltiga = "other_invalid_votes",
  andel_ovriga_ogiltiga = "other_invalid_vote_share",
  status_jamforelse = "comparison_status",
  antal_mandat = "seats",
  antal_fasta_mandat = "fixed_seats",
  antal_utjamningsmandat = "adjustment_seats",
  totalt_antal_mandat = "total_seats",
  totalt_antal_fasta_mandat = "total_fixed_seats",
  totalt_antal_utjamningsmandat = "total_adjustment_seats",
  antal_tomma_stolar = "unfilled_seats",
  kandidatnummer = "candidate_number",
  namn = "name",
  kon = "sex",
  alder_pa_valdagen = "age_on_election_day",
  folkbokforingskommun = "registered_municipality_name",
  antal_personroster = "preference_votes",
  antal_personroster_totalt = "total_preference_votes",
  antal_partiroster = "party_votes",
  andel_personroster = "preference_vote_share",
  antal_listroster = "list_votes",
  andel_personroster_lista = "list_preference_vote_share",
  kvalificerad_personval = "qualified_by_preference_votes",
  antal_personvalsomraden = "preference_vote_areas_count",
  invald = "elected",
  invald_valomradeskod = "elected_electoral_area_code",
  invald_valomradesnamn = "elected_electoral_area_name",
  invald_valkretskod = "elected_constituency_code",
  invald_valkretsnamn = "elected_constituency_name",
  invald_kommunvalkretskod = "elected_municipal_constituency_code",
  invald_kommunvalkretsnamn = "elected_municipal_constituency_name",
  invalsordning = "order_of_election",
  valgrund_id = "election_basis_id",
  valgrund_text = "election_basis",
  ersattargrupp = "substitute_group",
  antal_valkretsar = "constituencies_count",
  antal_valomraden = "electoral_areas_count",
  antal_listor = "lists_count",
  antal_partier = "parties_count",
  antal_valtyper = "election_types_count",
  antal_namn = "name_variants_count",
  namn_varierar = "name_varies",
  flera_valkretsar = "multiple_constituencies",
  flera_valomraden = "multiple_electoral_areas",
  flera_listor = "multiple_lists",
  flera_partier = "multiple_parties",
  flera_valtyper = "multiple_election_types",
  oppen_lista = "open_list",
  pa_namnvalsedel = "on_name_ballot",
  valsedelsstatus = "ballot_status",
  listnummer = "list_number",
  valkretsbeteckning_pa_valsedeln = "ballot_constituency_label",
  ordning = "ballot_order",
  anmalda_kandidater = "candidates_registered",
  samtycke = "consent",
  forklaring = "candidate_declaration",
  valsedelsuppgift = "ballot_info",
  antal_valsedlar_lista = "list_ballots_ordered",
  giltig = "valid",
  ledamot_kandidatnummer = "member_candidate_number",
  ledamot_namn = "member_name",
  ersattare_kandidatnummer = "substitute_candidate_number",
  ersattare_namn = "substitute_name",
  ersattarordning = "substitute_order"
)

.public_name_en <- function(svenska) {
  out <- unname(.public_name_base_en[svenska])
  # Source-oriented *_fg and diff_* fields use one consistent public convention:
  # previous_* and *_change (an absolute difference, never a relative percent).
  previous <- is.na(out) & endsWith(svenska, "_fg")
  if (any(previous)) {
    stem <- substr(svenska[previous], 1L, nchar(svenska[previous]) - 3L)
    translated <- unname(.public_name_base_en[stem])
    if (anyNA(translated)) stop("Incomplete English column mapping.", call. = FALSE)
    out[previous] <- paste0("previous_", translated)
  }
  difference <- is.na(out) & startsWith(svenska, "diff_")
  if (any(difference)) {
    stem <- substring(svenska[difference], 6L)
    translated <- unname(.public_name_base_en[stem])
    if (anyNA(translated)) stop("Incomplete English column mapping.", call. = FALSE)
    out[difference] <- paste0(translated, "_change")
  }
  if (anyNA(out) || anyDuplicated(out)) {
    stop("Incomplete or ambiguous English column mapping.", call. = FALSE)
  }
  out
}

.check_output_language <- function(language) {
  if (!is.character(language) || length(language) != 1L || is.na(language) ||
      !language %in% c("en", "sv")) {
    stop("`names` must be exactly 'en' or 'sv'.", call. = FALSE)
  }
  invisible(language)
}

.public_output_names <- function(data, language) {
  .check_output_language(language)
  if (language == "en") base::names(data) <- .public_name_en(base::names(data))
  data
}

# Canonical Parquet has one English vocabulary. The three base-only columns
# below are technical fields; every shared concept uses the public name map.
.canonical_base_names_en <- c(node_id = "node_id",
                              parti_complete = "party_complete",
                              list_complete = "list_complete")

.canonical_names_en <- function(data) {
  original <- base::names(data)
  technical <- startsWith(original, ".")
  base_only <- original %in% base::names(.canonical_base_names_en)
  translated <- original
  translated[base_only] <- unname(.canonical_base_names_en[original[base_only]])
  translated[!technical & !base_only] <- .public_name_en(
    original[!technical & !base_only])
  if (anyDuplicated(translated)) stop("Ambiguous canonical column mapping.", call. = FALSE)
  base::names(data) <- translated
  data
}

.canonical_names_sv <- function(data) {
  swedish <- base::names(.public_name_base_en)
  derived <- c(paste0(swedish, "_fg"), paste0("diff_", swedish))
  candidates <- c(swedish, derived)
  english <- .public_name_en(candidates)
  inverse <- stats::setNames(candidates, english)
  inverse <- c(inverse, stats::setNames(base::names(.canonical_base_names_en),
                                       .canonical_base_names_en))
  current <- base::names(data)
  technical <- startsWith(current, ".")
  if (any(!technical & !current %in% base::names(inverse))) {
    stop("Unknown English canonical column: ",
         paste(current[!technical & !current %in% base::names(inverse)],
               collapse = ", "), call. = FALSE)
  }
  current[!technical] <- unname(inverse[current[!technical]])
  base::names(data) <- current
  data
}

.english_output_language <- function(names) {
  if (is.null(names)) names <- getOption("swelections.names", "en")
  .check_output_language(names)
  names
}
