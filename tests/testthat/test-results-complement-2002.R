complement_fixture <- function() {
 major <- c('0001','0004','0003','0068','0055','0002','0005')
 v <- expand.grid(llkkdddd=c('13800101','13800201','13809800'),partikod=c(major,'9997','9999'),stringsAsFactors=FALSE)
 v$antrost <- 1; v$partinamn <- v$partikod
 t <- data.frame(district=c('13800101','13800201','13809800'),giltiga=8,ogiltiga=1,rostande=9,tot=c(20,30,0),m=1,c=1,fp=1,kd=1,mp=1,s=1,v=1,vvr=1,
 municipal_constituency=c('138001','138002',NA),municipal_constituency_name=c('West','East',NA),collection=c(FALSE,FALSE,TRUE),district_name=c('One','Two','Postal'))
 node <- xml2::read_xml('<KOMMUN KOD="1380" RÖSTER="24"><GILTIGA PARTI="M" RÖSTER="3"/><GILTIGA PARTI="ÖVR" RÖSTER="3"><VARAV_ÖVRIGA PARTI="ÖVR" RÖSTER="3"/></GILTIGA><OGILTIGA TEXT="OG" RÖSTER="3"/><VALDELTAGANDE SUMMA_RÖSTER="27"/></KOMMUN>')
 list(votes=v,totals=t,node=node,municipality='1380',municipality_name='Halmstad',county='13',county_name='Halland',constituency='1318',constituency_name='Halland')
}
test_that('complementary votes require independent district and VM reconciliation', {
 b <- complement_fixture()
 expect_true(.rd2002_reconcile(b$votes,b$totals,b$node))
 for (field in c('antrost','partikod','llkkdddd')) {
  z <- b$votes; z[[field]][1] <- NA
  expect_error(.rd2002_reconcile(z,b$totals,b$node),'do not reconcile')
 }
 z <- b$votes; z$antrost[1] <- 2
 expect_error(.rd2002_reconcile(z,b$totals,b$node),'do not reconcile')
 expect_error(.rd2002_reconcile(rbind(b$votes,b$votes[1,]),b$totals,b$node),'do not reconcile')
 z <- b$totals; z$tot[1] <- NA
 expect_error(.rd2002_reconcile(b$votes,z,b$node),'do not reconcile')
 xml2::xml_set_attr(b$node,'RÖSTER','25')
 expect_error(.rd2002_reconcile(b$votes,b$totals,b$node),'do not reconcile')
})
test_that('complement retains postal votes outside municipal constituencies', {
 b <- complement_fixture()
 d <- .rd2002_complement_rows(b,'valdistrikt')
 c <- .rd2002_complement_rows(b,'kommunvalkrets')
 expect_equal(nrow(d),24L); expect_equal(nrow(c),16L)
 expect_true(all(is.na(d$kommunvalkretskod[d$valdistriktskod=='13809800'])))
 expect_identical(unique(c$kommunvalkretskod),c('138001','138002'))
 expect_equal(sum(d$antal_roster),24); expect_equal(sum(c$antal_roster),16)
 expect_true(all(is.na(d$blanka_roster))); expect_true(all(is.na(d$antal_roster_fg)))
 expect_true(all(is.na(d$partikod[d$ovriga_partier])))
 expect_false(any(d$partikod=='9999',na.rm=TRUE))
 expect_equal(unique(d$antal_rostberattigade[d$valdistriktskod=='13809800']),0L)
 b$totals$municipal_constituency[!b$totals$collection] <- '138000'
 expect_equal(nrow(.rd2002_complement_rows(b,'kommunvalkrets')),0L)
 expect_true(all(is.na(.rd2002_complement_rows(b,'valdistrikt')$kommunvalkretskod)))
})
test_that('VM result exports take priority; only the three verified gaps may be supplemented', {
 codes <- c('1380','1381','1384',sprintf('%04d',3000:3286))
 doc <- xml2::read_xml(paste0('<VAL><NATION><LÄN><KRETS_RIKSDAG>',paste0('<KOMMUN KOD="',codes,'"/>',collapse=''),'</KRETS_RIKSDAG></LÄN></NATION></VAL>'))
 local_mocked_bindings(.xml2002_read=function(...) doc)
 s <- list(sources=data.frame(export=paste0('slutresultat_',codes,'R.xml')))
 expect_length(.rd2002_result_coverage(s)$missing,0)
 s$sources <- s$sources[-1, ,drop=FALSE]
 expect_identical(.rd2002_result_coverage(s)$missing,'1380')
 s$sources <- s$sources[-nrow(s$sources), ,drop=FALSE]
 expect_error(.rd2002_result_coverage(s),'outside the verified')
})
test_that('a changed or missing complementary source is rejected before import', {
 s <- list(root=tempdir())
 expect_error(.rd2002_complement_sources(s),'Missing or changed complementary')
})
test_that('complementary results preserve full/standard and English/Swedish projection', {
 b <- complement_fixture()
 x <- .rd2002_complement_rows(b,'valdistrikt')
 x <- .xml2002_metadata(x)
 x <- .valresultat_public_andelar_2026(x)
 full <- .public_detail(x,'valresultat','full','RD')
 standard <- .public_detail(x,'valresultat','standard','RD')
 expect_identical(standard,full[names(standard)])
 expect_identical(nrow(standard),nrow(full))
 expect_identical(.public_output_names(.public_output_names(standard,'en'),'sv'),standard)
 expect_true(all(is.na(x$valdel[x$valdistriktstyp=='uppsamlingsdistrikt'])))
 expect_equal(unique(x$valdel[x$valdistriktskod=='13800101']),9/20)
})
