# Preserve the existing, fully validated raw/canonical readers as one internal
# implementation. The English API owns presentation; Swedish names and argument
# values are translated by the thin wrappers below.
.raw_public_api <- list(
  valresultat = valresultat, mandat = mandat, kandidaturer = kandidaturer,
  kandidater = kandidater, valda = valda, ersattare = ersattare,
  personroster = personroster
)

.swedish_level_en <- function(niva) {
  if (is.null(niva)) return(NULL)
  choices <- .english_argument_values$level
  selected <- match(niva, unname(choices))
  if (anyNA(selected)) {
    stop("Ok\u00e4nd geografisk niva: ", paste(niva, collapse = ", "), ".",
         call. = FALSE)
  }
  names(choices)[selected]
}

.swedish_count_en <- function(rakning) {
  if (identical(rakning, "slutlig")) return("final")
  if (identical(rakning, "preliminar")) return("preliminary")
  stop("Ok\u00e4nd rakning; ange slutlig eller preliminar.", call. = FALSE)
}

.swedish_public_call <- function(fun, args, ar, ar_missing, names, detaljniva) {
  if (!is.null(args$election)) args$election <- .valtyper(args$election)
  if (!ar_missing) args$year <- if (identical(ar, "alla")) "all" else ar
  args$names <- names
  args$detail <- detaljniva
  do.call(fun, args)
}

valresultat <- function(
    ar = 2026, val = "RD", rakning = c("slutlig", "preliminar"),
    niva = NULL, source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  if (!is.null(niva)) .check_text(niva, "niva")
  .swedish_public_call(results, list(
    election = val, count = .swedish_count_en(if (missing(rakning)) "slutlig" else rakning),
    level = .swedish_level_en(niva), source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

mandat <- function(
    ar = 2026, val = NULL, rakning = c("slutlig", "preliminar"), niva = NULL,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .swedish_public_call(seats, list(
    election = val, count = .swedish_count_en(if (missing(rakning)) "slutlig" else rakning),
    level = .swedish_level_en(niva), source = source, data_dir = data_dir,
    update = update, archive = archive, progress = progress, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

kandidaturer <- function(
    ar = 2026, val = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE,
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .swedish_public_call(candidacies, list(
    election = val, source = source, data_dir = data_dir, update = update,
    archive = archive, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

kandidater <- function(
    ar = 2026, val = NULL, resultat = TRUE,
    source = c("auto", "local", "remote", "canonical"), data_dir = NULL,
    update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .swedish_public_call(candidates, list(
    election = val, include_results = resultat, source = source,
    data_dir = data_dir, update = update, archive = archive,
    progress = progress, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

valda <- function(
    ar = 2026, val = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .swedish_public_call(elected, list(
    election = val, source = source, data_dir = data_dir, update = update,
    archive = archive, progress = progress, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

ersattare <- function(
    ar = 2026, val = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE, progress = interactive(),
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .swedish_public_call(substitutes, list(
    election = val, source = source, data_dir = data_dir, update = update,
    archive = archive, progress = progress, from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}

personroster <- function(
    ar = 2026, val = NULL, source = c("auto", "local", "remote", "canonical"),
    data_dir = NULL, update = FALSE, archive = FALSE, progress = interactive(),
    niva = "personvalsomrade", per_lista = FALSE, komplettera_nollor = FALSE,
    fran = NULL, till = NULL, names = "sv", detaljniva = "standard"
) {
  .check_text(niva, "niva")
  .check_flag(per_lista, "per_lista")
  .check_flag(komplettera_nollor, "komplettera_nollor")
  .swedish_public_call(preference_votes, list(
    election = val, source = source, data_dir = data_dir, update = update,
    archive = archive, progress = progress, level = .swedish_level_en(niva),
    by_list = per_lista, include_zeros = komplettera_nollor,
    from = fran, to = till
  ), ar, missing(ar), names, detaljniva)
}
