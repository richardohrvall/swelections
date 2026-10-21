# Approved fixed-election correction, not a mandate-period appointment.
# VPN 877-2018 (2018-12-12) and the 2022-10-31 original-holder history:
# KF 2303 / 0110, chair 3, candidate 534885, electoral start 2018-09-09.
# Raw files are never rewritten. Public historical candidate names remain NA.
.xml2018_ragunda_candidacy <- function(x) {
  scope <- x$valtyp == "KF" & x$valomradeskod == "2303" & x$partikod == "0110"
  rows <- which(scope)
  if (!length(rows) || any(x$kandidatnummer[rows] == "534885")) return(x)
  row <- x[NA_integer_, , drop = FALSE]
  shared <- c("valtillfalle", "valar", "valtyp", "valomradeskod",
    "valomradesnamn", "valkretskod", "valkretsnamn", "partibeteckning",
    "partiforkortning", "partikod")
  row[shared] <- x[rows[[1L]], shared]
  row$kandidatnummer <- "534885"
  # History/current list and position, not evidence of a printed ballot.
  row$listnummer <- "17638"
  row$ordning <- 3L
  row$giltig <- TRUE
  row$samtycke <- "ja"
  row$oppen_lista <- TRUE
  dplyr::bind_rows(x, row)
}

.xml2018_ragunda_elected <- function(doc, val) {
  if (val != "KF" || .xml2018_attr(xml2::xml_root(doc), "VALDAG") != "20180909" ||
      !identical(.xml2018_attr(.xml2018_find_first(doc, "./KOMMUN"), "KOD"), "2303"))
    return(doc)
  party <- .xml2018_find_all(doc,
    './KOMMUN/KRETS_KOMMUN/GILTIGA[@PARTI="SD"]')
  if (length(party) != 1L || .xml2018_int(party[[1L]], "MANDAT") != 3L)
    stop("Ragunda correction requires the verified three-seat SD result.", call. = FALSE)
  holder <- .xml2018_find_all(party, './GRUPP_VALDA/VALD[@ORDNING="3"]')
  if (length(holder) != 1L)
    stop("Ragunda correction requires exactly one original third seat.", call. = FALSE)
  id <- .xml2018_attr(holder[[1L]], "KANDNR")
  if (identical(id, "534885")) return(doc)
  if (!is.na(id) || !identical(.xml2018_attr(holder[[1L]], "NAMN"), "Kunde inte utses"))
    stop("Ragunda correction conflicts with the supplied elected relation.", call. = FALSE)
  xml2::xml_set_attr(holder[[1L]], "KANDNR", "534885")
  xml2::xml_set_attr(holder[[1L]], "NAMN", NA_character_)
  # Original order/group/basis are retained; no successor/substitute is inferred.
  doc
}

.xml2018_ragunda_votes <- function(raw, niva) {
  geo <- raw$geo
  scope <- geo$valtyp == "KF" & geo$valomradeskod == "2303"
  if (niva == "valdistrikt") scope <- scope & geo$valdistriktskod == "23030409"
  rows <- which(scope)
  if (!length(rows)) return(raw)
  if (length(rows) != 1L) stop("Ambiguous Ragunda correction geography.", call. = FALSE)
  party <- raw$parti[raw$parti$node_id == geo$node_id[rows] &
    raw$parti$valtyp == "KF" & raw$parti$partikod == "0110", , drop = FALSE]
  if (nrow(party) != 1L) stop("Missing Ragunda correction party.", call. = FALSE)
  old <- raw$roster[raw$roster$node_id == party$node_id &
    raw$roster$valtyp == "KF" & raw$roster$partikod == "0110" &
    raw$roster$kandidatnummer == "534885", , drop = FALSE]
  if (nrow(old)) {
    if (nrow(old) != 1L || old$antal_personroster != 5L)
      stop("Ragunda correction conflicts with supplied preference votes.", call. = FALSE)
    return(raw)
  }
  fields <- c("valtyp", "valomradeskod", "personvalsomradeskod", "partikod", "node_id")
  row <- party[fields]
  row$kandidatnummer <- "534885"
  row$antal_personroster <- 5L
  row$kvalificerad_personval <- FALSE
  # VPN identifies Stugubyn and the candidate count. It does not identify the
  # ballot-list allocation (four name ballots plus one party ballot). Preserve
  # all original validated list rows; never allocate these five votes to a list.
  raw$roster <- dplyr::bind_rows(raw$roster, row)
  raw
}

.xml2018_ragunda_provenance <- function() list(
  reference = "Valprovningsnamnden 877-2018",
  decision_date = "2018-12-12", electoral_start = "2018-09-09",
  election = "KF", municipality = "2303", party = "0110", seat = 3L,
  candidate_number = "534885", preference_votes = 5L, district = "23030409",
  reported_list = "0110-17638", reported_position = 3L,
  implementing_decision_date = NA_character_,
  preference_list_allocation = "Not established; original list rows preserved",
  decision_url = paste0("https://www.riksdagen.se/sv/dokument-och-lagar/",
    "dokument/valprovningsnamndens-beslut/",
    "mandatfordelning-inom-parti-bifall-forordnande_h6d34c8b78/"),
  decision_snapshot_sha256 = "8a73dcc2265abe3285240a52ca8a7f596d374cde0c0261272c1633d9af912ba3",
  history_source = "ledamoter_med_historik_20221031.skv",
  history_sha256 = "17e02228c522e558eaceeeef7aabb70e13c42379b50ac9a8ecbee638064bb835",
  current_source = "nuvarande_ledamoter_20221031.skv",
  current_sha256 = "bf0aa386a8a4411ea5f90b8971333d2752245654042b2936710892be09b52798",
  expanded_source = "ledamoter_och_ersattare2_20221031.skv",
  expanded_sha256 = "53d407becb584eca0b58c017dfcf4937390a14e54f226f96843a10e8e552a93b"
)
