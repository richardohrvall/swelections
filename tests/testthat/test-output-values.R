library(testthat)
test_that('semantic categories use English canonical values and Swedish presentation', {
 x <- tibble::tibble(rakningstillfalle=c('slutlig','preliminar'),
   geografiniva=c('kommun','valdistrikt'),valdistriktstyp=c('valdistrikt','uppsamlingsdistrikt'),
   kon=c('M','Kvinna'),valsedelsstatus=c('Definitiv','Utkast'),
   status_jamforelse=c('Kan jämföras','ej jämförbar: Ny'),
   valklass=c('ordinarie val','omval'))
 en <- .public_output(x,'en');sv <- .public_output(x,'sv')
 expect_identical(en$count_stage,c('final','preliminary'))
 expect_identical(sv$rakningstillfalle,c('slutlig','preliminar'))
 expect_identical(en$geographic_level,c('municipality','district'))
 expect_identical(sv$geografiniva,c('kommun','valdistrikt'))
 expect_identical(en$district_type,c('ordinary','collection'))
 expect_identical(en$sex,c('male','female'));expect_identical(sv$kon,c('man','kvinna'))
 expect_identical(en$ballot_status,c('final','draft'))
 expect_identical(sv$valsedelsstatus,c('definitiv','utkast'))
 expect_identical(en$comparison_status,c('comparable','not_comparable_new'))
 expect_identical(en$election_kind,c('ordinary','re_election'))
 expect_identical(sv$valklass,c('ordinarie','omval'))
 expect_identical(.canonical_encode(x),en)
 expect_identical(.values_en(en),en)
 expect_error(.values_en(tibble::tibble(count_stage='obekant')),'Unknown technical category')
})

test_that('consent and declaration are lossless Boolean/applicability pairs', {
 x<-tibble::tibble(samtycke=c('ja','nej','irrelevant',NA_character_),
   forklaring=c('irrelevant','ja','nej',NA_character_),giltig=c(TRUE,FALSE,TRUE,NA))
 en<-.public_output(x,'en');sv<-.public_output(x,'sv')
 expect_identical(en$consent,c(TRUE,FALSE,NA,NA))
 expect_identical(en$consent_applicable,c(TRUE,TRUE,FALSE,NA))
 expect_identical(en$candidate_declaration,c(NA,TRUE,FALSE,NA))
 expect_identical(en$candidate_declaration_applicable,c(FALSE,TRUE,TRUE,NA))
 expect_identical(sv$samtycke,en$consent)
 expect_identical(sv$samtycke_tillampligt,en$consent_applicable)
 expect_identical(en$valid,c(TRUE,FALSE,TRUE,NA))
 expect_identical(.values_en(en),en)
 expect_error(.values_en(tibble::tibble(consent=c(1,0))),'Expected Boolean')
 expect_error(.values_en(tibble::tibble(consent=FALSE,consent_applicable=FALSE)),'Inconsistent')
 expect_identical(typeof(.canonical_encode(tibble::tibble(samtycke=NA_character_))$consent),'logical')
})

test_that('referendum options are categories and blank remains valid', {
 x<-tibble::tibble(rostningsalternativkod=c('JA','NEJ','BLANK'),
   rostningsalternativnamn=c('Ja','Nej','Blank'),blankt_alternativ=c(FALSE,FALSE,TRUE),
   antal_roster=c(10L,20L,3L),ogiltiga_roster=2L)
 en<-.public_output(x,'en');sv<-.public_output(x,'sv')
 expect_identical(en$voting_option_name,c('yes','no','blank'))
 expect_identical(sv$rostningsalternativnamn,c('Ja','Nej','Blank'))
 expect_identical(en$voting_option_code,c('JA','NEJ','BLANK')) # source identifiers
 expect_type(en$voting_option_name,'character')
 expect_identical(en$is_blank_option,c(FALSE,FALSE,TRUE))
 expect_equal(sum(en$votes),33L);expect_identical(en$invalid_votes,rep(2L,3))
 expect_identical(.canonical_encode(x),en)
})

