referendum_fixture <- function(wednesday = FALSE, valid = 12L) {
 tag <- if (wednesday) 'ONSDAGSDISTRIKT' else 'VALDISTRIKT'
 attendance <- if (wednesday) '' else '<VALDELTAGANDE RÖSTBERÄTTIGADE="20" SUMMA_RÖSTER="14" PROCENT="70,0"/>'
 xml2::read_xml(paste0('<', tag, ' KOD="00010101" NAMN="Example" RÖSTER="', valid, '">',
  '<GILTIGA PARTI="JA" RÖSTER="5" PROCENT="41,7"/><GILTIGA PARTI="NEJ" RÖSTER="6" PROCENT="50,0"/>',
  '<GILTIGA PARTI="BLANK" RÖSTER="1" PROCENT="8,3"/><OGILTIGA TEXT="OG" RÖSTER="2"/>', attendance, '</', tag, '>'))
}
referendum_output <- function(wednesday = FALSE) .referendum2003_node(
 referendum_fixture(wednesday), list(level = 'valdistrikt', fields = list(
 valdistriktskod = '00010101', valdistriktsnamn = 'Example',
 valdistriktstyp = if (wednesday) 'wednesday' else 'ordinary')), 'example.xml', '20030918144504')

test_that('referendum blank ballots are valid options, invalid ballots are separate', {
 x <- referendum_output()
 expect_setequal(x$rostningsalternativkod, c('JA','NEJ','BLANK'))
 expect_identical(sum(x$antal_roster), 12L)
 expect_true(all(x$giltiga_roster == 12L))
 expect_true(all(x$ogiltiga_roster == 2L & x$totalt_antal_roster == 14L))
 expect_equal(sum(x$andel_roster), 1)
 expect_equal(x$valdel, rep(.7,3))
 expect_identical(x$blankt_alternativ, c(FALSE,FALSE,TRUE))
 expect_false(any(grepl('parti', names(x))))
 expect_error(.referendum2003_node(referendum_fixture(valid=13L), list(level='valdistrikt',fields=list()), 'x','t'), 'totals disagree')
})

test_that('Wednesday vote observations never invent electorate or turnout', {
 x <- referendum_output(TRUE)
 expect_true(all(is.na(x$antal_rostberattigade)))
 expect_true(all(is.na(x$valdel)))
 expect_identical(x$totalt_antal_roster, rep(14L,3))
 expect_true(all(is.na(x$kall_valdeltagandeprocent)))
})

test_that('referendum API shares projection and English/Swedish values', {
 local_mocked_bindings(.referendum2003_raw = function(...) referendum_output(),
   .canonical_release_manifest = function(...) stop("manifest unavailable fixture"))
 full <- results(2003,election='referendum',source='local',detail='full')
 standard <- results(2003,election='F',source='local')
 expect_identical(standard,full[names(standard)])
 expect_gt(ncol(full),ncol(standard))
 sv <- valresultat(2003,val='F',source='local',detaljniva='full')
 expect_identical(.public_output(sv,'en'),full)
 expect_identical(results(2003,election='referendum',source='local',names='sv'),
  valresultat(2003,val='F',source='local'))
 expect_identical(results(election='referendum',year='all',source='local'),standard)
 expect_identical(results(election='referendum',from=2000,to=2005,source='local'),standard)
 expect_error(results(2003,election='referendum',count='preliminary'), 'final results only')
 expect_error(results(2002,election='referendum'), '2002')
 expect_error(results(2003,election='referendum',level='region'), 'geographic level')
 expect_error(seats(2003,election='referendum'), 'Invalid')
 expect_error(results(2003,election='referendum',update=TRUE), 'read-only')
 expect_error(results(2003,election='referendum',source='canonical'), 'manifest')
})

test_that('referendum parser rejects duplicate and missing voting options', {
 n<-referendum_fixture();xml2::xml_set_attr(xml2::xml_find_first(n,'./GILTIGA[@PARTI="BLANK"]'),'PARTI','JA')
 expect_error(.referendum2003_node(n,list(level='valdistrikt',fields=list()),'x','t'),'ballot categories')
})
electorate_fixture <- function() {
 rows<-vapply(seq_len(21L),function(i) paste0('<tr><td>COUNTY ',i,'</td><td>1</td><td>3</td><td>2</td><td>1</td><td>6</td></tr>'),'')
 xml2::read_html(paste0('<table><tr><td>LÄN</td><td>Förstagångsväljare</td><td>Svenska medborgare</td><td>Utlands-svenskar</td><td>Utländska medborgare</td><td>Totalt</td></tr>',paste(rows,collapse=''),'<tr><td>HELA RIKET</td><td>21</td><td>63</td><td>42</td><td>21</td><td>126</td></tr></table>'))
}
test_that('electorate composition is disjoint and does not add first-time voters', {
 x<-.referendum2003_electorate_table(electorate_fixture())
 expect_equal(nrow(x),22L)
 expect_true(all(x$domestic+x$abroad+x$foreign==x$total))
 expect_equal(x$total[x$source_area_name=='HELA RIKET'],126L)
 bad<-electorate_fixture();xml2::xml_set_text(xml2::xml_find_first(bad,'//tr[2]/td[6]'),'7')
 expect_error(.referendum2003_electorate_table(bad),'reconcile')
 bad<-electorate_fixture();xml2::xml_remove(xml2::xml_find_first(bad,'//tr[2]'))
 expect_error(.referendum2003_electorate_table(bad),'coverage')
})
test_that('unavailable finer electorate components remain typed missing values', {
 x<-referendum_output(TRUE)
 for(f in .referendum2003_electorate_fields){expect_identical(x[[f]],rep(NA_integer_,3));}
 expect_identical(.referendum2003_enrich_electorate(x,'local',tempdir(),'valdistrikt'),x)
 expect_identical(.referendum2003_enrich_electorate(x,'local',tempdir(),'riket'),x)
 expect_equal(sum(x$antal_roster),12L)
 expect_true(all(x$ogiltiga_roster==2L))
 expect_identical(x$blankt_alternativ,c(FALSE,FALSE,TRUE))
})
test_that('electorate groups follow source header definitions, not just a sum', {
 bad<-electorate_fixture();xml2::xml_set_text(xml2::xml_find_first(bad,'//tr[1]/td[3]'),'Utlands-svenskar')
 expect_error(.referendum2003_electorate_table(bad),'definitions/order')
})
