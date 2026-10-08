identity_xml_2010 <- function(val = "RF", id = "451964", date = "20100919",
                              party = "FP", constituency = "0303") {
  type <- c(RD = "Riksdagsval", RF = "Landstingsval", KF = "Kommunfullm\u00e4ktigval")[[val]]
  xml2::read_xml(paste0('<VAL VALDAG="', date, '" VALTYP="', type,
    '" RAPPORTERING="SLUTLIG R&#214;STR&#196;KNING RESULTAT" FILNAMN="fixture.xml">',
    '<KRETS_LANDSTING KOD="', constituency, '"><GILTIGA PARTI="', party, '">',
    '<PERSONVAL KANDNR="', id, '" PERSONKRYSS="8"/>',
    '<VALSEDEL LISTNUMMER="0003-03159"><PERSONVAL KANDNR="', id,
    '" KANDIDAT="6" PERSONKRYSS="8"/></VALSEDEL>',
    '<VALD KANDNR="', id, '" ORDNING="1"/>',
    '<ERS\u00c4TTARE KANDNR="', id, '" ORDNING="2"/>',
    '</GILTIGA></KRETS_LANDSTING></VAL>'))
}

test_that("Bjorn has one canonical ID across the 2010 election types", {
  documents <- list(identity_xml_2010("RD", "442089"), identity_xml_2010(),
                    identity_xml_2010("KF", "442089"))
  out <- lapply(documents, .xml2010_candidate_identity)
  ids <- lapply(out, function(x) unique(xml2::xml_attr(
    xml2::xml_find_all(x$doc, ".//*[@KANDNR]"), "KANDNR")))
  expect_identical(ids, rep(list("442089"), 3))
  expect_identical(unique(out[[2]]$provenance$source_candidate_id), "451964")
  expect_identical(unique(out[[2]]$provenance$candidate_id), "442089")
  expect_equal(nrow(out[[2]]$provenance), 4L)
  expect_equal(nrow(out[[1]]$provenance), 0L)
  expect_identical(unique(xml2::xml_attr(xml2::xml_find_all(documents[[2]],
    ".//*[@KANDNR]"), "KANDNR")), "451964")
  # Apart from ID harmonisation the complete document is identical, including
  # vote values, list positions and elected/substitute relationship attributes.
  reverted <- out[[2]]$doc
  xml2::xml_set_attr(xml2::xml_find_all(reverted, ".//*[@KANDNR='442089']"),
                    "KANDNR", "451964")
  expect_identical(as.character(reverted), as.character(documents[[2]]))
})

test_that("the identity rule is occasion and source-context specific", {
  for (doc in list(identity_xml_2010(date = "20140914"),
                   identity_xml_2010("RD"), identity_xml_2010("KF"),
                   identity_xml_2010(id = "474411"))) {
    out <- .xml2010_candidate_identity(doc)
    expect_identical(as.character(out$doc), as.character(doc))
    expect_equal(nrow(out$provenance), 0L)
  }
  expect_error(.xml2010_candidate_identity(identity_xml_2010(party = "S")),
               "Unverified context")
  expect_error(.xml2010_candidate_identity(identity_xml_2010(constituency = "0301")),
               "Unverified context")
  doc <- identity_xml_2010()
  xml2::xml_set_attr(xml2::xml_find_first(doc, ".//VALD"), "KANDNR", "442089")
  expect_error(.xml2010_candidate_identity(doc), "collision")
})

test_that("municipal XML uses the same rule and harmonisation is idempotent", {
  doc <- identity_xml_2010()
  node <- xml2::xml_find_first(doc, ".//KRETS_LANDSTING")
  xml2::xml_set_name(node, "KRETS_KOMMUN")
  xml2::xml_set_attr(node, "KRETS_LANDSTING", "0303")
  out <- .xml2010_candidate_identity(doc)
  expect_identical(unique(out$provenance$candidate_id), "442089")
  again <- .xml2010_candidate_identity(out$doc)
  expect_identical(as.character(again$doc), as.character(out$doc))
  expect_equal(nrow(again$provenance), 0L)
})


test_that("the seven weaker name-based pairs are not harmonised", {
  ids <- c("123838", "228052", "227247", "467317", "259476", "323270",
           "367697", "474411", "298097", "324428", "316943", "486476",
           "415183", "420899")
  for (id in ids) {
    doc <- identity_xml_2010(id = id)
    out <- .xml2010_candidate_identity(doc)
    expect_identical(as.character(out$doc), as.character(doc))
    expect_equal(nrow(out$provenance), 0L)
  }
})

test_that("preserved 2010 XML changes only the approved candidate identity", {
  zip <- Sys.getenv("SWELECTIONS_2010_IDENTITY_ZIP")
  skip_if(!nzchar(zip), "Set SWELECTIONS_2010_IDENTITY_ZIP for the preserved-source audit")
  skip_if_not(file.exists(zip))
  before <- unname(tools::md5sum(zip))
  expect_identical(before, "e758499f800cfbc49ce02c54c3d1dd79")
  members <- utils::unzip(zip, list = TRUE)$Name
  members <- members[grepl("[.]xml$", members)]
  changed <- list()
  for (member in members) {
    con <- unz(zip, member, open = "rb")
    doc <- tryCatch(xml2::read_xml(con, options = c("NONET", "NOBLANKS")),
                    finally = close(con))
    out <- .xml2010_candidate_identity(doc)
    if (!nrow(out$provenance)) {
      expect_identical(as.character(out$doc), as.character(doc))
      next
    }
    changed[[member]] <- nrow(out$provenance)
    expect_true(all(xml2::xml_name(xml2::xml_find_all(doc,
      ".//*[@KANDNR='451964']")) == "PERSONVAL"))
    expect_identical(unique(out$provenance$source_candidate_id), "451964")
    for (path in out$provenance$source_node)
      xml2::xml_set_attr(xml2::xml_find_first(out$doc, path), "KANDNR", "451964")
    expect_identical(as.character(out$doc), as.character(doc))
  }
  expect_identical(unlist(changed), c(slutresultat_00L.xml = 2L,
    slutresultat_0360L.xml = 12L, slutresultat_0382L.xml = 2L))
  expect_identical(unname(tools::md5sum(zip)), before)
})
