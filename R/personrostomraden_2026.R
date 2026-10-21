.personval_geografiniva_2026 <- function(valtyp, valkretsindelad) {
  if (valkretsindelad) {
    dplyr::recode_values(
      valtyp,
      "RD" ~ "riksdagsvalkrets",
      "RF" ~ "regionvalkrets",
      "KF" ~ "kommunvalkrets",
      default = NA_character_
    )
  } else {
    dplyr::recode_values(
      valtyp,
      "RD" ~ "riket",
      "RF" ~ "region",
      "KF" ~ "kommun",
      default = NA_character_
    )
  }
}

.personval_nodstatus_2026 <- function(raw, obj) {
  if (!.personrost_objekt(obj) ||
      !"kvalificeradeForPersonvalLista" %in% names(obj) ||
      is.null(obj$kvalificeradeForPersonvalLista)) return(FALSE)

  lista <- obj$kvalificeradeForPersonvalLista
  if (!.personrost_array(lista) ||
      !identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), "slutlig") ||
      !.personrost_heltal(obj$antalValdistriktRaknade) ||
      !.personrost_heltal(obj$antalValdistriktSomSkaRaknas) ||
      obj$antalValdistriktRaknade != obj$antalValdistriktSomSkaRaknas) return(NA)

  giltig <- vapply(lista, function(r) {
    .personrost_objekt(r) && .personrost_id(r$partikod) &&
      (.personrost_id(r$kandidatnummer) || .personrost_heltal(r$kandidatnummer)) &&
      .personrost_heltal(r$antalPersonroster) &&
      is.numeric(r$andelPersonroster) && length(r$andelPersonroster) == 1L &&
      !is.na(r$andelPersonroster) && is.finite(r$andelPersonroster)
  }, logical(1))
  if (!all(giltig)) return(NA)

  id <- vapply(lista, function(r) {
    paste(as_chr_na(r$partikod), as_chr_na(r$kandidatnummer))
  }, "")
  if (anyDuplicated(id)) NA else TRUE
}

.personvalsomraden_mandat_2026 <- function(raw) {
  valtyp <- as_chr_na(raw$valtyp)
  valomrade <- raw$valomrade
  valomradeskod <- as_chr_na(valomrade$kod)
  valomradesnamn <- as_chr_na(valomrade$namn)
  valkretsar <- valomrade$valkretsLista
  indelad <- .personrost_array(valkretsar) && length(valkretsar) > 0L

  if (!.personrost_id(valtyp) || !valtyp %in% c("RD", "RF", "KF") ||
      !.personrost_id(valomradeskod) || !.personrost_id(valomradesnamn)) {
    stop("Mandatfilen saknar ett giltigt valomr\u00e5de f\u00f6r personr\u00f6ster.", call. = FALSE)
  }

  if (!is.null(valkretsar) && !.personrost_array(valkretsar)) {
    stop("Mandatfilens valkretsLista har ogiltig struktur.", call. = FALSE)
  }

  noder <- if (indelad) valkretsar else list(valomrade)
  koder <- if (indelad) {
    vapply(noder, function(x) as_chr_na(x$kod), "")
  } else {
    valomradeskod
  }
  namn <- if (indelad) {
    vapply(noder, function(x) as_chr_na(x$namnValkrets), "")
  } else {
    valomradesnamn
  }

  if (any(!nzchar(koder)) || any(!nzchar(namn)) || anyDuplicated(koder)) {
    stop("Mandatfilens personvalsomr\u00e5den har ogiltiga eller dubbla identiteter.", call. = FALSE)
  }

  tibble::tibble(
    geografiniva = .personval_geografiniva_2026(valtyp, indelad),
    personvalsomradeskod = koder,
    personvalsomradesnamn = namn,
    valomradeskod = valomradeskod,
    valomradesnamn = valomradesnamn,
    valkretskod = if (indelad) koder else rep(NA_character_, length(noder)),
    valkretsnamn = if (indelad) namn else rep(NA_character_, length(noder)),
    personval_available = vapply(
      noder,
      function(x) .personval_nodstatus_2026(raw, x),
      logical(1)
    ),
    .personval_nod = noder
  )
}

