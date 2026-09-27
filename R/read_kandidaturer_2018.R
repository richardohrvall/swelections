.read_kandidaturer_2018 <- function(file) {
  if (grepl("^https?://", file)) {
    tmp <- tempfile(fileext = ".skv")
    on.exit(unlink(tmp), add = TRUE)
    utils::download.file(file, tmp, mode = "wb", quiet = TRUE)
    file <- tmp
  }
  md5 <- tolower(unname(tools::md5sum(file)))
  komplett <- md5 %in% c(
    "9855ac4280c2a5165389a88c647ae49f", # nu publicerad, gallrad
    "02200d7ea83ad3c116ddf574ec9df9ad"  # verifierad \u00e4ldre forskningssnapshot
  )
  raw <- readr::read_delim(
    file, delim = ";", locale = readr::locale(encoding = "ISO-8859-1"),
    col_types = readr::cols(.default = readr::col_character()),
    na = "", trim_ws = FALSE, show_col_types = FALSE, progress = FALSE
  ) |> janitor::clean_names()
  required <- c(
    "valtyp", "valomradeskod", "valomradesnamn", "valkretskod",
    "valkretsnamn", "partibeteckning", "partiforkortning", "partikod",
    "valsedelsstatus", "listnummer", "ordning", "anmkand", "samtycke",
    "forklaring", "kandidatnummer", "namn", "alder_pa_valdagen", "kon",
    "folkbokforingsort", "valsedelsuppgift", "ant_best_vals", "giltig"
  )
  saknas <- setdiff(required, names(raw))
  if (length(saknas)) {
    stop("2018 \u00e5rs kandidaturfil saknar f\u00e4lt: ", paste(saknas, collapse = ", "),
         ".", call. = FALSE)
  }
  kod <- function(x, bredd) {
    ok <- !is.na(x) & grepl("^[0-9]+$", x)
    x[ok] <- mapply(function(value, width) {
      sprintf(paste0("%0", width, "d"), as.integer(value))
    }, x[ok], rep_len(bredd, length(x))[ok], USE.NAMES = FALSE)
    x
  }
  raw <- raw |>
    dplyr::transmute(
      valtyp = dplyr::recode_values(valtyp, "R" ~ "RD", "L" ~ "RF", "K" ~ "KF"),
      valomradeskod = kod(valomradeskod,
                          dplyr::if_else(valtyp == "KF", 4L, 2L)),
      valomradesnamn, valkretskod = kod(valkretskod, 2L), valkretsnamn,
      partibeteckning, partiforkortning, partikod, valsedelsstatus,
      listnummer, ordning, anmaldakandidater = raw$anmkand, samtycke,
      forklaring, kandidatnummer,
      # Namnkontraktet är oberoende av lokal snapshot och används aldrig som nyckel.
      namn = NA_character_, alder_pa_valdagen, kon,
      folkbokforingskommun = raw$folkbokforingsort, valsedelsuppgift,
      antal_valsedlar_for_den_specifika_listan = raw$ant_best_vals, giltig,
      valkretsbeteckning_pa_valsedeln = NA_character_
    )
  out <- parse_kandidaturer_2026(
    raw, ar = 2018L, namnvalsedlar_kompletta = komplett
  )
  if (anyDuplicated(out[c("valtyp", "valomradeskod", "valkretskod", "partikod",
                          "listnummer", "ordning", "kandidatnummer")])) {
    stop("Duplicerad kandidatur i 2018 \u00e5rs k\u00e4lla.", call. = FALSE)
  }
  out
}