test_that('proper names and literal source designations never enter the enum dictionary', {
 x<-tibble::tibble(namn=c('Ja','Nej','Giltig'),kommunnamn=c('Örebro','Åre','Orsa'),
   valdistriktsnamn=c('Ja','Nej','Blank'),partibeteckning=c('Nej till EU','Ja','Giltig'),
   kall_partibeteckning=c('NEJ','JA','Giltig'),kall_nodtyp=c('LÄN','KOMMUN','NATION'),
   valgrund_id=c('P','J','1'))
 en<-.public_output(x,'en');sv<-.public_output(x,'sv')
 expect_identical(en$name,x$namn);expect_identical(en$party_designation,x$partibeteckning)
 expect_identical(en$source_party_designation,x$kall_partibeteckning)
 expect_identical(en$source_node_type,x$kall_nodtyp)
 expect_identical(en$election_basis_id,x$valgrund_id)
 expect_identical(sv,x)
})

test_that('all six election-basis categories remain distinct', {
 d<-.value_dictionary()$election_basis
 x<-tibble::tibble(valgrund_text=names(d))
 en<-.public_output(x,'en');sv<-.public_output(x,'sv')
 expect_identical(en$election_basis,unname(d));expect_length(unique(en$election_basis),6)
 expect_identical(sv,x)
})

test_that('storage discriminators are English and neutral view keys are retained', {
 x<-tibble::tibble(.table=c('kommun','valdistrikt','RD'),
   .component=c('geo','parti','population_alla'),.person_view=c('TRUE','FALSE','TRUE__FALSE'))
 z<-.canonical_encode(x)
 expect_identical(z$.table,c('municipality','district','RD'))
 expect_identical(z$.component,c('geography','party','all_population'))
 expect_identical(z$.person_view,x$.person_view)
 expect_identical(.canonical_encode(z),z)
})

test_that('nested raw requests keep the source-oriented internal contract', {
 x<-tibble::tibble(samtycke='irrelevant',rakningstillfalle='slutlig')
 withr::local_options(swelections.internal_raw_request=TRUE)
 expect_identical(.public_output(x,'sv'),x)
})

test_that('history categories share one value dictionary', {
 x<-tibble::tibble(status=c('occupied','vacant'),start_date_basis=c('reported','original_elected_match'),
   end_date_basis=c('reported','re_election_replacement'),source_kind=c('history','allocation'),
   election_kind=c('ordinary','re_election'))
 sv<-.values_present(x,'sv')
 expect_identical(sv$status,c('besatt','vakant'))
 expect_identical(sv$source_kind,c('historik','mandatfordelning'))
 expect_identical(.values_en(sv),x)
})
test_that('handwritten and other-party aggregates use broad localized labels', {
 x<-tibble::tibble(partibeteckning=c('Handskrivna röster','Övriga partier','Nej till EU'),
   partikod=c(NA_character_,NA_character_,'0463'),ovriga_partier=c(TRUE,TRUE,FALSE),
   kall_partibeteckning_saknas=c(FALSE,TRUE,FALSE))
 en<-.public_output(x,'en');sv<-.public_output(x,'sv')
 expect_identical(en$party_designation,c('Handwritten votes','Other parties','Nej till EU'))
 expect_identical(sv$partibeteckning,x$partibeteckning)
 expect_identical(en$source_party_designation_missing,c(FALSE,TRUE,FALSE))
 expect_identical(.canonical_encode(x),en)
})

test_that('new normal reading refuses old canonical value contracts', {
 r<-.canonical_release_registry()
 expect_true(all(r$schema_version==3L))
 expect_true(.canonical_release(2018L)$auto_eligible)
 expect_identical(.canonical_release(2018L)$data_version,'data-v0.4.0')
 expect_match(.canonical_release(2018L)$base_url,'/data-v0.4.0$')
 for(y in c(2004L,2009L,2014L,2019L,2024L))expect_true(.canonical_release(y,'eu')$auto_eligible)
})
test_that('new Boolean applicability details preserve standard/full projection', {
 x<-tibble::tibble(valtyp='RD',kandidatnummer='1',samtycke='irrelevant',forklaring=NA_character_,giltig=TRUE)
 local_mocked_bindings(.raw_public_api=utils::modifyList(.raw_public_api,list(kandidaturer=function(...)x)))
 for(language in c('en','sv')){
  full<-candidacies(2026,'RD',names=language,detail='full')
  standard<-candidacies(2026,'RD',names=language,detail='standard')
  expect_identical(standard,full[names(standard)])
  field<-if(language=='en')'consent'else'samtycke'
  app<-if(language=='en')'consent_applicable'else'samtycke_tillampligt'
  expect_identical(full[[field]],NA)
  expect_identical(full[[app]],FALSE)
  expect_false(app%in%names(standard))
 }
})

