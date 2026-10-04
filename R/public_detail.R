# Presentation is deliberately downstream of raw/canonical harmonisation. The
# published Parquet schema and source-oriented parsers are not changed here.
.check_detail <- function(detail) {
  if (!is.character(detail) || length(detail) != 1L || is.na(detail) ||
      !detail %in% c("standard", "full")) {
    stop("`detail` must be exactly 'standard' or 'full'.", call. = FALSE)
  }
  detail
}

.public_copy <- function(data, target, source, rows = rep(TRUE, nrow(data))) {
  if (!source %in% names(data) || target %in% names(data))
    return(data)
  value <- data[[source]]
  value[!rows] <- NA
  data[[target]] <- value
  data
}

# Split the KF meaning from the shared source field before projection. Preserve
# that field explicitly in full, including technical codes for undivided areas.
.public_constituency <- function(data, prefix = "", elections = unique(data$valtyp)) {
  if (!"valtyp" %in% names(data)) return(data)
  kf <- data$valtyp %in% "KF"
  if (!"KF" %in% elections) return(data)
  code <- paste0(prefix, "valkretskod")
  if (!code %in% names(data)) return(data)
  municipal <- kf & !is.na(data[[code]]) & !grepl("00$", data[[code]])
  for (suffix in c("kod", "namn")) {
    source <- paste0(prefix, "valkrets", suffix)
    data <- .public_copy(data, paste0("kall_", source), source)
    target <- paste0(prefix, "kommunvalkrets", suffix)
    if (source %in% names(data) && !target %in% names(data)) {
      data[[target]] <- data[[source]]
      data[[target]][!municipal] <- NA_character_
    }
    if (source %in% names(data)) data[[source]][kf] <- NA_character_
  }
  data
}

.public_geography <- function(data, table, elections = unique(data$valtyp)) {
  if (table %in% c("results", "seats", "preference_votes", "substitutes")) {
    rf <- if ("valtyp" %in% names(data)) data$valtyp == "RF" else FALSE
    kf <- if ("valtyp" %in% names(data)) data$valtyp == "KF" else FALSE
    if ("RF" %in% elections) {
      data <- .public_copy(data, "regionkod", "valomradeskod", rf)
      data <- .public_copy(data, "regionnamn", "valomradesnamn", rf)
    }
    if ("KF" %in% elections) {
      data <- .public_copy(data, "kommunkod", "valomradeskod", kf)
      data <- .public_copy(data, "kommunnamn", "valomradesnamn", kf)
    }
    data <- .public_constituency(data, elections = elections)
    if (table == "substitutes") {
      for (suffix in c("kod", "namn")) {
        source <- paste0("valomrades", suffix)
        data <- .public_copy(data, paste0("kall_", source), source)
        # RF/KF parent roles are represented by region/municipality fields.
        # Keep only RD's distinct surrounding area in the generic public field.
        if (source %in% names(data)) data[[source]][rf | kf] <- NA_character_
      }
    }
  }
  if (table %in% c("candidacies", "candidates")) {
    for (suffix in c("kod", "namn")) {
      data <- .public_copy(data, paste0("kandidatur_valomrades", suffix),
                           paste0("valomrades", suffix))
      data <- .public_copy(data, paste0("kandidatur_valkrets", suffix),
                           paste0("valkrets", suffix))
    }
  }
  if (table %in% c("candidacies", "candidates"))
    data <- .public_constituency(data, "kandidatur_", elections)
  if (table %in% c("candidates", "elected"))
    data <- .public_constituency(data, "invald_", elections)
  data
}

.standard_geography <- c(
  "valdistriktskod", "valdistriktsnamn", "kommunkod", "kommunnamn",
  "lankod", "lannamn", "regionkod", "regionnamn", "valkretskod",
  "valkretsnamn", "kommunvalkretskod", "kommunvalkretsnamn",
  "personvalsomradeskod", "personvalsomradesnamn"
)

