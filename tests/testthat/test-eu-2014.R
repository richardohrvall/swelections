test_that('2014 result categories preserve unspecified valid votes and old invalid semantics', {
 reg<-.xml2018_reg_index(tibble::tibble(valtyp='E',valomradeskod='00',
  partiforkortning=c('A','scl'),partibeteckning=c('Alpha','Socialisterna'),partikod=c('0001',NA_character_)))
 doc<-xml2::read_xml('<VAL><NATION KOD="00" NAMN="Sverige" RÖSTER="20"><GILTIGA PARTI="A" RÖSTER="10"/><ÖVRIGA_GILTIGA><GILTIGA PARTI="scl" RÖSTER="0"/><HANDSKRIVNA RÖSTER="10"/></ÖVRIGA_GILTIGA><OGILTIGA TEXT="BLANK" RÖSTER="2"/><OGILTIGA TEXT="OG" RÖSTER="1"/></NATION></VAL>')
 x<-.eu2014_result_node(xml2::xml_find_first(doc,'./NATION'),doc,'riket',reg)
 expect_identical(x$antal_roster,c(10L,0L,10L))
 expect_identical(x$ovriga_partier,c(FALSE,FALSE,TRUE))
 expect_identical(x$partibeteckning[2],'Socialisterna')
 expect_true(is.na(x$partikod[3]))
 expect_identical(unique(x$giltiga_roster),20L)
 expect_identical(unique(x$ogiltiga_roster),3L)
 expect_identical(unique(x$totalt_antal_roster),23L)
 expect_true(all(is.na(x$roster_ej_anmalt_deltagande)))
 expect_identical(unique(x$valdatum),'2014-05-25')
})

test_that('2014 raw source labels do not invent parties or fill the ten votes', {
 f<-tempfile(fileext='.skv');on.exit(unlink(f))
 writeLines('LAN;KOM;DISTRIKT;NAMN_DISTRIKT;PARTIBETECKNING;ANTAL\n05;80;1001;Example;Exact label;2',f)
 ctx<-tibble::tibble(geografiniva='valdistrikt',.geo=c('05801001','05803201'))
 residual<-tibble::tibble(valdistriktskod=c('05801001','05803201'),antal_roster=c(2L,10L))
 x<-.eu2014_source_designations(f,ctx,residual)
 expect_equal(sum(x$antal_roster),12L)
 expect_equal(x$antal_roster[x$kall_partibeteckning_saknas],10L)
 expect_true(is.na(x$kall_partibeteckning[x$kall_partibeteckning_saknas]))
 expect_identical(x$kall_enhetskod[x$kall_partibeteckning_saknas],'05803201')
 residual$antal_roster[2]<-11L
 expect_error(.eu2014_source_designations(f,ctx,residual),'disclosure gap')
})

test_that('2014 complete preliminary is never inferred from valnatt or final', {
 expect_error(.eu2014_read('results',list(rakning='preliminar')),'no recovered complete preliminary')
 expect_error(.eu2014_file('final','remote',NULL),'preserved original local')
})

test_that('2014 English and Swedish wrappers share detail and output-name handling', {
 fixture<-tibble::tibble(valar=2014L,valtyp='E',partikod=NA_character_,
  partibeteckning='Handskrivna roster',antal_roster=10L,ovriga_partier=TRUE,
  kall_roster_utan_partibeteckning=10L)
 local_mocked_bindings(.eu2014_read=function(table,args)fixture)
 en<-c('results','seats','candidacies','candidates','elected','substitutes','preference_votes')
 sv<-c('valresultat','mandat','kandidaturer','kandidater','valda','ersattare','personroster')
 for(i in seq_along(en))for(lang in c('en','sv'))for(detail in c('standard','full')){
  a<-do.call(get(en[i],envir=asNamespace('swelections')),list(year=2014,election='european',source='local',names=lang,detail=detail))
  b<-do.call(get(sv[i],envir=asNamespace('swelections')),list(ar=2014,val='E',source='local',names=lang,detaljniva=detail))
  expect_identical(a,b)
 }
 a<-results(2014,election='E',detail='standard');b<-results(2014,election='E',detail='full')
 expect_false('source_votes_without_party_designation'%in%names(a))
 expect_identical(b$source_votes_without_party_designation,10L)
 expect_identical(a,b[names(a)])
})

test_that('2014 original sources preserve complete fixed election observations', {
 root<-Sys.getenv('SWEELECTIONS_EU2014_ROOT')
 skip_if(!nzchar(root),'Set SWEELECTIONS_EU2014_ROOT for preserved-source integration.')
 k<-candidacies(2014,election='E',source='local',data_dir=root,detail='full')
 c<-candidates(2014,election='E',source='local',data_dir=root)
 e<-elected(2014,election='E',source='local',data_dir=root)
 s<-substitutes(2014,election='E',source='local',data_dir=root)
 p<-preference_votes(2014,election='E',source='local',data_dir=root,by_list=TRUE,include_zeros=FALSE)
 expect_equal(nrow(k),376L);expect_true(all(is.na(k$valid)));expect_equal(nrow(c),376L)
 expect_equal(nrow(e),20L);expect_equal(nrow(s),74L)
 expect_equal(sum(c$total_preference_votes),1859375L)
 expect_equal(sum(p$preference_votes),1859375L)
 expect_true(all(is.na(k$name)));expect_true(all(is.na(p$name)))
})
