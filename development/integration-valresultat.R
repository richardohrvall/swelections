# Kör uttryckligen med en read-only rådatamapp som första argument.
# Inga råfiler kopieras; rapporten innehåller endast kontrollresultat/utdrag.
.libPaths(c(file.path(getwd(), ".r-lib"), .libPaths()))
pkgload::load_all(".", quiet = TRUE)
root <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(!is.na(root), dir.exists(root))
options(valresultat.resultatsamling_2026 = "genrep2026", valresultat.data_dir = root)
ns <- asNamespace("swelections")
run <- function() {
  blocked <- function(...) stop("BLOCKERAD: nat/skrift till raarkiv")
  testthat::local_mocked_bindings(download_val_file = blocked, archive_val_file = blocked,
                                val_remote_url = blocked, .package = "swelections")
  testthat::local_mocked_bindings(download.file = blocked, .package = "utils")
  index <- .read_resultatindex_2026(source = "local", data_dir = root)
  local_root <- file.path(root, "2026", "genrep2026")
  paths <- list.files(local_root, "\\.zip$", recursive = TRUE)
  files <- file.path(local_root, paths)
  before <- tools::md5sum(c(file.path(local_root, "index.md5"), files))
  on.exit(stopifnot(identical(before, tools::md5sum(names(before)))), add = TRUE)
  cat("READ-ONLY INVENTERING\n")
  for (file in files) {
    cat("\n", file, "\n", sep = "")
    print(utils::unzip(file, list = TRUE)[c("Name", "Length")], row.names = FALSE)
  }
  resultat <- list()
  sammanfattning <- list()
  schema <- utils::read.table("tests/testthat/fixtures/valresultat-schema.txt", col.names = c("namn", "typ"))
  for (path in paths) {
    val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", path)
    kallaer <- if (val == "KF") c("M", "D") else c("M", "U", "D")
    for (kalla in kallaer) {
      cat("\nLASER ", path, " [", kalla, "]\n", sep = "")
      flush.console()
      raw <- .read_valresultat_raw(file.path(local_root, path), kalla, val, "slutlig")
      parsed <- switch(kalla, D = parse_rostfordelning_2026(raw),
        U = parse_underordnad_summering_2026(raw), M = parse_rostfordelning_mandat_2026(raw))
      nivaer <- switch(kalla, D = "valdistrikt", U = c("kommun", "kommunvalkrets"),
        M = switch(val, RD = c("riket", "riksdagsvalkrets"),
                   RF = c("region", "regionvalkrets"), KF = c("kommun", "kommunvalkrets")))
      for (niva in nivaer) {
        tag <- paste(val, basename(path), niva, sep = "/")
        cat("ANROP ", tag, "\n", sep = "")
        stopifnot(identical(.valresultat_kalla(val, niva), kalla))
        nodes <- switch(kalla,
          D = raw$valdistrikt,
          M = if (niva %in% c("riket", "region", "kommun")) list(raw$valomrade) else raw$valomrade$valkretsLista,
          U = if (niva == "kommun") raw$kommuner else unlist(lapply(raw$kommuner, function(x) x$kommunvalkretsar), recursive = FALSE))
        other <- lapply(nodes, function(x) x$rostfordelning$rosterPaverkaMandat$rosterOvrigaPartier)
        present <- !vapply(other, is.null, logical(1))
        zeros <- vapply(other, function(x) identical(as_int_na(x$antalRoster), 0L), logical(1))
        cat("RAKALLA: omraden=", length(nodes), "; ovriga finns=", sum(present),
            "; saknas/null=", sum(!present), "; explicit noll=", sum(zeros), "\n", sep = "")
        # API-anrop med verklig lokal filidentitet. RF/KF använder ett tydligt
        # avgränsat index i minnet; detta är inte ett komplett landsanrop.
        api <- tryCatch(local({
          testthat::local_mocked_bindings(
            .read_resultatindex_2026 = function(...) index[index$path == path, ],
            .read_valresultat_raw = function(file, kalla, val, rakning) {
              stopifnot(identical(normalizePath(file), normalizePath(file.path(local_root, path))))
              raw
            }, .package = "swelections")
          valresultat(val = val, niva = niva, source = "local", data_dir = root, progress = FALSE)
        }), error = identity)
        if (inherits(api, "error")) {
          cat("FEL: ", conditionMessage(api), "\n", sep = "")
          next
        }
        stopifnot(identical(names(api), schema$namn), identical(unname(vapply(api, typeof, "")), schema$typ))
        stopifnot(!any(vapply(api, is.list, logical(1))))
        stopifnot(sum(api$ovriga_partier) == sum(present),
                  sum(api$ovriga_partier & api$antal_roster == 0L, na.rm = TRUE) == sum(zeros))
        .valresultat_check_key(api, niva)
        # Jämför med den tidigare parsern, utan att jämföra dess artificiella
        # övriga-rader eller de rapporteringskolumner som adaptern harmoniserar.
        baseline <- parsed
        if (nrow(baseline)) baseline <- baseline[baseline$geografiniva == niva, ]
        key <- .valresultat_geo_key(niva)
        if (kalla == "M" && val == "KF" && nrow(baseline)) {
          baseline$kommunkod <- baseline$valomradeskod
          baseline$kommunvalkretskod <- baseline$valkretskod
        }
        common <- intersect(names(api), names(baseline))
        measures <- common[grepl("^(antal_roster|andel_roster|totalt_antal_roster|giltiga_roster|ogiltiga_roster|blanka_roster|ovriga_ogiltiga|diff_|valdel|over_sparr|roster_ej_anmalt)", common)]
        compare_key <- unique(c(key, "partikod", "ovriga_partier"))
        if (nrow(api)) {
          matched <- dplyr::left_join(api[c(compare_key, measures)], baseline[c(compare_key, measures)],
                                     by = compare_key, suffix = c(".api", ".parser"), relationship = "one-to-one")
          stopifnot(nrow(matched) == nrow(api))
          for (nm in measures) stopifnot(identical(matched[[paste0(nm, ".api")]], matched[[paste0(nm, ".parser")]]))
        }
        areas <- api[!duplicated(api[c("geografiniva", key)]), ]
        sumcheck <- api |>
          dplyr::summarise(summa = sum(antal_roster), giltiga = dplyr::first(giltiga_roster),
                           .by = dplyr::all_of(c("geografiniva", key)))
        invalid <- function(x) sum(!is.na(x) & !x)
        totalfel <- invalid(areas$totalt_antal_roster == areas$giltiga_roster + areas$ogiltiga_roster)
        partifel <- invalid(sumcheck$summa == sumcheck$giltiga)
        ogiltigafel <- invalid(areas$ogiltiga_roster == areas$blanka_roster + areas$roster_ej_anmalt_deltagande + areas$ovriga_ogiltiga)
        andelsfel <- invalid(abs(api$andel_roster - 100 * api$antal_roster / api$giltiga_roster) <= 0.011)
        if (kalla != "M") stopifnot(all(is.na(api$over_sparr)))
        stopifnot(all(is.na(api$over_sparr[api$ovriga_partier])))
        sammanfattning[[tag]] <- data.frame(val, kod = sub(".*_([^_]+)_[A-Z]{2}\\.zip$", "\\1", path), kalla, niva,
          rader = nrow(api), omraden = nrow(areas), totalfel, partifel, ogiltigafel, andelsfel,
          ovriga = sum(api$ovriga_partier), ovriga_noll = sum(api$ovriga_partier & api$antal_roster == 0, na.rm = TRUE),
          sparr_ifylld = sum(!is.na(api$over_sparr)))
        print(sammanfattning[[tag]], row.names = FALSE)
        resultat[[tag]] <- api
        rm(baseline)
      }
      rm(raw, parsed)
      gc()
    }
  }
  cat("\nSAMMANFATTNING\n")
  print(dplyr::bind_rows(sammanfattning), row.names = FALSE)
  cat("\nOFFICIELLA NIVAER MOT VARANDRA (ENDAST LOKALT TACKTA OMRADEN)\n")
  for (path in paths) {
    val <- sub(".*_([A-Z]{2})\\.zip$", "\\1", path)
    get_result <- function(niva) resultat[[paste(val, basename(path), niva, sep = "/")]]
    main <- c(RD = "riket", RF = "region", KF = "kommun")[[val]]
    parent <- get_result(main)
    if (is.null(parent)) next
    for (niva in c("valdistrikt", "kommun", "kommunvalkrets", "riksdagsvalkrets", "regionvalkrets")) {
      low <- get_result(niva)
      if (is.null(low) || !nrow(low) || niva == main) next
      # U:s kommunvalkretsar täcker bara valkretsindelade kommuner.
      upper <- if (niva == "kommunvalkrets" && val != "KF") get_result("kommun") else parent
      groups <- c(if (niva == "kommunvalkrets" && val != "KF") "kommunkod", "partikod", "ovriga_partier")
      if ("kommunkod" %in% groups) upper <- upper[upper$kommunkod %in% low$kommunkod, ]
      lower_sum <- dplyr::summarise(low, roster = sum(antal_roster), .by = dplyr::all_of(groups))
      upper_sum <- dplyr::summarise(upper, roster = sum(antal_roster), .by = dplyr::all_of(groups))
      comparison <- dplyr::full_join(lower_sum, upper_sum, by = groups, suffix = c("_lower", "_upper"))
      # Frånvarande partirad redovisas separat; endast numerisk kontroll
      # kan betrakta den som noll. Ingen sådan omkodning sker i API-utdata.
      absent <- sum(is.na(comparison$roster_lower) | is.na(comparison$roster_upper))
      diff <- dplyr::coalesce(comparison$roster_lower, 0L) - dplyr::coalesce(comparison$roster_upper, 0L)
      cat(basename(path), niva, "->", if ("kommunkod" %in% groups) "indelade kommuner" else main,
          ": differenser=", sum(diff != 0), "; ensidiga partirader=", absent, "\n")
      if (any(diff != 0)) print(utils::head(comparison[diff != 0, ], 8))
    }
  }
  cat("\nDEFAULTS MED OFORANDRAT LOKALT INDEX\n")
  for (val in c("RD", "RF", "KF")) {
    out <- tryCatch(valresultat(val = val, source = "local", data_dir = root, progress = FALSE), error = identity)
    cat(val, ": ")
    if (inherits(out, "error")) cat(conditionMessage(out), "\n") else {
      cat(nrow(out), "rader; niva", unique(out$geografiniva), "\n")
      if (val == "RD") dplyr::glimpse(out, width = 90)
    }
  }
  cat("\nKF LOKALT URVAL (INTE KOMPLETT STANDARDANROP)\n")
  kf <- dplyr::bind_rows(resultat[grepl("^KF/.*/kommun$", names(resultat))])
  print(utils::head(kf[c("valomradeskod", "valomradesnamn", "partikod", "partiforkortning", "antal_roster", "andel_roster")]))
  stopifnot(identical(before, tools::md5sum(names(before))))
  cat("\nMD5 oforandrat for index och samtliga lokala genrep-ZIP.\n")
  invisible(resultat)
}
resultat <- run()
