# Public column names are translated only after a complete Swedish result has
# been constructed and validated. Values, types, keys and row order are untouched.
.public_name_base_en <- c(
  valtillfalle = "election_event",
  valar = "election_year",
  valklass = "election_class",
  valtyp = "election_type",
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
  valomradeskod = "electoral_area_code",
  valomradesnamn = "electoral_area_name",
  valkretskod = "constituency_code",
  valkretsnamn = "constituency_name",
  kommunvalkretskod = "municipal_constituency_code",
  kommunvalkretsnamn = "municipal_constituency_name",
  personvalsomradeskod = "personal_vote_area_code",
  personvalsomradesnamn = "personal_vote_area_name",
  raknat = "counted",
  rapporteringstid = "reporting_time",
  senaste_uppdateringstid = "last_update_time",
  senaste_uppdateringstid_omrade = "area_last_update_time",
  antal_uppdateringar = "update_count",
  antal_valdistrikt_raknade = "districts_counted",
  antal_valdistrikt_som_ska_raknas = "districts_to_count",
  antal_valdistrikt_raknade_omrade = "area_districts_counted",
  antal_valdistrikt_som_ska_raknas_omrade = "area_districts_to_count",
  antal_rostberattigade_raknade = "eligible_voters_in_counted_districts",
  partibeteckning = "party_designation",
  partiforkortning = "party_abbreviation",
  partikod = "party_code",
  partifarg = "party_color",
  fargkod = "color_code",
  ordningsnummer = "party_order_number",
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
  roster_ej_anmalt_deltagande = "votes_no_participation_notification",
  andel_ej_anmalt_deltagande = "vote_share_no_participation_notification",
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
  antal_tomma_stolar = "vacant_seats",
  kandidatnummer = "candidate_number",
  namn = "name",
  kon = "sex",
  alder_pa_valdagen = "age_on_election_day",
  folkbokforingskommun = "registered_municipality_code",
  antal_personroster = "personal_votes",
  antal_personroster_totalt = "total_personal_votes",
  antal_partiroster = "party_votes",
  andel_personroster = "personal_vote_share",
  antal_listroster = "list_votes",
  andel_personroster_lista = "list_personal_vote_share",
  kvalificerad_personval = "qualified_for_personal_election",
  antal_personvalsomraden = "personal_vote_areas_count",
  invald = "elected",
  invald_valomradeskod = "elected_electoral_area_code",
  invald_valomradesnamn = "elected_electoral_area_name",
  invald_valkretskod = "elected_constituency_code",
  invald_valkretsnamn = "elected_constituency_name",
  invalsordning = "election_order",
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
  valkretsbeteckning_pa_valsedeln = "constituency_designation_on_ballot",
  ordning = "ballot_order",
  anmalda_kandidater = "registered_candidates",
  samtycke = "consent",
  forklaring = "declaration",
  valsedelsuppgift = "ballot_information",
  antal_valsedlar_lista = "ballots_for_list",
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

.english_output_language <- function(names) {
  if (is.null(names)) names <- getOption("swelections.names", "en")
  .check_output_language(names)
  names
}