.personval_partiroster_2026 <- function(omraden) {
  purrr::map2_dfr(
    omraden$personvalsomradeskod,
    omraden$.personval_nod,
    function(omradeskod, nod) {
      partier <- nod$rostfordelning$rosterPaverkaMandat$partiRoster
      if (is.null(partier)) {
        return(tibble::tibble(
          personvalsomradeskod = character(),
          partikod = character(),
          antal_partiroster = integer()
        ))
      }
      if (!.personrost_array(partier) || !all(vapply(partier, function(p) {
        .personrost_objekt(p) && .personrost_id(p$partikod) &&
          .personrost_heltal(p$antalRoster)
      }, logical(1)))) {
        stop("Mandatfilens partir\u00f6stf\u00f6rdelning har ogiltig struktur.", call. = FALSE)
      }
      partikoder <- vapply(partier, function(p) p$partikod, "")
      if (anyDuplicated(partikoder)) {
        stop("Mandatfilen inneh\u00e5ller dubbla partirader i ett personvalsomr\u00e5de.", call. = FALSE)
      }
      tibble::tibble(
        personvalsomradeskod = omradeskod,
        partikod = partikoder,
        antal_partiroster = vapply(partier, function(p) as_int_na(p$antalRoster), integer(1))
      )
    }
  )
}

.personval_officiella_2026 <- function(omraden) {
  purrr::map2_dfr(
    seq_len(nrow(omraden)),
    omraden$.personval_nod,
    function(i, nod) {
      if (!isTRUE(omraden$personval_available[[i]])) {
        return(tibble::tibble(
          personvalsomradeskod = character(),
          kandidatnummer = character(),
          partikod = character(),
          antal_personroster_officiellt = integer(),
          andel_personroster_officiellt_procent = double()
        ))
      }
      lista <- nod$kvalificeradeForPersonvalLista
      if (!length(lista)) {
        return(tibble::tibble(
          personvalsomradeskod = character(),
          kandidatnummer = character(),
          partikod = character(),
          antal_personroster_officiellt = integer(),
          andel_personroster_officiellt_procent = double()
        ))
      }
      tibble::tibble(
        personvalsomradeskod = omraden$personvalsomradeskod[[i]],
        kandidatnummer = vapply(lista, function(x) as_chr_na(x$kandidatnummer), ""),
        partikod = vapply(lista, function(x) as_chr_na(x$partikod), ""),
        antal_personroster_officiellt = vapply(
          lista, function(x) as_int_na(x$antalPersonroster), integer(1)
        ),
        andel_personroster_officiellt_procent = vapply(
          lista, function(x) as_dbl_na(x$andelPersonroster), double(1)
        )
      )
    }
  )
}

