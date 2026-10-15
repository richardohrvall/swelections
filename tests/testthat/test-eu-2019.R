test_that('2019 XML separates final detail from preliminary other parties', {
 reg <- .xml2018_reg_index(tibble::tibble(valtyp='E',valomradeskod='00',
   partiforkortning='A',partibeteckning='Alpha',partikod='0001'))
 doc <- xml2::read_xml('<VAL><NATION KOD="00" NAMN="Sverige" RÖSTER="12"><GILTIGA PARTI="A" RÖSTER="10"/><ÖVRIGA_GILTIGA RÖSTER="2"/><OGILTIGA TEXT="BLANK" RÖSTER="1"/><OGILTIGA TEXT="OGEJ" RÖSTER="0"/><OGILTIGA TEXT="OG" RÖSTER="1"/></NATION></VAL>')
 x <- .eu2019_result_node(xml2::xml_find_first(doc,'./NATION'),doc,'riket',reg,'preliminar')
 expect_identical(x$antal_roster,c(10L,2L))
 expect_identical(x$ovriga_partier,c(FALSE,TRUE))
 expect_true(is.na(x$partikod[2]))
 expect_identical(unique(x$totalt_antal_roster),14L)
 expect_identical(unique(x$ogiltiga_roster),2L)
 expect_true(all(is.na(x$antal_rostberattigade)))
})

test_that('2019 preference reader uses candidate ID and does not confuse rank and position', {
 reg <- .xml2018_reg_index(tibble::tibble(valtyp='E',valomradeskod='00',
   partiforkortning='A',partibeteckning='Alpha',partikod='0001'))
 doc <- xml2::read_xml('<NATION><GILTIGA PARTI="A"><PERSONVAL KANDNR="12" PERSONKRYSS="3"/><VALSEDEL LISTNUMMER="0001-17241" RÖSTER="10" PERSONKRYSS="3"><PERSONVAL KANDNR="12" KANDIDAT="7" ORDNING="1" NAMN="Namnet Gallrat" PERSONKRYSS="3"/></VALSEDEL><PARTISEDEL LISTNUMMER="0001-90000" RÖSTER="2"/></GILTIGA></NATION>')
 b <- .eu2019_preferences_node(doc,reg,'00')
 expect_identical(b$votes$kandidatnummer,'12')
 expect_identical(b$votes$antal_personroster,3L)
 expect_equal(sum(b$lists$antal_listroster),12L)
 expect_true(all(is.na(b$votes$kandidatnamn_lista)))
 xml2::xml_set_attr(xml2::xml_find_first(doc,'.//VALSEDEL'),'PERSONKRYSS','4')
 expect_error(.eu2019_preferences_node(doc,reg,'00'),'totals disagree')
})

test_that('2019 geography never invents a technical municipal constituency', {
 doc<-xml2::read_xml('<KOMMUN KOD="0114" NAMN="Upplands Väsby"><KRETS_KOMMUN KOD="011400" NAMN="Teknisk"><ONSDAGSDISTRIKT KOD="E-0114-00" NAMN="Onsdagsräkning"/></KRETS_KOMMUN></KOMMUN>')
 g<-.eu2019_geo(xml2::xml_find_first(doc,'.//ONSDAGSDISTRIKT'),'valdistrikt')
 expect_identical(g$kommunkod,'0114');expect_identical(g$lankod,'01')
 expect_identical(g$valdistriktskod,'E-0114-00')
 expect_identical(g$valdistriktstyp,'uppsamlingsdistrikt')
 expect_true(is.na(g$kommunvalkretskod))
})

test_that('2019 wrappers share selection and output naming', {
 fixture<-tibble::tibble(valar=2019L,valtyp='E',kandidatnummer='12',partikod='0001',namn=NA_character_)
 local_mocked_bindings(.eu2019_read=function(table,args)fixture)
 en<-c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
 sv<-c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster')
 for(i in seq_along(en)) {
  a<-do.call(get(en[i],envir=asNamespace("swelections")),list(year=2019,election='european',source='local',detail='full'))
  b<-do.call(get(sv[i],envir=asNamespace("swelections")),list(ar=2019,val='E',source='local',detaljniva='full'))
  expect_identical(a,.public_output_names(b,'en'))
  expect_identical(a$election_year,2019L)
 }
})

test_that('2019 preserved sources reproduce complete fixed election observations', {
 root<-Sys.getenv('SWEELECTIONS_EU2019_ROOT')
 skip_if(!nzchar(root),'Set SWEELECTIONS_EU2019_ROOT for preserved-source integration.')
 kd<-candidacies(2019,election='E',source='local',data_dir=root,detail='full')
 c<-candidates(2019,election='E',source='local',data_dir=root)
 e<-elected(2019,election='E',source='local',data_dir=root)
 s<-substitutes(2019,election='E',source='local',data_dir=root)
 p<-preference_votes(2019,election='E',source='local',data_dir=root,by_list=TRUE,include_zeros=FALSE)
 expect_equal(nrow(kd),562L);expect_equal(sum(kd$valid),556L);expect_equal(nrow(c),556L)
 expect_equal(nrow(e),20L);expect_equal(nrow(s),74L)
 expect_equal(sum(p$preference_votes),1634596L);expect_equal(nrow(p),518L)
 expect_true(all(is.na(kd$name)));expect_true(all(is.na(p$name)))
 expect_equal(p$preference_votes[p$candidate_number=='534261' & p$party_code=='1351'],2L)
 expect_equal(c$total_preference_votes[c$candidate_number=='534261' & c$party_code=='1140'],0L)
 expect_equal(sum(c$total_preference_votes),1627141L)
})
