parse_valda_ersattare_2026 <- function(raw) {

  valtyp <- as_chr_na(raw$valtyp)
  valomrade <- raw$valomrade

  geografiniva_valomrade <- dplyr::recode_values(
    valtyp,
    "RD" ~ "riket",
    "RF" ~ "region",
    "KF" ~ "kommun",
    default = NA_character_
  )

  geografiniva_valkrets <- dplyr::recode_values(
    valtyp,
    "RD" ~ "riksdagsvalkrets",
    "RF" ~ "regionvalkrets",
    "KF" ~ "kommunvalkrets",
    default = NA_character_
  )

  empty_valda <- function() {
    tibble::tibble(
      valtillfalle = character(),
      valklass = character(),
      rakningstillfalle = character(),
      valtyp = character(),
      valdatum = character(),
      valdatum_fg = character(),
      test = logical(),
      geografiniva = character(),
      valomradeskod = character(),
      valomradesnamn = character(),
      valkretskod = character(),
      valkretsnamn = character(),
      partibeteckning = character(),
      partiforkortning = character(),
      partikod = character(),
      partifarg = character(),
      kandidatnummer = character(),
      namn = character(),
      invalsordning = integer(),
      valgrund_id = character(),
      valgrund_text = character(),
      ersattargrupp = character()
    )
  }

  empty_ersattare <- function() {
    tibble::tibble(
      valtillfalle = character(),
      valklass = character(),
      rakningstillfalle = character(),
      valtyp = character(),
      valdatum = character(),
      valdatum_fg = character(),
      test = logical(),
      geografiniva = character(),
      valomradeskod = character(),
      valomradesnamn = character(),
      valkretskod = character(),
      valkretsnamn = character(),
      partibeteckning = character(),
      partiforkortning = character(),
      partikod = character(),
      partifarg = character(),
      ledamot_kandidatnummer = character(),
      ledamot_namn = character(),
      ersattargrupp = character(),
      ersattare_kandidatnummer = character(),
      ersattare_namn = character(),
      ersattarordning = integer(),
      valgrund_id = character(),
      valgrund_text = character()
    )
  }

  parse_niva <- function(
      valda,
      geografiniva,
      valkretskod = NA_character_,
      valkretsnamn = NA_character_
  ) {

    if (is.null(valda) ||
        is.null(valda$partiLedamoterLista) ||
        length(valda$partiLedamoterLista) == 0) {
      return(list(
        valda = empty_valda(),
        ersattare = empty_ersattare()
      ))
    }

    parti_list <- valda$partiLedamoterLista


    # Metadata is shared by the entire elected/substitute group.
    common <- function(parti) tibble::tibble(
      valtillfalle = as_chr_na(raw$valtillfalle),
      valklass = as_chr_na(raw$valklass),
      rakningstillfalle = .normalisera_rakningstillfalle_2026(raw$rakningstillfalle),
      valtyp = valtyp, valdatum = as_chr_na(raw$valdatum),
      valdatum_fg = as_chr_na(raw$tidigareValdatum), test = as_lgl_na(raw$test),
      geografiniva = geografiniva,
      valomradeskod = as_chr_na(valomrade$kod),
      valomradesnamn = as_chr_na(valomrade$namn),
      valkretskod = valkretskod, valkretsnamn = valkretsnamn,
      partibeteckning = as_chr_na(parti$partibeteckning),
      partiforkortning = as_chr_na(parti$partiforkortning),
      partikod = as_chr_na(parti$partikod), partifarg = as_chr_na(parti$partiFarg)
    )
    chars <- function(rows, value) vapply(rows,
      function(row) as_chr_na(value(row)), character(1), USE.NAMES = FALSE)
    ints <- function(rows, value) vapply(rows,
      function(row) as_int_na(value(row)), integer(1), USE.NAMES = FALSE)
    valda_rows <- purrr::map_dfr(parti_list, function(parti) {
      ledamoter <- parti$ledamoter
      if (!length(ledamoter)) return(empty_valda())
      columns <- tibble::tibble(
        kandidatnummer = chars(ledamoter, \(x) x$kandidatnummer),
        namn = chars(ledamoter, \(x) x$namn),
        invalsordning = ints(ledamoter, \(x) x$invalsordning),
        valgrund_id = chars(ledamoter, \(x) x$valgrundId),
        valgrund_text = chars(ledamoter, \(x) x$valgrundText),
        ersattargrupp = chars(ledamoter, \(x) x$ersattargrupp)
      )
      dplyr::bind_cols(common(parti)[rep(1L, nrow(columns)), ], columns)
    })
    ersattare_rows <- purrr::map_dfr(parti_list, function(parti) {
      ledamoter <- parti$ledamoter
      if (!length(ledamoter)) return(empty_ersattare())
      lists <- lapply(ledamoter, function(l) l$ersattareList)
      ersattare <- unlist(lists, recursive = FALSE, use.names = FALSE)
      if (!length(ersattare)) return(empty_ersattare())
      parents <- ledamoter[rep(seq_along(ledamoter), lengths(lists))]
      columns <- tibble::tibble(
        ledamot_kandidatnummer = chars(parents, \(x) x$kandidatnummer),
        ledamot_namn = chars(parents, \(x) x$namn),
        ersattargrupp = chars(parents, \(x) x$ersattargrupp),
        ersattare_kandidatnummer = chars(ersattare, \(x) x$kandidatnummer),
        ersattare_namn = chars(ersattare, \(x) x$namn),
        ersattarordning = ints(ersattare, \(x) x$ersattarordning),
        valgrund_id = chars(ersattare, \(x) x$valgrundId),
        valgrund_text = chars(ersattare, \(x) x$valgrundText)
      )
      dplyr::bind_cols(common(parti)[rep(1L, nrow(columns)), ], columns)
    })
    list(
      valda = valda_rows,
      ersattare = ersattare_rows
    )
  }

  valkretsar <- valomrade$valkretsLista
  kallval <- .valda_kallval_2026(raw)

  if (identical(kallval$niva, "valkrets")) {

    parsed <- purrr::map(
      valkretsar,
      \(vk) parse_niva(
        valda = vk$valda,
        geografiniva = geografiniva_valkrets,
        valkretskod = as_chr_na(vk$kod),
        valkretsnamn = as_chr_na(vk$namnValkrets)
      )
    )

    valda_valkrets <- parsed |>
      purrr::map("valda") |>
      purrr::list_rbind()

    ersattare_valkrets <- parsed |>
      purrr::map("ersattare") |>
      purrr::list_rbind()

    return(list(valda = valda_valkrets, ersattare = ersattare_valkrets))
  }

  # Annars använder vi valområdesnivån. Om även den saknar valda
  # returneras schema-stabila tomma tabeller.
  parse_niva(
    valda = valomrade$valda,
    geografiniva = geografiniva_valomrade
  )
}
