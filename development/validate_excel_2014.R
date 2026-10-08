# Independent OOXML/SKV cross-check. R-only development aid, no runtime reader.
pkgload::load_all(".", quiet = TRUE)
file <- ".local-data/rkl/2014/valresultat/2014_kommunval_per_valdistrikt.xlsx"
read_member <- function(member) {
  con <- unz(file, member, "rb"); on.exit(close(con))
  xml2::read_xml(readBin(con, "raw", n = 10000000L))
}
ns <- c(m = "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
doc <- read_member("xl/worksheets/sheet1.xml")
strings <- xml2::xml_text(xml2::xml_find_all(read_member("xl/sharedStrings.xml"), "./m:si", ns))
header <- xml2::xml_find_all(doc, "./m:sheetData/m:row[2]/m:c", ns)
labels <- strings[as.integer(xml2::xml_text(xml2::xml_find_all(header, "./m:v", ns))) + 1L]
columns <- sub("[0-9]+$", "", xml2::xml_attr(header, "r"))
path <- ".local-data/rkl/2014/valresultat/2014_kommunval_per_valdistrikt.skv"
skv <- utils::read.table(path, skip = 1L, sep = ";", quote = "", comment.char = "",
  fill = TRUE, colClasses = "character", fileEncoding = "latin1")
fields <- c("M tal", "C tal", "FP tal", "KD tal", "S tal", "V tal", "MP tal",
  "SD tal", "FI tal", "Rost Giltiga", "Rostande", "Rostb")
checks <- 0L
for (field in fields) {
  i <- match(field, labels); stopifnot(!is.na(i))
  cells <- xml2::xml_find_all(doc, paste0("./m:sheetData/m:row[position()>2]/m:c[starts-with(@r,'",
    columns[[i]], "')]"), ns)
  # Select by exact column letters, rather than prefix (A must not match AA).
  cells <- cells[sub("[0-9]+$", "", xml2::xml_attr(cells, "r")) == columns[[i]]]
  rows <- as.integer(sub("^[A-Z]+", "", xml2::xml_attr(cells, "r"))) - 3L
  numbers <- as.numeric(xml2::xml_text(xml2::xml_find_all(cells, "./m:v", ns)))
  value <- rep(NA_real_, nrow(skv)); value[rows] <- numbers
  expected <- suppressWarnings(as.numeric(skv[[i]]))
  stopifnot(identical(value, expected))
  checks <- checks + sum(!is.na(value))
}
jsonlite::write_json(list(file = file, md5 = unname(tools::md5sum(file)),
  sha256 = swelections:::.canonical_sha256(file), rows = nrow(skv), fields = fields,
  comparisons = checks, differences = 0L),
  ".local-data/validation-2014/excel-totals.json", pretty = TRUE, auto_unbox = TRUE)
cat("PASS official Excel/SKV", nrow(skv), "districts", checks, "counts\n")
