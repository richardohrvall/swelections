test_that('2004 keys identify ballot positions, never physical persons', {
 expect_identical(.eu2004_key(c('00001','00002'),c(1L,1L)),c('2004:E:ballot:00001:1','2004:E:ballot:00002:1'))
 expect_error(.eu2004_read('results',list(rakning='preliminar')),'complete preliminary')
 expect_error(.eu2004_file('final','remote',NULL),'pinned preserved original')
})

test_that('2004 aggregate other votes are retained without invented candidates', {
 d<-xml2::read_xml('<VAL><NATION><GILTIGA PARTI="ÖVR" RÖSTER="1000"><VARAV_ÖVRIGA PARTI="A" RÖSTER="57"/><VARAV_ÖVRIGA PARTI="ÖVR" RÖSTER="943"/></GILTIGA></NATION></VAL>')
 x<-.eu2004_adapt(d,tibble::tibble())
 expect_identical(.xml2018_int(xml2::xml_find_first(x,'//HANDSKRIVNA'),'RÖSTER'),943L)
 expect_length(xml2::xml_find_all(x,'//PERSONVAL'),0L)
 expect_length(xml2::xml_find_all(x,'//ÖVRIGA_GILTIGA/GILTIGA'),1L)
})

test_that('2004 preference rank is not ballot position', {
 d<-xml2::read_xml('<VAL><NATION><GILTIGA PARTI="M"><VALSEDEL LISTNUMMER="0001-00001"><PERSONVAL ORDNING="1" KANDIDAT="32" PERSONKRYSS="7"/></VALSEDEL></GILTIGA></NATION></VAL>')
 x<-.eu2004_adapt(d,tibble::tibble(kandidatnummer='2004:E:ballot:00001:32'))
 n<-xml2::xml_find_first(x,'//PERSONVAL')
 expect_identical(.xml2018_attr(n,'KANDNR'),'2004:E:ballot:00001:32')
 expect_identical(.xml2018_attr(n,'ORDNING'),'1')
 expect_identical(.xml2018_int(n,'PERSONKRYSS'),7L)
})

test_that('2004 wrappers independently project names and detail', {
 fixture<-tibble::tibble(valar=2004L,valtyp='E',partikod='0001',kandidatnummer='2004:E:ballot:00001:1',antal_personroster=2L)
 local_mocked_bindings(.eu2004_read=function(table,args)fixture)
 en<-c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
 sv<-c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster')
 for(i in seq_along(en))for(lang in c('en','sv'))for(detail in c('standard','full')) {
  a<-do.call(get(en[i],envir=asNamespace('swelections')),list(year=2004,election='E',source='local',names=lang,detail=detail))
  b<-do.call(get(sv[i],envir=asNamespace('swelections')),list(ar=2004,val='E',source='local',names=lang,detaljniva=detail))
  expect_identical(a,b)
 }
})

test_that('2004 preserved sources reconcile with the established final protocol', {
 root<-Sys.getenv('SWEELECTIONS_EU2004_ROOT')
 skip_if(!nzchar(root),'Set SWEELECTIONS_EU2004_ROOT for preserved-source integration.')
 b<-.eu2004_bundle(list(source='local',data_dir=root))
 expect_equal(nrow(b$kd),382L);expect_equal(length(unique(b$kd$listnummer)),30L)
 expect_equal(nrow(b$relations$valda),19L);expect_equal(nrow(b$relations$ersattare),71L)
 expect_equal(sum(b$seats$antal_mandat),19L);expect_equal(sum(b$seats$antal_tomma_stolar),0L)
 p<-b$votes[b$votes$.geo=='00',]
 expect_equal(sum(p$antal_personroster),1480960L)
 expect_equal(sum(p$antal_personroster[p$partikod=='0110']),14450L)
 expect_equal(sum(b$source_designations$antal_roster),943L)
 expect_equal(sum(b$context$geografiniva=='valdistrikt'),6271L)
 d<-b$result[b$result$geografiniva=='valdistrikt',];u<-d[!duplicated(d$valdistriktskod),]
 expect_equal(sum(d$antal_roster),2512069L)
 expect_equal(sum(u$totalt_antal_roster),2584464L)
 expect_equal(sum(u$antal_rostberattigade,na.rm=TRUE),6827870L)
 expect_equal(sum(u$valdistriktstyp=='uppsamlingsdistrikt'),396L)
 expect_true(all(is.na(u$antal_rostberattigade[u$valdistriktstyp=='uppsamlingsdistrikt'])))
 expect_equal(sum(d$antal_roster[d$valdistriktskod=='E-0483-02']),0L)
 expect_true(all(is.na(b$kd$giltig)))
})