.standard_fields <- list(
  results = c(
    "valar", "valtyp", "rakningstillfalle", "geografiniva",
    .standard_geography,
    "partikod", "partibeteckning", "partiforkortning", "ovriga_partier",
    "antal_roster", "andel_roster", "totalt_antal_roster", "giltiga_roster",
    "ogiltiga_roster", "blanka_roster", "antal_rostberattigade", "valdel",
    "antal_roster_fg", "andel_roster_fg", "valdel_fg",
    "diff_antal_roster", "diff_andel_roster", "diff_valdel",
    "status_jamforelse", "raknat", "antal_valdistrikt_raknade_omrade",
    "antal_valdistrikt_som_ska_raknas_omrade", "antal_valdistrikt_raknade",
    "antal_valdistrikt_som_ska_raknas",
    "antal_rostberattigade_raknade"
  ),
  seats = c(
    "valar", "valtyp", "rakningstillfalle", "geografiniva",
    .standard_geography,
    "partikod", "partibeteckning", "partiforkortning", "antal_mandat",
    "antal_mandat_fg", "diff_antal_mandat", "totalt_antal_mandat",
    "antal_tomma_stolar", "antal_fasta_mandat", "antal_utjamningsmandat",
    "status_jamforelse"
  ),
  candidacies = c(
    "valar", "valtyp", "kandidatnummer", "namn", "partikod",
    "partibeteckning", "partiforkortning", "kandidatur_valomradeskod",
    "kandidatur_valomradesnamn", "kandidatur_valkretskod",
    "kandidatur_valkretsnamn", "kandidatur_kommunvalkretskod",
    "kandidatur_kommunvalkretsnamn", "listnummer", "ordning", "giltig",
    "oppen_lista", "pa_namnvalsedel", "folkbokforingskommun"
  ),
  candidates = c(
    "valar", "valtyp", "kandidatnummer", "namn", "partikod",
    "partibeteckning", "partiforkortning", "antal_personroster_totalt",
    "kvalificerad_personval", "invald", "invald_valomradeskod",
    "invald_valomradesnamn", "invald_valkretskod", "invald_valkretsnamn",
    "invald_kommunvalkretskod", "invald_kommunvalkretsnamn",
    "invalsordning", "valgrund_text", "ersattargrupp", "kon",
    "alder_pa_valdagen", "folkbokforingskommun",
    "kandidatur_valomradeskod", "kandidatur_valomradesnamn",
    "kandidatur_valkretskod", "kandidatur_valkretsnamn",
    "kandidatur_kommunvalkretskod", "kandidatur_kommunvalkretsnamn",
    "antal_valomraden", "antal_valkretsar", "antal_listor", "oppen_lista",
    "pa_namnvalsedel"
  ),
  elected = c(
    "valar", "valtyp", "kandidatnummer", "namn", "partikod",
    "partibeteckning", "partiforkortning", "antal_personroster_totalt",
    "kvalificerad_personval", "invald", "invald_valomradeskod",
    "invald_valomradesnamn", "invald_valkretskod", "invald_valkretsnamn",
    "invald_kommunvalkretskod", "invald_kommunvalkretsnamn",
    "invalsordning", "valgrund_text", "ersattargrupp", "kon",
    "alder_pa_valdagen", "folkbokforingskommun"
  ),
  substitutes = c(
    "valar", "valtyp", "geografiniva", "partikod", "partibeteckning",
    "partiforkortning", "ledamot_kandidatnummer", "ledamot_namn",
    "ersattare_kandidatnummer", "ersattare_namn", "ersattarordning",
    "ersattargrupp", "valgrund_text",
    # The electoral area is the parent of a constituency-level substitute
    # relation; it is distinct from the constituency where the relation applies.
    "valomradeskod", "valomradesnamn", "valkretskod", "valkretsnamn",
    "kommunkod", "kommunnamn", "regionkod", "regionnamn",
    "kommunvalkretskod", "kommunvalkretsnamn"
  ),
  preference_votes = c(
    "valar", "valtyp", "geografiniva",
    .standard_geography, "partikod", "partibeteckning",
    "partiforkortning", "kandidatnummer", "namn", "antal_personroster",
    "antal_partiroster", "andel_personroster", "kvalificerad_personval",
    "listnummer", "antal_listroster", "andel_personroster_lista",
    "valdistriktstyp"
  )
)

.public_detail <- function(data, table, detail, elections = unique(data$valtyp)) {
  data <- .public_geography(data, table, elections)
  if (detail == "full") return(data)
  keep <- intersect(.standard_fields[[table]], names(data))
  if (!any(elections %in% c("RD", "RF"))) {
    generic <- c("valkretskod", "valkretsnamn", "kandidatur_valkretskod",
                 "kandidatur_valkretsnamn", "invald_valkretskod",
                 "invald_valkretsnamn")
    keep <- setdiff(keep, generic)
  }
  if (table == "substitutes") {
    # RF/KF parents already have specific region/municipality identifiers.
    # RD's surrounding electoral area remains available as source context.
    if (!"RD" %in% elections)
      keep <- setdiff(keep, c("valomradeskod", "valomradesnamn"))
  }
  if (table == "preference_votes" && "personvalsomradeskod" %in% names(data)) {
    # These aliases describe the requested preference-vote area, regardless
    # of observed rows. RD/RF may additionally carry distinct municipal context.
    keep <- setdiff(keep, c("valkretskod", "valkretsnamn"))
    if (!any(elections %in% c("RD", "RF")))
      keep <- setdiff(keep, c("kommunvalkretskod", "kommunvalkretsnamn"))
  }
  data[, keep, drop = FALSE]
}
