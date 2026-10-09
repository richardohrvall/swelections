test_that("2010 collection HTML preserves reported, blank and explicit zero fields", {
  file <- tempfile(fileext = ".html")
  withr::defer(unlink(file))
  row <- function(label, name, value) paste0('<tr><td>',label,'</td><td>',name,
    '</td><td>',value,'</td><td></td><td></td><td></td><td></td><td></td></tr>')
  doc <- xml2::read_xml('<VAL><KOMMUN KOD="0184" NAMN="Solna"><KRETS_KOMMUN KOD="018400"><ONSDAGSDISTRIKT KOD="K-0184-00" NAMN="Collection" RÖSTER="999"/></KRETS_KOMMUN></KOMMUN></VAL>')
  node <- xml2::xml_find_first(doc, './/ONSDAGSDISTRIKT')
  register <- .xml2018_reg_index(tibble::tibble(valtyp="KF",valomradeskod="0184",
    partiforkortning=c("A","B"),partibeteckning=c("Parti A","Parti B"),partikod=c("0001","0002")))
  page <- function(a,b,total,blank,other) writeLines(paste0('<html><table class="sorteringsbar_tabell">',
    row("A","Parti A",a),row("B","Parti B",b),row("","Giltiga r&#246;ster",total),
    row("BLANK","Blanka",blank),row("OG","Övriga ogiltiga",other),'</table></html>'),file)
  page("4","","4","0","")
  x <- .xml2014_collection(file,node,doc,"KF",register,2010L)
  expect_identical(x$antal_roster,c(4L,NA_integer_))
  expect_true(all(x$raknat))
  expect_identical(x$blanka_roster,c(0L,0L))
  expect_true(all(is.na(x$ovriga_ogiltiga)))
  expect_true(all(is.na(x$totalt_antal_roster)))
  expect_true(all(is.na(x$antal_roster_fg)))
  expect_true(all(is.na(x$diff_antal_roster)))
  text <- readLines(file)
  text <- sub("<td>4</td><td></td><td></td>","<td>4</td><td></td><td>+4</td>",text,fixed=TRUE)
  writeLines(text,file)
  enriched <- .xml2014_collection(file,node,doc,"KF",register,2010L)
  expect_identical(enriched$diff_antal_roster,c(4L,NA_integer_))
  expect_identical(names(x),c(names(.metadata_2014(.valresultat_schema(),2010L)),"raknat"))
  page("","","","","")
  x <- .xml2014_collection(file,node,doc,"KF",register,2010L)
  expect_identical(nrow(x),2L)
  expect_false(any(x$raknat))
  expect_true(all(is.na(x$antal_roster)))
  expect_true(all(is.na(x$giltiga_roster)))
  expect_true(all(is.na(x$totalt_antal_roster)))
  page("0","0","0","0","0")
  x <- .xml2014_collection(file,node,doc,"KF",register,2010L)
  expect_identical(x$antal_roster,c(0L,0L))
  expect_identical(x$totalt_antal_roster,c(0L,0L))
  expect_true(all(x$raknat))
})

test_that("2010 aggregate reporting sums known votes without zero-filling missing input", {
  x <- .valresultat_schema()[rep(NA_integer_,3),]
  x$valdistriktskod <- c("one","two","three");x$valdistriktstyp <- "uppsamlingsdistrikt"
  x$partikod <- "0001";x$valtyp <- "RD";x$raknat <- c(TRUE,TRUE,FALSE)
  x$antal_roster <- c(4L,NA_integer_,NA_integer_)
  original <- x
  out <- .xml2014_aggregate_results(x,"RD","riket",2010L)
  expect_identical(out$antal_roster,4L)
  expect_identical(x,original)
  x$antal_roster <- NA_integer_
  expect_identical(.xml2014_aggregate_results(x,"RD","riket",2010L)$antal_roster,NA_integer_)
  expect_identical(.xml2014_aggregate_results(original,"RD","riket",2014L)$antal_roster,NA_integer_)
})

test_that("2010 preliminary party aliases use official scoped designations only", {
  register <- .xml2018_reg_index(tibble::tibble(valtyp="KF",valomradeskod="1287",
    partiforkortning="SP",partibeteckning="Official local party",partikod="0310"))
  doc <- xml2::read_xml('<VAL><PARTI FÖRKORTNING="SSP" BETECKNING="Official local party"/><KOMMUN KOD="1287"/></VAL>')
  out <- .xml2010_preliminary_register(register,doc,"KF")
  expect_identical(.xml2018_parti("SSP","KF","1287",out)$partikod,"0310")
  expect_identical(register$data$partiforkortning,"SP")
})
