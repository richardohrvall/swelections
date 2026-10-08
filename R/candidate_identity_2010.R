# Explicit, approved identity harmonisation for the 2010 election occasion.
# Apply at the future 2010 XML reader boundary, before candidate joins or sums.
# This is not a global replacement and does not enable public 2010 support.
.xml2010_candidate_identity <- function(doc) {
  empty <- tibble::tibble(rule = character(), election_date = character(),
    election_code = character(), source_file = character(), source_node = character(),
    source_candidate_id = character(), candidate_id = character())
  root <- xml2::xml_root(doc)
  if (!identical(.xml2018_attr(root, "VALDAG"), "20100919") ||
      !identical(.xml2018_attr(root, "VALTYP"), "Landstingsval") ||
      !identical(.xml2018_attr(root, "RAPPORTERING"),
                 "SLUTLIG R\u00d6STR\u00c4KNING RESULTAT"))
    return(list(doc = doc, provenance = empty))

  nodes <- xml2::xml_find_all(doc, ".//*[@KANDNR='451964']")
  if (!length(nodes)) return(list(doc = doc, provenance = empty))
  # Area XML and municipal/district XML express the same RF constituency
  # through different branches. Require the approved party/geography context.
  contexts <- vapply(nodes, function(node) {
    party <- xml2::xml_find_chr(node, "string(ancestor::GILTIGA[1]/@PARTI)")
    constituency <- xml2::xml_find_chr(node,
      "string(ancestor::KRETS_LANDSTING[1]/@KOD)")
    if (!nzchar(constituency)) constituency <- xml2::xml_find_chr(node,
      "string(ancestor::KRETS_KOMMUN[1]/@KRETS_LANDSTING)")
    list <- xml2::xml_find_chr(node, "string(ancestor::VALSEDEL[1]/@LISTNUMMER)")
    position <- .xml2018_attr(node, "KANDIDAT")
    identical(party, "FP") && identical(constituency, "0303") &&
      (!nzchar(list) || (identical(list, "0003-03159") &&
        identical(position, "6")))
  }, logical(1))
  if (!all(contexts)) stop("Unverified context for 2010 Bjorn Andersson identity rule.",
                           call. = FALSE)
  if (length(xml2::xml_find_all(doc, ".//*[@KANDNR='442089']")))
    stop("2010 candidate identity collision: 442089 already occurs in RF XML.",
         call. = FALSE)

  paths <- xml2::xml_path(nodes)
  provenance <- tibble::tibble(rule = "2010-bjorn-andersson",
    election_date = "2010-09-19", election_code = "RF",
    source_file = .xml2018_attr(root, "FILNAMN"), source_node = paths,
    source_candidate_id = "451964", candidate_id = "442089")
  # xml2 nodes have reference semantics: copy before changing in-memory IDs.
  out <- xml2::read_xml(as.character(doc), options = c("NONET", "NOBLANKS"))
  for (path in paths) xml2::xml_set_attr(xml2::xml_find_first(out, path),
                                      "KANDNR", "442089")
  list(doc = out, provenance = provenance)
}
