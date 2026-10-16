test_that('2009 source-position keys do not assert a physical person identity', {
 expect_identical(.eu2009_key(c('04536','04536'),c('18','32')),
  c('2009:E:ballot:04536:18','2009:E:ballot:04536:32'))
 expect_error(.eu2009_read('results',list(rakning='preliminar')),'no verified complete preliminary')
 expect_error(.eu2009_file('final','remote',NULL),'pinned preserved original')
})

test_that('2009 other-party nesting retains all valid votes without double counting', {
 d<-xml2::read_xml('<VAL><NATION KOD="00" RÖSTER="30"><GILTIGA PARTI="A" RÖSTER="10"/><GILTIGA PARTI="ÖVR" RÖSTER="20"><VARAV_ÖVRIGA PARTI="B" RÖSTER="17"/></GILTIGA></NATION></VAL>')
 x<-.eu2009_adapt(d,tibble::tibble())
 expect_equal(.xml2018_int(xml2::xml_find_first(x,'./NATION/ÖVRIGA_GILTIGA/GILTIGA'),'RÖSTER'),17L)
 expect_equal(.xml2018_int(xml2::xml_find_first(x,'./NATION/ÖVRIGA_GILTIGA/HANDSKRIVNA'),'RÖSTER'),3L)
 expect_length(xml2::xml_find_all(x,'./NATION/GILTIGA[@PARTI="ÖVR"]'),0L)
 d<-xml2::read_xml('<VAL><NATION><GILTIGA PARTI="ÖVR" RÖSTER="2"/></NATION></VAL>')
 expect_equal(.xml2018_int(xml2::xml_find_first(.eu2009_adapt(d,tibble::tibble()),'//HANDSKRIVNA'),'RÖSTER'),2L)
})

test_that('2009 wrappers keep names and detail independent', {
 fixture<-tibble::tibble(valar=2009L,valtyp='E',partikod='0909',
  kandidatnummer='2009:E:ballot:04536:18',namn='Per Johansson',antal_personroster=22L)
 local_mocked_bindings(.eu2009_read=function(table,args)fixture)
 en<-c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
 sv<-c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster')
 for(i in seq_along(en))for(lang in c('en','sv'))for(detail in c('standard','full')) {
  a<-do.call(get(en[i],envir=asNamespace('swelections')),list(year=2009,election='E',source='local',names=lang,detail=detail))
  b<-do.call(get(sv[i],envir=asNamespace('swelections')),list(ar=2009,val='E',source='local',names=lang,detaljniva=detail))
  expect_identical(a,b)
 }
})

test_that('2009 preserved observations retain homonyms and inconsistent small-party counts', {
 root<-Sys.getenv('SWEELECTIONS_EU2009_ROOT')
 skip_if(!nzchar(root),'Set SWEELECTIONS_EU2009_ROOT for preserved-source integration.')
 b<-.eu2009_bundle(list(source='local',data_dir=root))
 expect_equal(nrow(b$kd),500L)
 p<-b$kd[b$kd$listnummer=='04536' & b$kd$namn=='Per Johansson',]
 expect_identical(p$ordning,c(18L,32L));expect_identical(p$alder_pa_valdagen,c(48L,38L))
 expect_length(unique(p$kandidatnummer),2L)
 expect_equal(nrow(b$relations$valda),18L);expect_equal(nrow(b$relations$ersattare),68L)
 expect_equal(sum(b$seats$antal_mandat),18L);expect_equal(sum(b$seats$antal_tomma_stolar),0L)
 expect_equal(sum(b$votes$antal_personroster[b$votes$.geo=='00']),1874130L)
 expect_equal(sum(b$small$antal_personroster[b$small$geografiniva=='riket']),2665L)
 expect_equal(sum(b$small$antal_personroster[b$small$geografiniva=='lan']),2677L)
 expect_equal(sum(b$small$antal_personroster[b$small$geografiniva=='kommun']),2677L)
 expect_equal(sum(b$small$antal_personroster[b$small$geografiniva=='valdistrikt']),2571L)
 expect_equal(sum(b$source_designations$antal_roster),1130L)
 gap<-b$source_designations[b$source_designations$kall_partibeteckning_saknas,]
 expect_equal(gap$antal_roster[match(c('0180','0125'),gap$kall_enhetskod)],c(2L,1L))
 expect_true(all(is.na(b$kd$giltig)))
})
test_that('2009 preference rank is never used as ballot position or candidate identity', {
 d<-xml2::read_xml('<VAL><NATION><GILTIGA PARTI="Ai"><VALSEDEL LISTNUMMER="0909-04536"><PERSONVAL ORDNING="1" KANDIDAT="32" NAMN="Per Johansson" PERSONKRYSS="7"/></VALSEDEL></GILTIGA></NATION></VAL>')
 k<-tibble::tibble(kandidatnummer='2009:E:ballot:04536:32')
 x<-.eu2009_adapt(d,k);n<-xml2::xml_find_first(x,'//PERSONVAL')
 expect_identical(.xml2018_attr(n,'KANDNR'),'2009:E:ballot:04536:32')
 expect_identical(.xml2018_attr(n,'ORDNING'),'1')
 expect_identical(.xml2018_attr(n,'KANDIDAT'),'32')
 expect_identical(.xml2018_int(n,'PERSONKRYSS'),7L)
})

test_that('2009 small-party homonym columns are distinct observations without list linkage', {
 b<-list(votes=tibble::tibble(.geo='00',partikod='0909',listnummer=NA_character_,
  kandidatnummer=c('2009:E:source-column:36','2009:E:source-column:47'),
  antal_personroster=c(22L,22L),kandidatnamn_lista='Per Johansson'),
  lists=tibble::tibble(.geo='00',partikod='0909',listnummer=NA_character_,antal_listroster=NA_integer_),
  parties=tibble::tibble(.geo='00',partikod='0909',antal_partiroster=2862L),context=tibble::tibble(.geo='00'))
 k<-tibble::tibble(kandidatnummer='2009:E:ballot:04536:18',partikod='0909',listnummer='04536',namn='Per Johansson',partiforkortning='Ai',partibeteckning='ArbetarInitiativet')
 x<-.eu2009_preference_view(b,'riket',k,TRUE,FALSE,character())
 expect_equal(nrow(x),2L);expect_equal(sum(x$antal_personroster),44L)
 expect_true(all(is.na(x$listnummer)));expect_true(all(is.na(x$andel_personroster_lista)))
 expect_true(all(is.na(x$kvalificerad_personval)))
 expect_identical(x$valdatum,rep('2009-06-07',2))
 expect_identical(x$kandidatnummer,b$votes$kandidatnummer)
})
test_that('2009 candidate area counts retain the established qualification semantics', {
 kd<-tibble::tibble(giltig=rep(NA,3))
 fixture<-list(kd=kd,votes=tibble::tibble(.geo='00',kandidatnummer=c('A','B'),antal_personroster=c(3L,2L)),
  qualified=tibble::tibble(partikod='0001',kandidatnummer='A'),relations=list(valda=NULL))
 local_mocked_bindings(.eu2009_bundle=function(args)fixture,
  .kandidater_bas=function(k,ar)tibble::tibble(kandidatnummer=c('A','B','C'),partikod='0001'),
  add_valda_to_kandidater_2026=function(out,valda)out)
 x<-.eu2009_read('candidates',list(resultat=TRUE))
 expect_identical(x$antal_personroster_totalt,c(3L,2L,NA_integer_))
 expect_identical(x$kvalificerad_personval,c(TRUE,FALSE,NA))
 expect_identical(x$antal_personvalsomraden,c(1L,0L,NA_integer_))
})