.personrostomradesunderlag_2026 <- function(raw, valomradeskod, omraden) {
  status <- tibble::tibble(
    valtyp = character(), valomradeskod = character(),
    personvalsomradeskod = character(), partikod = character(),
    personroster_available = logical(), antal_partiroster_distrikt = integer()
  )
  roster <- tibble::tibble(
    kandidatnummer = character(), valtyp = character(),
    valomradeskod = character(), personvalsomradeskod = character(),
    partikod = character(), antal_personroster_summerat = integer()
  )
  tom <- list(status = status, roster = roster)

  if (!.personrost_objekt(raw) || !.personrost_array(raw$valdistrikt) ||
      !length(raw$valdistrikt) || !.personrost_id(valomradeskod)) return(tom)
  vd <- raw$valdistrikt
  if (!all(vapply(vd, .personrost_objekt, logical(1)))) return(tom)

  indelad <- all(!is.na(omraden$valkretskod))
  distrikt_omrade <- if (indelad) {
    vapply(vd, function(d) as_chr_na(d$kretskod), "")
  } else {
    rep(valomradeskod, length(vd))
  }
  if (any(!distrikt_omrade %in% omraden$personvalsomradeskod)) return(tom)

  identitet_ok <- all(vapply(vd, function(d) {
    .personrost_id(d$valdistriktskod) && .personrost_id(d$kommunkod) &&
      identical(d$valomradeskod, valomradeskod)
  }, logical(1)))
  identiteter <- vapply(vd, function(d) {
    paste(as_chr_na(d$valomradeskod), as_chr_na(d$kommunkod),
          as_chr_na(d$valdistriktskod), as_chr_na(d$valdistriktstyp), sep = "/")
  }, "")
  antal <- raw$antalValdistriktSomSkaRaknas
  raknade <- raw$antalValdistriktRaknade
  tackning <- identitet_ok && !anyDuplicated(identiteter) &&
    .personrost_heltal(antal) && antal > 0L && length(vd) == antal &&
    .personrost_heltal(raknade) && raknade == antal &&
    identical(.normalisera_rakningstillfalle_2026(raw$rakningstillfalle), "slutlig")

  for (omradeskod in omraden$personvalsomradeskod) {
    index <- which(distrikt_omrade == omradeskod)
    vd_omrade <- vd[index]
    partier <- lapply(vd_omrade, function(d) {
      if (!.personrost_objekt(d$rostfordelning) ||
          !.personrost_objekt(d$rostfordelning$rosterPaverkaMandat)) return(NULL)
      d$rostfordelning$rosterPaverkaMandat$partiRoster
    })
    giltiga <- vapply(partier, function(ps) {
      .personrost_array(ps) && all(vapply(ps, function(p) {
        .personrost_objekt(p) && .personrost_id(p$partikod)
      }, logical(1)))
    }, logical(1))
    koder <- lapply(seq_along(partier), function(i) {
      if (!giltiga[[i]]) character() else vapply(partier[[i]], function(p) p$partikod, "")
    })
    alla <- sort(unique(unlist(koder)))

    for (kod in alla) {
      noder <- lapply(seq_along(vd_omrade), function(i) {
        j <- which(koder[[i]] == kod)
        if (length(j) == 1L) partier[[i]][[j]] else NULL
      })
      states <- vapply(noder, .personrost_partistatus, logical(1))
      available <- if (tackning) .personrost_status(states) else NA
      distriktsroster <- vapply(noder, function(p) {
        if (.personrost_objekt(p) && .personrost_heltal(p$antalRoster)) {
          as_int_na(p$antalRoster)
        } else {
          NA_integer_
        }
      }, integer(1))
      antal_partiroster_distrikt <- if (length(distriktsroster) == length(vd_omrade) &&
          !anyNA(distriktsroster)) as.integer(sum(distriktsroster)) else NA_integer_

      status <- dplyr::bind_rows(status, tibble::tibble(
        valtyp = as_chr_na(raw$valtyp), valomradeskod = valomradeskod,
        personvalsomradeskod = omradeskod, partikod = kod,
        personroster_available = available,
        antal_partiroster_distrikt = antal_partiroster_distrikt
      ))

      if (isTRUE(available)) {
        # Collect typed candidate vectors before constructing one group table.
        votes <- lapply(noder, function(p) {
          .personrost_rader(p$summeradePersonroster, "kandidatnummer")
        })
        values <- unlist(votes, use.names = FALSE)
        ids <- unlist(lapply(votes, names), use.names = FALSE)
        rader <- tibble::tibble(
          kandidatnummer = if (length(ids)) ids else character(),
          antal_personroster_summerat = if (length(values)) values else integer()
        )
        if (nrow(rader)) {
          rader <- dplyr::summarise(
            rader,
            antal_personroster_summerat = as.integer(sum(antal_personroster_summerat)),
            .by = kandidatnummer
          )
          rader$valtyp <- as_chr_na(raw$valtyp)
          rader$valomradeskod <- valomradeskod
          rader$personvalsomradeskod <- omradeskod
          rader$partikod <- kod
          roster <- dplyr::bind_rows(roster, rader)
        }
      }
    }
  }

  list(status = status, roster = roster)
}

