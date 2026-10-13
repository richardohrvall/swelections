test_that('2002 RD supplement is a pinned transcription with explicit unknown cells', {
  x <- .xml2002_supplement()
  constituency <- x[x$area_code != '00', ]
  expect_equal(nrow(constituency), 116L)
  expect_equal(sum(!is.na(constituency$votes)), 107L)
  expect_equal(sum(is.na(constituency$votes)), 9L)
  for (p in c('0421','ND','NYD','Pop'))
    expect_identical(sum(constituency$votes[constituency$party_alias == p], na.rm=TRUE),
      x$votes[x$area_code == '00' & x$party_alias == p])
  expect_identical(x$votes[x$area_code=='2125' & x$party_alias=='Pop'],0L)
  expect_true(is.na(x$votes[x$area_code=='0808' & x$party_alias=='Pop']))
})

supplement_node <- function(code='00',tag='NATION',total=13000L) {
  # This source has a complete original other partition; the supplement replaces
  # four known subtotals, never adds votes to the valid aggregate.
  xml2::read_xml(paste0('<',tag,' KOD="',code,'" RÖSTER="',total+200L,'">',
    '<GILTIGA PARTI="M" RÖSTER="200"/><GILTIGA PARTI="ÖVR" RÖSTER="',total,'">',
    '<VARAV_ÖVRIGA PARTI="ABC" RÖSTER="2"/>',
    '<VARAV_ÖVRIGA PARTI="0421" RÖSTER="274"/>',
    '<VARAV_ÖVRIGA PARTI="ND" RÖSTER="4122"/>',
    '<VARAV_ÖVRIGA PARTI="NYD" RÖSTER="106"/>',
    '<VARAV_ÖVRIGA PARTI="Pop" RÖSTER="8"/>',
    '<VARAV_ÖVRIGA PARTI="ÖVR" RÖSTER="',total-4512L,'"/>',
    '</GILTIGA><OGILTIGA TEXT="OG" RÖSTER="10"/></',tag,'>'))
}

test_that('2002 RD national overlay replaces the partition without changing totals', {
  d <- supplement_node()
  .xml2002_apply_supplement(d,'riket')
  p <- xml2::xml_find_all(d,'./GILTIGA[@PARTI="ÖVR"]/VARAV_ÖVRIGA')
  counts <- as.integer(xml2::xml_attr(p,'RÖSTER'))
  expect_identical(sum(counts),13000L)
  expect_identical(counts[xml2::xml_attr(p,'PARTI')=='ÖVR'],1030L)
  expect_identical(.xml2018_int(d,'RÖSTER'),13200L)
  expect_identical(.xml2018_int(xml2::xml_find_first(d,'./OGILTIGA'),'RÖSTER'),10L)
  expect_identical(.xml2018_int(xml2::xml_find_first(d,'./GILTIGA[@PARTI="M"]'),'RÖSTER'),200L)
  expect_identical(anyDuplicated(xml2::xml_attr(p,'PARTI')),0L)
})

test_that('2002 RD unknown cells remain NA and inside the numeric other residual', {
  d <- supplement_node('0808','KRETS_RIKSDAG')
  .xml2002_apply_supplement(d,'riksdagsvalkrets')
  p <- xml2::xml_find_all(d,'./GILTIGA[@PARTI="ÖVR"]/VARAV_ÖVRIGA')
  expect_identical(sum(as.integer(xml2::xml_attr(p,'RÖSTER'))),13000L)
  unknown <- xml2::xml_find_all(d,'./GILTIGA[@PARTI="NYD" or @PARTI="Pop"]')
  expect_length(unknown,2L)
  expect_true(all(is.na(xml2::xml_attr(unknown,'RÖSTER'))))
  expect_false(any(xml2::xml_attr(p,'PARTI') %in% c('NYD','Pop')))
  expect_identical(as.integer(xml2::xml_attr(p,'RÖSTER'))[xml2::xml_attr(p,'PARTI')=='ÖVR'],12768L)
})

test_that('2002 county totals require complete disclosure and lower levels stay untouched', {
  d <- xml2::read_xml('<LÄN KOD="01"><KRETS_RIKSDAG KOD="0101"/><KRETS_RIKSDAG KOD="0102"/></LÄN>')
  x <- .xml2002_supplement_values(d,'lan')
  expect_identical(x$votes,c(274L,3742L,NA_integer_,NA_integer_))
  d <- supplement_node('0114','KOMMUN'); before <- as.character(d)
  .xml2002_apply_supplement(d,'kommun')
  expect_identical(as.character(d),before)
  expect_error(.xml2002_apply_supplement(supplement_node(total=5000L),'riket'), 'exceeds')
})

test_that('explicit constituency zero corrects observed lower counts without allocating positive votes', {
  d <- supplement_node('2180','KOMMUN')
  .xml2002_apply_supplement(d,'kommun','2125')
  p <- xml2::xml_find_all(d,'./GILTIGA[@PARTI="ÖVR"]/VARAV_ÖVRIGA')
  counts <- as.integer(xml2::xml_attr(p,'RÖSTER')); alias <- xml2::xml_attr(p,'PARTI')
  expect_identical(counts[alias=='Pop'],0L)
  expect_identical(counts[alias=='ND'],4122L)
  expect_identical(sum(counts),13000L)
  expect_identical(counts[alias=='ÖVR'],8496L)
  d <- supplement_node('0114','KOMMUN');before <- as.character(d)
  .xml2002_apply_supplement(d,'kommun','0102')
  expect_identical(as.character(d),before)
})
