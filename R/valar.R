# En enda intern förteckning över stödda valår per funktion och valtyp.
# Andra publika funktioner använder ännu bara 2026, men kan senare återanvända
# samma årslösare när deras historiska källor har implementerats.
.stodd_valar <- function(funktion, val) {
  register <- list(
    valresultat = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                      KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    mandat = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                  KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    kandidaturer = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                       KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    kandidater = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                      KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    personroster = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                       KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    valda = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                 KF = c(2010L, 2014L, 2018L, 2022L, 2026L)),
    ersattare = list(RD = c(2010L, 2014L, 2018L, 2022L, 2026L), RF = c(2010L, 2014L, 2018L, 2022L, 2026L),
                    KF = c(2010L, 2014L, 2018L, 2022L, 2026L))
  )
  out <- register[[funktion]][[val]]
  if (is.null(out)) stop("Ok\u00e4nd funktion eller valtyp i \u00e5rsregistret.", call. = FALSE)
  out
}

.valar_grans <- function(x, namn) {
  if (!is.numeric(x) || is.logical(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x != trunc(x) || x < 1 || x > .Machine$integer.max) {
    stop("`", namn, "` ska vara ett heltals\u00e5r.", call. = FALSE)
  }
  as.integer(x)
}

.resolve_valar <- function(ar = 2026, fran = NULL, till = NULL,
                          funktion = "valresultat", val = "RD",
                          ar_angivet = TRUE) {
  stodd <- sort(unique(.stodd_valar(funktion, val)))
  intervall <- !is.null(fran) || !is.null(till)
  if (intervall && ar_angivet) {
    stop("`ar` och `fran`/`till` \u00e4r alternativa \u00e5rsval.", call. = FALSE)
  }
  if (intervall) {
    undre <- if (is.null(fran)) -Inf else .valar_grans(fran, "fran")
    ovre <- if (is.null(till)) Inf else .valar_grans(till, "till")
    if (undre > ovre) stop("`fran` f\u00e5r inte vara st\u00f6rre \u00e4n `till`.", call. = FALSE)
    out <- stodd[stodd >= undre & stodd <= ovre]
    if (!length(out)) {
      stop("Inga st\u00f6dda val\u00e5r f\u00f6r ", funktion, "/", val,
           " i intervallet. St\u00f6dda \u00e5r: ", paste(stodd, collapse = ", "), ".",
           call. = FALSE)
    }
    return(out)
  }
  if (is.character(ar) && length(ar) == 1L && !is.na(ar) && identical(ar, "alla")) {
    return(stodd)
  }
  if (!is.numeric(ar) || is.logical(ar) || !length(ar) || anyNA(ar) ||
      any(!is.finite(ar)) || any(ar != trunc(ar)) ||
      any(ar < 1 | ar > .Machine$integer.max)) {
    stop("`ar` ska inneh\u00e5lla ett eller flera heltals\u00e5r eller vara \"alla\". ",
         "St\u00f6dda \u00e5r f\u00f6r ", val, ": ", paste(stodd, collapse = ", "), ".",
         call. = FALSE)
  }
  out <- unique(as.integer(ar))
  saknas <- out[!out %in% stodd]
  if (length(saknas)) {
    stop("Val\u00e5r som inte st\u00f6ds f\u00f6r ", funktion, "/", val, ": ",
         paste(saknas, collapse = ", "), ". St\u00f6dda \u00e5r: ",
         paste(stodd, collapse = ", "), ".", call. = FALSE)
  }
  out
}