.personrostomraden_2026 <- function(kandidaturer, kandidater, rost_raw, mandat_raw) {
  valtyp <- as_chr_na(mandat_raw$valtyp)
  if (!identical(as_chr_na(rost_raw$valtyp), valtyp)) {
    stop("R\u00f6st- och mandatfilen avser olika valtyper.", call. = FALSE)
  }

  omraden <- .personvalsomraden_mandat_2026(mandat_raw)
  valomradeskod <- unique(omraden$valomradeskod)
  indelad <- all(!is.na(omraden$valkretskod))
  kandidaturer_omrade <- kandidaturer |>
    dplyr::filter(
      giltig %in% TRUE,
      valtyp == .env$valtyp,
      valomradeskod == .env$valomradeskod
    )

  if (indelad) {
    saknade <- setdiff(
      unique(kandidaturer_omrade$valkretskod),
      omraden$personvalsomradeskod
    )
    if (length(saknade)) {
      stop(
        "Kandidaturdata inneh\u00e5ller valkretskoder som saknas i mandatfilen: ",
        paste(saknade, collapse = ", "), ".",
        call. = FALSE
      )
    }
    universum <- kandidaturer_omrade |>
      dplyr::distinct(kandidatnummer, valtyp, partikod, valomradeskod, valkretskod) |>
      dplyr::rename(personvalsomradeskod = valkretskod) |>
      dplyr::left_join(
        dplyr::select(omraden, -personval_available, -.personval_nod),
        by = dplyr::join_by(valomradeskod, personvalsomradeskod),
        relationship = "many-to-one"
      )
  } else {
    universum <- kandidaturer_omrade |>
      dplyr::distinct(kandidatnummer, valtyp, partikod, valomradeskod) |>
      dplyr::mutate(personvalsomradeskod = omraden$personvalsomradeskod[[1]]) |>
      dplyr::left_join(
        dplyr::select(omraden, -personval_available, -.personval_nod),
        by = dplyr::join_by(valomradeskod, personvalsomradeskod),
        relationship = "many-to-one"
      )
  }

  identitet <- kandidater |>
    dplyr::select(
      kandidatnummer, valtyp, partikod, namn,
      partiforkortning, partibeteckning
    )
  universum <- universum |>
    dplyr::left_join(
      identitet,
      by = dplyr::join_by(kandidatnummer, valtyp, partikod),
      relationship = "many-to-one"
    )

  underlag <- .personrostomradesunderlag_2026(
    rost_raw, valomradeskod, omraden
  )
  mandatlistor <- NULL
  get_mandatlistor <- function() {
    if (is.null(mandatlistor)) {
      mandatlistor <<- .personroster_mandatlistor_2026(omraden)
    }
    mandatlistor
  }
  avstamda <- .personrostomraden_avstamda_2026(
    rost_raw, omraden, mandatlistor = get_mandatlistor())
  summerade_omrade <- .personroster_summerade_omrade_2026(omraden)
  listsummerade <- tibble::tibble(
    personvalsomradeskod = character(), partikod = character(),
    kandidatnummer = character(), antal_personroster_listor = integer())
  if (any(avstamda)) {
    listsummerade <- get_mandatlistor()$roster |>
      dplyr::summarise(
        antal_personroster_listor = as.integer(sum(antal_personroster_lista)),
        .by = c(personvalsomradeskod, partikod, kandidatnummer)
      )
  }
  partiroster <- .personval_partiroster_2026(omraden)
  officiella <- .personval_officiella_2026(omraden)
  okanda_officiella <- officiella |>
    dplyr::anti_join(
      universum,
      by = dplyr::join_by(
        kandidatnummer, partikod, personvalsomradeskod
      )
    )
  if (nrow(okanda_officiella)) {
    stop(
      "En kandidat i den officiella personvalslistan saknar en giltig kandidatur i omr\u00e5det.",
      call. = FALSE
    )
  }

  status_med_partiroster <- underlag$status |>
    dplyr::left_join(
      partiroster,
      by = dplyr::join_by(personvalsomradeskod, partikod),
      relationship = "one-to-one"
    )
  fel_partiroster <- status_med_partiroster |>
    dplyr::filter(
      personroster_available %in% TRUE,
      !is.na(antal_partiroster),
      !is.na(antal_partiroster_distrikt),
      antal_partiroster != antal_partiroster_distrikt
    )
  if (nrow(fel_partiroster)) {
    stop(
      "Den officiella partir\u00f6sttotalen st\u00e4mmer inte med valdistrikten i ett personvalsomr\u00e5de.",
      call. = FALSE
    )
  }

  out <- universum |>
    dplyr::left_join(
      dplyr::select(omraden, personvalsomradeskod, personval_available),
      by = dplyr::join_by(personvalsomradeskod),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      underlag$status,
      by = dplyr::join_by(valtyp, valomradeskod, personvalsomradeskod, partikod),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      underlag$roster,
      by = dplyr::join_by(
        kandidatnummer, valtyp, valomradeskod,
        personvalsomradeskod, partikod
      ),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      summerade_omrade,
      by = dplyr::join_by(personvalsomradeskod, partikod, kandidatnummer),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      listsummerade,
      by = dplyr::join_by(personvalsomradeskod, partikod, kandidatnummer),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      partiroster,
      by = dplyr::join_by(personvalsomradeskod, partikod),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      dplyr::mutate(officiella, .officiell_rad = TRUE),
      by = dplyr::join_by(
        kandidatnummer, partikod, personvalsomradeskod
      ),
      relationship = "one-to-one"
    )

  motsagelse <- out |>
    dplyr::filter(
      .officiell_rad %in% TRUE,
      personroster_available %in% TRUE,
      antal_personroster_officiellt !=
        dplyr::coalesce(antal_personroster_summerat, 0L)
    )
  if (nrow(motsagelse)) {
    stop(
      "Officiellt personr\u00f6stetal st\u00e4mmer inte med komplett summerat distriktsunderlag.",
      call. = FALSE
    )
  }
  motsagelse_omrade <- out |>
    dplyr::filter(
      avstamda[match(personvalsomradeskod, names(avstamda))] %in% TRUE,
      .officiell_rad %in% TRUE, !is.na(antal_personroster_omrade),
      antal_personroster_officiellt != antal_personroster_omrade
    )
  if (nrow(motsagelse_omrade)) {
    stop("Officiellt personr\u00f6stetal st\u00e4mmer inte med omr\u00e5dets summerade personr\u00f6ster.",
         call. = FALSE)
  }

  andelsfel <- out |>
    dplyr::filter(
      .officiell_rad %in% TRUE,
      !is.na(antal_partiroster),
      antal_partiroster > 0L,
      abs(
        100 * antal_personroster_officiellt / antal_partiroster -
          andel_personroster_officiellt_procent
      ) > 0.005 + 1e-10
    )
  if (nrow(andelsfel)) {
    stop(
      "Officiell personr\u00f6standel st\u00e4mmer inte med person- och partir\u00f6stetalen.",
      call. = FALSE
    )
  }

  out <- out |>
    dplyr::mutate(
      antal_personroster = dplyr::case_when(
        .officiell_rad %in% TRUE ~ antal_personroster_officiellt,
        avstamda[match(personvalsomradeskod, names(avstamda))] %in% TRUE &
          !is.na(antal_personroster_omrade) ~ antal_personroster_omrade,
        avstamda[match(personvalsomradeskod, names(avstamda))] %in% TRUE &
          !is.na(antal_personroster_listor) ~ antal_personroster_listor,
        avstamda[match(personvalsomradeskod, names(avstamda))] %in% TRUE ~ 0L,
        personroster_available %in% TRUE ~
          dplyr::coalesce(antal_personroster_summerat, 0L),
        .default = NA_integer_
      ),
      kvalificerad_personval = dplyr::case_when(
        .officiell_rad %in% TRUE ~ TRUE,
        personval_available %in% TRUE ~ FALSE,
        .default = NA
      ),
      andel_personroster = dplyr::if_else(
        !is.na(antal_personroster) & !is.na(antal_partiroster) &
          antal_partiroster > 0L,
        antal_personroster / antal_partiroster,
        NA_real_
      ),
      valtillfalle = as_chr_na(mandat_raw$valtillfalle),
      rakningstillfalle = .normalisera_rakningstillfalle_2026(
        mandat_raw$rakningstillfalle
      ),
      valdatum = as_chr_na(mandat_raw$valdatum),
      test = as_lgl_na(mandat_raw$test)
    ) |>
    dplyr::select(
      valtillfalle, valtyp, kandidatnummer, namn, partikod,
      partiforkortning, partibeteckning, geografiniva,
      personvalsomradeskod, personvalsomradesnamn,
      valomradeskod, valomradesnamn, valkretskod, valkretsnamn,
      antal_personroster, antal_partiroster, andel_personroster,
      kvalificerad_personval, rakningstillfalle, valdatum, test
    ) |>
    dplyr::arrange(
      valtyp, valomradeskod, personvalsomradeskod, partikod, kandidatnummer
    )
  out <- .kort_kommunnamn_2026(out)
  .kort_kommunnamn_2026(
    out,
    kodkolumn = "personvalsomradeskod",
    namnkolumn = "personvalsomradesnamn",
    rader = out$geografiniva == "kommun"
  )
}

.personrosttotaler_fran_omraden_2026 <- function(personroster) {
  if (!nrow(personroster)) {
    return(tibble::tibble(
      kandidatnummer = character(), valtyp = character(), partikod = character(),
      antal_personroster_totalt = integer()
    ))
  }
  personroster |>
    dplyr::summarise(
      antal_personroster_totalt = if (all(!is.na(antal_personroster))) {
        as.integer(sum(antal_personroster))
      } else {
        NA_integer_
      },
      .by = c(kandidatnummer, valtyp, partikod)
    )
}
