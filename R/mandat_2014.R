.mandat_2014 <- function(sources, par, progress) {
  rows <- lapply(seq_len(nrow(par)), function(i) {
    v <- par$valtyp[[i]]
    niva <- par$geografiniva[[i]]
    register <- .xml2014_register_all(sources, v)
    files <- .xml2014_members(sources, v, niva, mandat = TRUE)
    purrr::map(files, function(f) {
      doc <- .xml2014_file(f, v)
      root <- xml2::xml_find_first(doc, "./NATION|./KOMMUN")
      nodes <- .xml2018_mandat_noder(doc, v, niva)
      purrr::map(nodes, .xml2018_mandatrader, doc = doc, root = root,
        val = v, niva = niva, register = register) |>
        purrr::list_rbind()
    }, .progress = progress) |> purrr::list_rbind()
  }) |> purrr::list_rbind()
  rows <- .metadata_2014(rows, .historical_year(sources))
  .mandat_public_2026(.kort_kommunnamn_2026(rows), .historical_year(sources))
}