test_that('applicability columns have the same final order for raw and canonical paths', {
 raw<-tibble::tibble(valtyp='RD',samtycke='irrelevant',kandidatur_valomradeskod='01')
 stored<-.canonical_encode(raw[c('valtyp','samtycke')])
 stored$candidacy_electoral_area_code<-'01'
 for(lang in c('en','sv')) {
  expect_identical(.public_output(raw,lang),.public_output(.canonical_names_sv(stored),lang))
 }
})

test_that('mixed canonical and raw candidacy years bind logical properties before projection', {
 fixture<-function(ar,...) {
  if(ar==2018L)tibble::tibble(valar=ar,valtyp='RD',kandidatnummer='1',samtycke=TRUE,samtycke_tillampligt=TRUE,forklaring=NA,forklaring_tillamplig=FALSE)
  else tibble::tibble(valar=ar,valtyp='RD',kandidatnummer='2',samtycke='nej',forklaring='irrelevant')
 }
 local_mocked_bindings(.kandidaturer_ett_ar=fixture)
 for(lang in c('en','sv')) {
  full<-candidacies(c(2018,2022),'RD',source='auto',names=lang,detail='full')
  standard<-candidacies(c(2018,2022),'RD',source='auto',names=lang)
  expect_identical(standard,full[names(standard)])
  en<-if(lang=='en')full else .public_output(full,'en')
  expect_identical(en$election_year,c(2018L,2022L))
  expect_identical(en$consent,c(TRUE,FALSE))
  expect_identical(en$consent_applicable,c(TRUE,TRUE))
  expect_identical(en$candidate_declaration,c(NA,NA))
  expect_identical(en$candidate_declaration_applicable,c(FALSE,FALSE))
 }
})

test_that('EU year dispatch can combine raw and canonical candidacy properties', {
 raw<-tibble::tibble(valar=2004L,valtyp='E',kandidatnummer='old',samtycke='irrelevant')
 canonical<-tibble::tibble(valar=2024L,valtyp='E',kandidatnummer='new',samtycke=TRUE,samtycke_tillampligt=TRUE)
 local_mocked_bindings(
  .select_public_source=function(source,year,...)if(year==2024L)'canonical'else'local',
  .eu2004_read=function(...)raw,
  .eu2024_canonical=function(...)canonical)
 x<-candidacies(c(2004,2024),'E',source='auto',detail='full')
 expect_identical(x$election_year,c(2004L,2024L))
 expect_identical(x$consent,c(NA,TRUE))
 expect_identical(x$consent_applicable,c(FALSE,TRUE))
 expect_true(.canonical_release(2024L,'eu')$auto_eligible)
})

test_that('year binding preserves nested raw source applicability strings', {
 x<-tibble::tibble(samtycke=c('ja','irrelevant'),forklaring=c('nej',NA_character_))
 withr::local_options(swelections.internal_raw_request=TRUE)
 expect_identical(.public_bind_years(list(x)),x)
})

test_that('canonical applicability order is deterministic when inputs are already logical', {
 raw<-tibble::tibble(samtycke='ja',.table='RD')
 expected<-.canonical_encode(raw)
 already<-.canonical_names_sv(expected)
 already<-already[c('samtycke','samtycke_tillampligt','.table')]
 expect_identical(.canonical_encode(already),expected)
 expect_identical(tail(names(expected),1L),'consent_applicable')
})

test_that('single-year source intermediates keep their native applicability representation', {
 x<-tibble::tibble(samtycke=c('ja','irrelevant'),forklaring=c('nej',NA_character_))
 expect_identical(.public_bind_years(list(x)),x)
})
